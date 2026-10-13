param([switch]$SkipBuildTools)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$toolsRoot = Join-Path $projectRoot '.tools'
$downloadRoot = Join-Path $toolsRoot 'downloads'
New-Item -ItemType Directory -Force $downloadRoot | Out-Null
function Download-Signed($Url, $Target, $ExpectedPublisher) {
    if (-not (Test-Path -LiteralPath $Target)) { Invoke-WebRequest -Uri $Url -OutFile $Target }
    $signature = Get-AuthenticodeSignature -LiteralPath $Target
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch $ExpectedPublisher) { throw "Invalid installer signature: $Target" }
}
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$hasBuildTools = $false
if (Test-Path -LiteralPath $vswhere) {
    $hasBuildTools = [bool](& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 Microsoft.VisualStudio.Component.VC.CMake.Project Microsoft.VisualStudio.Component.VC.ATL -property installationPath)
}
if (-not $SkipBuildTools -and -not $hasBuildTools) {
    $installer = Join-Path $downloadRoot 'vs_BuildTools.exe'
    Download-Signed 'https://aka.ms/vs/17/release/vs_BuildTools.exe' $installer 'Microsoft Corporation'
    # The Windows UAC prompt is the OS's administrator authorization step.
    $process = Start-Process -FilePath $installer -Verb RunAs -WindowStyle Hidden -ArgumentList '--quiet --wait --norestart --nocache --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.ATL --includeRecommended --installPath "C:\Program Files\Microsoft Visual Studio\2022\BuildTools"' -Wait -PassThru
    if ($process.ExitCode -notin @(0, 3010)) { throw "Visual Studio installation failed: $($process.ExitCode)" }
}
if (-not (Test-Path (Join-Path $toolsRoot 'inno\ISCC.exe'))) {
    $installer = Join-Path $downloadRoot 'innosetup.exe'
    Download-Signed 'https://github.com/jrsoftware/issrc/releases/download/is-6_7_3/innosetup-6.7.3.exe' $installer 'Pyrsys B.V.'
    $destination = Join-Path $toolsRoot 'inno'
    $process = Start-Process -FilePath $installer -WindowStyle Hidden -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART','/CURRENTUSER',"/DIR=`"$destination`"") -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "Inno Setup installation failed: $($process.ExitCode)" }
}
Write-Output 'Windows build tools ready.'
