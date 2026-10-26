#define AppName "LeoMoon HotKeyz"
#define AppExeName "LeoMoon HotKeyz.exe"
#define AppId "{{50E465C5-2BF7-4476-ADE0-96229901C2ED}"

#ifndef AppVersion
  #error AppVersion must be passed with /DAppVersion.
#endif
#ifndef AppFileVersion
  #error AppFileVersion must be passed with /DAppFileVersion.
#endif
#ifndef StageDir
  #error StageDir must be passed with /DStageDir.
#endif
#ifndef OutputDir
  #error OutputDir must be passed with /DOutputDir.
#endif
#ifndef IconFile
  #error IconFile must be passed with /DIconFile.
#endif

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
VersionInfoVersion={#AppFileVersion}
VersionInfoTextVersion={#AppFileVersion}
VersionInfoProductVersion={#AppFileVersion}
VersionInfoProductTextVersion={#AppFileVersion}
AppPublisher=LeoMoon Studios Inc.
DefaultDirName={localappdata}\Programs\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir={#OutputDir}
OutputBaseFilename=leomoon-hotkeyz-{#AppVersion}-windows-x86-setup
SetupIconFile={#IconFile}
Compression=lzma2/ultra64
SolidCompression=yes
CloseApplications=yes
CloseApplicationsFilter={#AppExeName}
RestartApplications=no
AppMutex=LeoMoon HotKeyz
UninstallDisplayIcon={app}\{#AppExeName}
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#StageDir}\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon
