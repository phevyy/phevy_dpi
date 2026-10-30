; phevy kurulum betigi (Inno Setup 6). Derleme: ..\release.bat
#define AppName "phevy"
#define AppVersion "0.2.0"
#define AppExe "phevy.exe"
#define BuildDir "..\flutter_app\build\windows\x64\runner\Release"

[Setup]
; AppId sabit kalmali: guncellemeler eski kurulumun ustune yazilir.
AppId={{DF4E8C0E-4694-41FB-9286-6A69C1AD9F8F}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=phevy
DefaultDirName={autopf}\phevy
DefaultGroupName=phevy
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir=..\dist\installer
OutputBaseFilename=phevy_kurulum_{#AppVersion}
SetupIconFile=..\flutter_app\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
CloseApplications=yes

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"

[Tasks]
Name: "defender"; Description: "Windows Defender dışlaması ekle (önerilir: aksi halde Defender WinDivert sürücüsünü silebilir)"; GroupDescription: "Güvenlik:"
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "THIRD_PARTY.txt"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\phevy"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\phevy"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
; Uygulama yonetici izni ister; kurulum zaten yonetici oldugu icin tekrar UAC sorulmadan acilir.
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,phevy}"; Flags: nowait postinstall skipifsilent runascurrentuser shellexec

[UninstallRun]
Filename: "{sys}\schtasks.exe"; Parameters: "/Delete /F /TN phevy"; Flags: runhidden; RunOnceId: "DeleteAutostartTask"

[Code]
procedure StopPhevy;
var
  R: Integer;
begin
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM phevy.exe', '', SW_HIDE, ewWaitUntilTerminated, R);
  // Motor, uygulama kapaninca (stdin kapaninca) surucuyu birakip kendisi cikar; kisa bekleyip garantiye al.
  Sleep(1500);
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM phevy_engine.exe', '', SW_HIDE, ewWaitUntilTerminated, R);
end;

procedure SetDefenderExclusion(Add: Boolean);
var
  R: Integer;
  Cmd: String;
begin
  if Add then
    Cmd := 'Add-MpPreference'
  else
    Cmd := 'Remove-MpPreference';
  // Defender kapali ya da baska antivirus varsa komut basarisiz olur; kurulum yine devam eder.
  Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
    '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "' + Cmd +
    ' -ExclusionPath ''' + ExpandConstant('{app}') + '''"',
    '', SW_HIDE, ewWaitUntilTerminated, R);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  StopPhevy;
  Result := '';
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  // Dosyalar kopyalanmadan once: Defender WinDivert'i kopyalanirken silmesin.
  if (CurStep = ssInstall) and WizardIsTaskSelected('defender') then
    SetDefenderExclusion(True);
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  R: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    StopPhevy;
    Exec(ExpandConstant('{sys}\sc.exe'), 'stop WinDivert', '', SW_HIDE, ewWaitUntilTerminated, R);
  end;
  if CurUninstallStep = usPostUninstall then
    SetDefenderExclusion(False);
end;
