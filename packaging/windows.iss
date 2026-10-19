#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif
#ifndef BundleDir
  #error BundleDir must be provided by build-release.ps1
#endif
#ifndef OutputDir
  #error OutputDir must be provided by build-release.ps1
#endif

#ifdef TestBuild
  #define PackageId "{{46B5F62C-3899-4AF2-91A1-8EB34746229E}"
  #define PackageName "うに時間割（デバッグ）"
  #define InstallFolder "UniTable.debug"
  #define VariantSuffix "-debug"
#else
  #define PackageId "{{70BF2996-F0EF-44A0-8925-7DF10F57CC85}"
  #define PackageName "うに時間割"
  #define InstallFolder "UniTable"
  #define VariantSuffix ""
#endif

[Setup]
AppId={#PackageId}
AppName={#PackageName}
AppVersion={#AppVersion}
AppPublisher=UniTable
DefaultDirName={localappdata}\Programs\{#InstallFolder}
DefaultGroupName={#PackageName}
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
OutputDir={#OutputDir}
OutputBaseFilename=UniTable-{#AppVersion}-windows-x64{#VariantSuffix}-setup
UninstallDisplayIcon={app}\UniTable.exe
SetupIconFile=..\windows\runner\resources\app_icon.ico
WizardSmallImageFile=..\assets\icons\app_icon_512.png
WizardImageFile=..\assets\icons\installer-wizard.png
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "デスクトップにショートカットを作成"; GroupDescription: "追加設定:"; Flags: unchecked

[Files]
Source: "{#BundleDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#PackageName}"; Filename: "{app}\UniTable.exe"
Name: "{autodesktop}\{#PackageName}"; Filename: "{app}\UniTable.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\UniTable.exe"; Description: "{#PackageName}を起動"; Flags: nowait postinstall skipifsilent
