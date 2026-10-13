#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif
#ifndef BundleDir
  #error BundleDir must be provided by build-release.ps1
#endif
#ifndef OutputDir
  #error OutputDir must be provided by build-release.ps1
#endif

[Setup]
AppId={{70BF2996-F0EF-44A0-8925-7DF10F57CC85}
AppName=うに時間割
AppVersion={#AppVersion}
AppPublisher=UniTable
DefaultDirName={localappdata}\Programs\UniTable
DefaultGroupName=うに時間割
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
OutputDir={#OutputDir}
OutputBaseFilename=UniTable-{#AppVersion}-windows-x64-setup
UninstallDisplayIcon={app}\UniTable.exe
SetupIconFile=..\windows\runner\resources\app_icon.ico
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
Name: "{group}\うに時間割"; Filename: "{app}\UniTable.exe"
Name: "{autodesktop}\うに時間割"; Filename: "{app}\UniTable.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\UniTable.exe"; Description: "うに時間割を起動"; Flags: nowait postinstall skipifsilent
