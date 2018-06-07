unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Winapi.ShellApi, Winapi.TlHelp32,
  Vcl.StdCtrls, uFunctions, Vcl.Imaging.jpeg, Vcl.ExtCtrls, IniFiles;

type
  TForm1 = class(TForm)
    Image1: TImage;
    lblStatus: TLabel;
    TimerStartProxy: TTimer;
    TimerDetectProxy: TTimer;
    TimerStartTera: TTimer;
    LocateApp: TOpenDialog;
    TimerClose: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerStartProxyTimer(Sender: TObject);
    procedure TimerDetectProxyTimer(Sender: TObject);
    procedure TimerStartTeraTimer(Sender: TObject);
    procedure TimerCloseTimer(Sender: TObject);
  private
    { Private declarations }
    ini:TMemIniFile;

    wait_for_count_cycle : integer;
  public
    { Public declarations }
    exe_tp:string;
    admin_tp:boolean;
    exe_tera:string;

    delay_tera:integer;
    wait_for:string;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

const LNG_STARTING = 'Starting...';
      LNG_STARTING_TERA_PROXY = 'Launching Tera Proxy...';
      LNG_TERA_PROXY_NOT_FOUND = 'Tera Proxy not found! Please specify correct path...';
      LNG_TERA_PROXY_WAITING = 'Waiting for Tera Proxy...';
      LNG_STARTING_TERA = 'Launching Tera Online...';
      LNG_TERA_NOT_FOUND = 'Tera Launcher not found! Please specify correct path...';

      LNG_SHUT_DOWN = 'Shutting down...';

      LNG_ERR_TERA_PROXY_NOT_FOUND = 'Unable to locate Tera Proxy!';
      LNG_ERR_TERA_PROXY_TIMEOUT = 'Timeout waiting for proxy to start!';
      LNG_ERR_TERA_NOT_FOUND = 'Unable to locate Tera Launcher!';




procedure TForm1.FormCreate(Sender: TObject);
begin
lblStatus.Caption := LNG_STARTING;

ini        := TMemIniFile.Create(ChangeFileExt(Application.ExeName,'.ini'), Tencoding.UTF8);
admin_tp   := ini.ReadBool('TeraProxyLauncher',   'TeraProxyAdmin', true);
exe_tp     := ini.ReadString('TeraProxyLauncher',  'TeraProxyPath', 'TeraProxy.bat');
exe_tera   := ini.ReadString('TeraProxyLauncher',  'TeraLauncherPath', 'Tera-Launcher.exe');
wait_for   := ini.ReadString('TeraProxyLauncher', 'TeraProxyFind', 'node.exe');
delay_tera := ini.ReadInteger('TeraProxyLauncher', 'DelayTeraFor', 3000);

// we write the info back to the ini. it will save only if tera proxy or launcher paths are not set
// this is to write all information in the ini in case it was missing
ini.WriteBool('TeraProxyLauncher',   'TeraProxyAdmin', admin_tp);
ini.WriteString('TeraProxyLauncher', 'TeraProxyFind', wait_for);
ini.WriteInteger('TeraProxyLauncher', 'DelayTeraFor', delay_tera);
ini.UpdateFile;

if delay_tera < 10 then delay_tera := 50 // minimum 50 ms
else
if delay_tera > 60000 then delay_tera := 60000; // maximum 1 minute (60 seconds * 1000)

wait_for_count_cycle := 0;

lblStatus.Caption := LNG_STARTING_TERA_PROXY;
TimerStartProxy.Enabled := true;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
ini.Free;
end;

procedure TForm1.TimerStartProxyTimer(Sender: TObject);
begin
TimerStartProxy.Enabled := false;
// check if tera proxy is found
if not FileExists(exe_tp) then
   begin
   lblStatus.Caption := LNG_TERA_PROXY_NOT_FOUND;

   LocateApp.FileName := '';
   LocateApp.Filter := 'TeraProxy.bat|TeraProxy.bat';
   LocateApp.Title  := 'Locate and select TeraProxy.bat';
   if LocateApp.Execute then
      begin
      lblStatus.Caption := LNG_STARTING_TERA_PROXY;
      exe_tp := LocateApp.FileName;
      ini.WriteString('TeraProxyLauncher', 'TeraProxyPath', exe_tp);
      ini.UpdateFile;
      end
   else
      begin
        lblStatus.Caption := LNG_ERR_TERA_PROXY_NOT_FOUND;
        ShowMessage(LNG_ERR_TERA_PROXY_NOT_FOUND);
        Close;
      end;
   end;

lblStatus.Caption := LNG_TERA_PROXY_WAITING;
if admin_tp then RunAsAdmin(0, exe_tp,'')
            else ShellExecute(0, 'open', PChar(exe_tp),nil,PChar(ExtractFilePath(exe_tp)),SW_SHOWNORMAL);
TimerDetectProxy.Enabled := true;
end;


procedure TForm1.TimerDetectProxyTimer(Sender: TObject);
var pid:cardinal;
begin
// wait for process or asume started if no process name given
if ( processExists(wait_for, pid) ) OR (wait_for = '') then
  begin
  TimerDetectProxy.Enabled := false;

  lblStatus.Caption := LNG_STARTING_TERA;
  TimerStartTera.Interval := delay_tera;
  TimerStartTera.Enabled := true;
  end
else
  begin
  wait_for_count_cycle := wait_for_count_cycle+1;
  // if proxy doesn't start within a minute (60 seconds * 10 checks per second)
  if wait_for_count_cycle > 600 then
    begin
    lblStatus.Caption := LNG_ERR_TERA_PROXY_TIMEOUT;
    TimerDetectProxy.Enabled := false;
    ShowMessage(LNG_ERR_TERA_PROXY_TIMEOUT);
    Close;
    end;
  end;
end;


procedure TForm1.TimerStartTeraTimer(Sender: TObject);
begin
TimerStartTera.Enabled := false;


// check if tera proxy is found
if not FileExists(exe_tera) then
   begin
   lblStatus.Caption := LNG_TERA_NOT_FOUND;

   LocateApp.FileName := '';
   LocateApp.Filter := 'Tera-Launcher.exe|Tera-Launcher.exe';
   LocateApp.Title  := 'Locate and select Tera-Launcher.exe';
   if LocateApp.Execute then
      begin
      lblStatus.Caption := LNG_STARTING_TERA;
      exe_tera := LocateApp.FileName;
      ini.WriteString('TeraProxyLauncher', 'TeraLauncherPath', exe_tera);
      ini.UpdateFile;
      end
   else
      begin
        lblStatus.Caption := LNG_ERR_TERA_NOT_FOUND;
        ShowMessage(LNG_ERR_TERA_NOT_FOUND);
        Close;
      end;
   end;

ShellExecute(0, 'open', PChar(exe_tera),nil,PChar(ExtractFilePath(exe_tera)),SW_SHOWNORMAL);

lblStatus.Caption := LNG_SHUT_DOWN;
TimerClose.Enabled := true;
end;


procedure TForm1.TimerCloseTimer(Sender: TObject);
begin
Close;
end;



end.
