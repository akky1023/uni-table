param([switch]$SkipBuild, [string]$Publisher = 'CN=akky_1023')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$flutter = Join-Path $projectRoot '.tools\flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutter)) { $flutter = (Get-Command flutter -ErrorAction Stop).Source }
$dart = Join-Path (Split-Path $flutter -Parent) 'dart.bat'
$version = [regex]::Match((Get-Content pubspec.yaml -Raw), '(?m)^version:\s*([\d.]+)\+\d+').Groups[1].Value
if (-not $version) { throw 'Cannot determine application version.' }
$sdkBin = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
$sdk = Get-ChildItem -LiteralPath $sdkBin -Directory | Where-Object {
    $_.Name -match '^\d+\.\d+\.\d+\.\d+$' -and (Test-Path (Join-Path $_.FullName 'x64\makeappx.exe'))
} | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
if (-not $sdk) { throw 'Windows SDK x64 MakeAppx was not found.' }
$dist = Join-Path $projectRoot 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
$name = "UniTable-$version-windows-x64-unsigned"
$buildWindows = if ($SkipBuild) { 'false' } else { 'true' }
# 証明書はインストールせず、確認用の未署名パッケージだけを生成します。
# msix付属のMakeAppxはランタイムの問題があるためWindows SDK版を使います。
& $dart run msix:build --build-windows $buildWindows --sign-msix false --install-certificate false --publisher $Publisher --output-path $dist --output-name $name
if ($LASTEXITCODE -ne 0) { throw 'MSIX manifest preparation failed.' }
$release = Join-Path $projectRoot 'build\windows\x64\runner\Release'
$package = Join-Path $dist "$name.msix"
& (Join-Path $sdk.FullName 'x64\makeappx.exe') pack /o /d $release /p $package
if ($LASTEXITCODE -ne 0) { throw 'MSIX packaging failed.' }
$checksums = Get-ChildItem -LiteralPath $dist -File | Where-Object { $_.Extension -in '.apk', '.exe', '.zip', '.msix' } | Sort-Object Name | ForEach-Object {
    "$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant())  $($_.Name)"
}
[IO.File]::WriteAllLines((Join-Path $dist 'SHA256SUMS.txt'), $checksums, [Text.UTF8Encoding]::new($false))
Write-Output "Unsigned MSIX: $package"
