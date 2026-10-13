param([switch]$AcceptLicenses)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$toolsRoot = Join-Path $projectRoot '.tools'
$downloadRoot = Join-Path $toolsRoot 'downloads'
$sdkRoot = Join-Path $toolsRoot 'android-sdk'
$jdkRoot = Join-Path $toolsRoot 'jdk'
New-Item -ItemType Directory -Force $downloadRoot, $sdkRoot, $jdkRoot | Out-Null

function Get-VerifiedArchive($Url, $Target, $Hash, $Algorithm) {
    if (-not (Test-Path -LiteralPath $Target)) {
        Write-Output "Downloading $([IO.Path]::GetFileName($Target))"
        Invoke-WebRequest -Uri $Url -OutFile $Target
    }
    if ((Get-FileHash -LiteralPath $Target -Algorithm $Algorithm).Hash -ne $Hash) {
        throw "Archive checksum mismatch: $Target"
    }
}

$jdk = Get-ChildItem -LiteralPath $jdkRoot -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'bin\java.exe') } | Select-Object -First 1
if ($null -eq $jdk) {
    $metadata = Invoke-RestMethod 'https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse'
    $package = $metadata[0].binary.package
    $archive = Join-Path $downloadRoot $package.name
    Get-VerifiedArchive $package.link $archive $package.checksum 'SHA256'
    Expand-Archive -LiteralPath $archive -DestinationPath $jdkRoot
    $jdk = Get-ChildItem -LiteralPath $jdkRoot -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'bin\java.exe') } | Select-Object -First 1
}
if ($null -eq $jdk) { throw 'Java 21 was not installed.' }
$env:JAVA_HOME = $jdk.FullName
$env:ANDROID_HOME = $sdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot
$env:GRADLE_USER_HOME = Join-Path $toolsRoot 'gradle-cache'

$sdkManager = Join-Path $sdkRoot 'cmdline-tools\latest\bin\sdkmanager.bat'
$sourceProperties = Join-Path $sdkRoot 'cmdline-tools\latest\source.properties'
if (-not (Test-Path -LiteralPath $sdkManager) -or -not ((Get-Content -LiteralPath $sourceProperties -Raw) -match 'Pkg.Revision=19\.0')) {
    [xml]$repository = (Invoke-WebRequest 'https://dl.google.com/android/repository/repository2-3.xml').Content
    $latest = $repository.SelectNodes('//*[local-name()="remotePackage"]') | Where-Object { $_.path -eq 'cmdline-tools;19.0' }
    $archiveInfo = $latest.archives.archive | Where-Object { $_.'host-os' -eq 'windows' }
    $archive = Join-Path $downloadRoot $archiveInfo.complete.url
    Get-VerifiedArchive "https://dl.google.com/android/repository/$($archiveInfo.complete.url)" $archive $archiveInfo.complete.checksum.InnerText 'SHA1'
    $commandRoot = Join-Path $sdkRoot 'cmdline-tools'
    New-Item -ItemType Directory -Force $commandRoot | Out-Null
    $previous = [IO.Path]::GetFullPath((Join-Path $commandRoot 'latest'))
    $preserved = [IO.Path]::GetFullPath((Join-Path $commandRoot ('previous-' + [Guid]::NewGuid().ToString('N'))))
    if (-not $previous.StartsWith($toolsRoot + '\') -or -not $preserved.StartsWith($toolsRoot + '\')) { throw 'Unexpected tool path.' }
    if (Test-Path -LiteralPath $previous) { Move-Item -LiteralPath $previous -Destination $preserved }
    Expand-Archive -LiteralPath $archive -DestinationPath $commandRoot
    $unpacked = [IO.Path]::GetFullPath((Join-Path $commandRoot 'cmdline-tools'))
    $destination = [IO.Path]::GetFullPath((Join-Path $commandRoot 'latest'))
    if (-not $unpacked.StartsWith($toolsRoot + '\') -or -not $destination.StartsWith($toolsRoot + '\')) { throw 'Unexpected tool path.' }
    Move-Item -LiteralPath $unpacked -Destination $destination
}

if ($AcceptLicenses) {
    (1..100 | ForEach-Object { 'y' }) | & $sdkManager "--sdk_root=$sdkRoot" --licenses
    if ($LASTEXITCODE -ne 0) { throw 'Android SDK license setup failed.' }
}
& $sdkManager "--sdk_root=$sdkRoot" 'platform-tools' 'platforms;android-36' 'build-tools;36.0.0' 'ndk;28.2.13676358' 'cmake;3.22.1'
if ($LASTEXITCODE -ne 0) { throw 'Android SDK package installation failed.' }

$flutter = Join-Path $toolsRoot 'flutter\bin\flutter.bat'
& $flutter config --android-sdk $sdkRoot --jdk-dir $jdk.FullName
if ($LASTEXITCODE -ne 0) { throw 'Flutter toolchain configuration failed.' }
Write-Output "Android toolchain ready: $sdkRoot"
