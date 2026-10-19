param(
    [ValidateSet('all','windows','android')][string]$Target = 'all',
    [switch]$SkipChecks,
    [switch]$SkipRestore,
    [switch]$PortableOnly
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$toolsRoot = Join-Path $projectRoot '.tools'
$flutter = Join-Path $toolsRoot 'flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutter)) { $flutter = (Get-Command flutter -ErrorAction Stop).Source }
$dart = Join-Path (Split-Path $flutter -Parent) 'dart.bat'
$version = [regex]::Match((Get-Content pubspec.yaml -Raw), '(?m)^version:\s*([\d.]+)\+(\d+)').Groups[1].Value
if (-not $version) { throw 'Cannot determine application version.' }
$dist = Join-Path $projectRoot 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
$jdk = Get-ChildItem (Join-Path $toolsRoot 'jdk') -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName 'bin\java.exe') } | Select-Object -First 1
if ($jdk) { $env:JAVA_HOME = $jdk.FullName }
if (Test-Path (Join-Path $toolsRoot 'android-sdk')) {
    $env:ANDROID_HOME = Join-Path $toolsRoot 'android-sdk'
    $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
}
$env:GRADLE_USER_HOME = Join-Path $toolsRoot 'gradle-cache'
function Assert-Exit($Step) { if ($LASTEXITCODE -ne 0) { throw "$Step failed (exit code $LASTEXITCODE)." } }

if (-not $SkipRestore) {
    & $flutter pub get
    Assert-Exit 'Dependency resolution'
}
if (-not $SkipChecks) {
    & $flutter analyze --no-pub
    Assert-Exit 'Static analysis'
    & $flutter test --no-pub
    Assert-Exit 'Tests'
}

if ($Target -in @('all','android')) {
    $signingRoot = Join-Path $toolsRoot 'signing'
    $properties = Join-Path $signingRoot 'android-key.properties'
    if (-not (Test-Path (Join-Path $projectRoot 'android\key.properties')) -and -not (Test-Path -LiteralPath $properties)) {
        if (-not $jdk) { throw 'Run scripts/setup-android.ps1 -AcceptLicenses first.' }
        New-Item -ItemType Directory -Force $signingRoot | Out-Null
        $keyStore = Join-Path $signingRoot 'unitable-release.jks'
        if (Test-Path -LiteralPath $keyStore) { throw 'An existing signing key has no properties file. Restore its properties; do not regenerate the key.' }
        $random = New-Object byte[] 32
        [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($random)
        $password = [Convert]::ToBase64String($random)
        $passwordFile = Join-Path $signingRoot 'password.txt'
        [IO.File]::WriteAllText($passwordFile, $password, [Text.UTF8Encoding]::new($false))
        & (Join-Path $jdk.FullName 'bin\keytool.exe') -genkeypair -keystore $keyStore -storetype JKS -alias unitable -keyalg RSA -keysize 3072 -validity 10000 -dname 'CN=akky_1023, O=Neomenia, C=JP' -ext 'SAN=DNS:neomenia.net' "-storepass:file" $passwordFile "-keypass:file" $passwordFile
        Assert-Exit 'APK signing key creation'
        $propertyText = "storeFile=$($keyStore.Replace('\','/'))`nstorePassword=$password`nkeyPassword=$password`nkeyAlias=unitable`n"
        [IO.File]::WriteAllText($properties, $propertyText, [Text.UTF8Encoding]::new($false))
        Remove-Item -LiteralPath $passwordFile
        $password = $null
        Write-Output 'Created persistent APK signing key in .tools/signing. Back up this directory securely.'
    }
    & $flutter build apk --release --no-pub
    Assert-Exit 'Android release build'
    $apk = Join-Path $dist "UniTable-$version-android.apk"
    Copy-Item -LiteralPath 'build\app\outputs\flutter-apk\app-release.apk' -Destination $apk -Force
    $apksigner = Join-Path $env:ANDROID_HOME 'build-tools\36.0.0\apksigner.bat'
    & $apksigner verify --verbose $apk
    Assert-Exit 'APK signature verification'
    $aapt = Join-Path $env:ANDROID_HOME 'build-tools\36.0.0\aapt.exe'
    $resources = & $aapt dump resources $apk
    Assert-Exit 'APK resource verification'
    if (-not ($resources -match 'drawable/ic_notification')) {
        throw 'Notification icon is missing from the release APK'
    }
}

if ($Target -in @('all','windows')) {
    & $flutter build windows --release --no-pub
    Assert-Exit 'Windows release build'
    $release = Join-Path $projectRoot 'build\windows\x64\runner\Release'
    $bundle = Join-Path $dist "UniTable-$version-windows-x64"
    $runningBundle = Get-Process -Name UniTable -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -and ([IO.Path]::GetDirectoryName($_.Path) -eq $bundle)
    }
    if ($runningBundle) {
        $buildNumber = [regex]::Match((Get-Content pubspec.yaml -Raw), '(?m)^version:\s*[\d.]+\+(\d+)').Groups[1].Value
        $bundle = Join-Path $dist "UniTable-$version-windows-x64-build$buildNumber"
        Write-Output "Keeping the running application; publishing the updated portable bundle to $bundle"
    }
    New-Item -ItemType Directory -Force $bundle | Out-Null
    Copy-Item -Path (Join-Path $release '*') -Destination $bundle -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE') -Destination (Join-Path $bundle 'LICENSE') -Force
    # App-local MSVC runtime enables the portable build without a separate installer.
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    $vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    $crt = Get-ChildItem (Join-Path $vs 'VC\Redist\MSVC\*\x64\*') -Directory | Where-Object { $_.Name -match '^Microsoft\.VC\d+\.CRT$' } | Sort-Object FullName -Descending | Select-Object -First 1
    if (-not $crt) { throw 'MSVC redistributable DLLs were not found.' }
    Copy-Item -Path (Join-Path $crt.FullName '*.dll') -Destination $bundle -Force
    $report = Join-Path $dist 'windows-smoke-test.json'
    if (Test-Path -LiteralPath $report) { Remove-Item -LiteralPath $report }
    $check = Start-Process -FilePath (Join-Path $bundle 'UniTable.exe') -WorkingDirectory $bundle -WindowStyle Hidden -ArgumentList @('--verify-installation', "`"--report=$report`"") -PassThru
    if (-not $check.WaitForExit(30000)) { Stop-Process -Id $check.Id; throw 'Windows executable startup check timed out.' }
    if ($check.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $report) -or -not ((Get-Content -LiteralPath $report -Raw | ConvertFrom-Json).ok)) { throw 'Windows executable startup check failed.' }
    if ((Get-Content -LiteralPath $report -Raw | ConvertFrom-Json).appVersion -cne $version) { throw 'Windows in-app version does not match the release version.' }
    [IO.File]::WriteAllText((Join-Path $bundle 'README.txt'), "UniTable $version`r`nStart UniTable.exe. Keep the data folder and DLL files beside the executable.`r`nLocal notifications on Windows require the MSIX edition.`r`n", [Text.UTF8Encoding]::new($false))
    $zip = Join-Path $dist "UniTable-$version-windows-x64.zip"
    Compress-Archive -LiteralPath $bundle -DestinationPath $zip -Force
    if (-not $PortableOnly) {
        $iscc = Join-Path $toolsRoot 'inno\ISCC.exe'
        if (-not (Test-Path -LiteralPath $iscc)) { $iscc = (Get-Command ISCC.exe -ErrorAction Stop).Source }
        & $iscc "/DAppVersion=$version" "/DBundleDir=$bundle" "/DOutputDir=$dist" (Join-Path $projectRoot 'packaging\windows.iss')
        Assert-Exit 'Windows installer build'
    }
}

$checksums = Get-ChildItem -LiteralPath $dist -File | Where-Object { $_.Extension -in @('.apk','.exe','.zip','.msix') } | ForEach-Object { "$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLower())  $($_.Name)" }
[IO.File]::WriteAllLines((Join-Path $dist 'SHA256SUMS.txt'), $checksums, [Text.UTF8Encoding]::new($false))
Write-Output "Release artifacts: $dist"
