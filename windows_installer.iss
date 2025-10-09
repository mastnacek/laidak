[Setup]
AppName=TODO Doom
AppVersion=1.0.0
AppPublisher=Jaroslav
DefaultDirName={autopf}\TODODoom
DefaultGroupName=TODO Doom
OutputDir=build\windows\installer
OutputBaseFilename=TodoDoomSetup
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\todo.exe

[Languages]
Name: "czech"; MessagesFile: "compiler:Languages\Czech.isl"

[Tasks]
Name: "desktopicon"; Description: "Vytvořit ikonu na ploše"; GroupDescription: "Další ikony:"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\todo.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\TODO Doom"; Filename: "{app}\todo.exe"
Name: "{autodesktop}\TODO Doom"; Filename: "{app}\todo.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\todo.exe"; Description: "Spustit TODO Doom"; Flags: nowait postinstall skipifsilent
