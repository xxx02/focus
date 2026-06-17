; Focus - Windows kurulum scripti (Inno Setup)
; GitHub Actions windows job'unda derlenir: ISCC.exe windows\installer.iss

[Setup]
AppName=Focus
AppVersion=1.1.0
AppPublisher=xxx02
AppPublisherURL=https://github.com/xxx02/focus
; Göreli yollar (Source, OutputDir) bu script'in bir üst klasörüne = repo köküne göre çözülür.
SourceDir=..
DefaultDirName={autopf}\Focus
DefaultGroupName=Focus
UninstallDisplayIcon={app}\focus_launcher.exe
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=Focus-Setup-Windows
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\Focus"; Filename: "{app}\focus_launcher.exe"
Name: "{group}\{cm:UninstallProgram,Focus}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Focus"; Filename: "{app}\focus_launcher.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\focus_launcher.exe"; Description: "{cm:LaunchProgram,Focus}"; Flags: nowait postinstall skipifsilent
