unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.jpeg, IniFiles,
  Vcl.ExtCtrls, Vcl.Grids, Winapi.ShellApi, Winapi.TlHelp32, uFunctions;

type
  TfrmMain = class(TForm)
    Image1: TImage;
    lblStatus: TLabel;
    apps: TStringGrid;
    LocateApp: TOpenDialog;
    TimerStartApp: TTimer;
    lblStatus2: TLabel;
    TimerClose: TTimer;
    TimerMainApp: TTimer;
    TimerDetectApp: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerStartAppTimer(Sender: TObject);
    procedure TimerDetectAppTimer(Sender: TObject);
    procedure TimerMainAppTimer(Sender: TObject);
    procedure TimerCloseTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    ini:TMemIniFile;

    wait_for_count_cycle : integer;

    current_index:integer;
    current_section:string;
    current_name:string;
    current_path:string;
    current_admin:boolean;
    current_delay:integer;
    current_find:string;
    current_required:boolean;

    main_name:string;
    main_path:string;
    main_admin:boolean;
    main_delay:integer;
    // find and required sections don't apply to main app

    procedure Load_App_Data(idx:integer);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

const MAIN_APP_SECTION = 'Tera';

      LNG_LOADING = 'Loading ...';
      LNG_STARTING = 'Starting app...';

      LNG_NOT_FOUND = 'Invalid path! Please specify correct path...';

      LNG_APP_LOCATE = 'Locate and select application executable for';
      LNG_APP_LOCATED = 'Specified a new path for app';

      LNG_PROCESS_WAITING = 'Waiting for process...';

      LNG_ERR_APP_NOT_FOUND = 'Failed to locate requested application!';
      LNG_ERR_PROCESS_TIMEOUT = 'Process did not start in a reasonable ammount of time!';

      LNG_MAIN_NOT_FOUND = 'Tera Launcher not found! Please specify correct path...';
      LNG_ERR_MAIN_NOT_FOUND = 'Unable to locate Tera Launcher!';
      LNG_MAIN_LOCATED = 'Specified a new path for Tera Launcher';
      LNG_MAIN_STARTING = 'Launching Tera Online...';

      LNG_NO_APPS = 'No apps defined! Please check and edit the ini file!';
      LNG_SHUT_DOWN = 'Shutting down...';

procedure TfrmMain.Load_App_Data(idx: Integer);
var i:integer;
begin
if idx < apps.RowCount then
   begin
   current_index    := idx;
   current_section  := apps.Cells[0,idx]; // used by ini to save info if needed
   current_name     := apps.Cells[1,idx];
   current_path     := apps.Cells[2,idx];
   if apps.Cells[3,idx] = 'yes' then current_admin := true
                                else current_admin := false;
   i := StrToInt(apps.Cells[4,idx]);
   current_delay    := i;
   current_find     := apps.Cells[5,idx];
   if apps.Cells[6,idx] = 'yes' then current_required := true
                                else current_required := false;

   lblStatus.Caption := '['+IntToStr(idx+1)+'/'+IntToStr(apps.RowCount-1)+'] '+
                        current_name;
   lblStatus2.Caption := LNG_STARTING;

   // set delay for the timer
   TimerStartApp.Interval := current_delay;
   end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var section_list:TStringList;
    i,idx:integer;

    sname:string;
    need_admin, is_required:boolean;
    use_delay:integer;
begin
lblStatus.Caption := '';
lblStatus2.Caption := LNG_LOADING;

// load ini file
ini        := TMemIniFile.Create(ChangeFileExt(Application.ExeName,'.ini'), Tencoding.UTF8);

// get apps to start
section_list := TStringList.Create;
ini.ReadSections(section_list);

if section_list.Count < 2 then
   begin
   lblStatus2.Caption := LNG_NO_APPS;
//   TimerClose.Interval := 3000;
//   TimerClose.Enabled := true;
//   exit;
   end;

apps.RowCount := section_list.Count;

if section_list.Count > 0 then
  begin
  idx := 0;
  for i := 0 to section_list.Count-1 do
    begin
    sname := section_list[i];

    if (LowerCase(sname) <> LowerCase(MAIN_APP_SECTION)) AND (LowerCase(sname) <> 'settings') then
        begin
        apps.Cells[0,idx] := sname;
        // app name
        apps.Cells[1,idx] := ini.ReadString(sname, 'Name', '<<Unnamed>>');
        // app path
        apps.Cells[2,idx] := ini.ReadString(sname, 'Path', '-path-not-set-');
        // app needs admin
        need_admin        := ini.ReadBool(sname, 'Admin', false);
        if need_admin then apps.Cells[3,idx] := 'yes'
                      else apps.Cells[3,idx] := 'no';
        // app delay
        use_delay         := ini.ReadInteger(sname, 'Delay', 1000);
        if use_delay < 50 then use_delay := 50 // minimum 50 ms
        else if use_delay > 60000 then use_delay := 60000; // maximum 1 minute (60 seconds * 1000)
        apps.Cells[4,idx] := IntToStr(use_delay);
        // app wait for process
        apps.Cells[5,idx] := ini.ReadString(sname, 'Find', '');
        // app is required - If app is not found, execution will be stopped
        is_required        := ini.ReadBool(sname, 'Required', false);
        if is_required then apps.Cells[6,idx] := 'yes'
                       else apps.Cells[6,idx] := 'no';

        idx := idx+1;
        end
    else
        apps.RowCount := apps.RowCount-1;
    end;

end;

// get main app info
main_name  := ini.ReadString(MAIN_APP_SECTION,  'Name',  '<<Unnamed>>');
main_path  := ini.ReadString(MAIN_APP_SECTION,  'Path',  '-path-not-set-');
main_admin := ini.ReadBool(MAIN_APP_SECTION,    'Admin', false);
main_delay := ini.ReadInteger(MAIN_APP_SECTION, 'Delay', 1000);



if section_list.Count > 0 then
   begin
   Load_App_Data(0);
   TimerStartApp.Interval := current_delay;
   TimerStartApp.Enabled := true;
   end
else
   begin
   // start main app only
   lblStatus.Caption := LNG_MAIN_STARTING;
   TimerMainApp.Interval := 5000;
   TimerMainApp.Enabled  := true;
   end;
end;


procedure TfrmMain.FormDestroy(Sender: TObject);
begin
ini.Free;
end;



procedure TfrmMain.TimerStartAppTimer(Sender: TObject);
begin
TimerStartApp.Enabled := false;

if not FileExists(current_path) then
   begin
   lblStatus2.Caption := LNG_NOT_FOUND;

   LocateApp.FileName := '';
   LocateApp.Title := LNG_APP_LOCATE+' '+current_name;
   if LocateApp.Execute then
      begin
      lblStatus2.Caption := LNG_APP_LOCATED;
      current_path := LocateApp.FileName;
      ini.WriteString(current_section, 'Path', current_path);
      ini.UpdateFile;
      end
   else
      begin
        lblStatus2.Caption := LNG_ERR_APP_NOT_FOUND;
        if current_required then TimerClose.Enabled := true
        else
          begin
          if current_index < apps.RowCount-1 then
             begin
             current_index := current_index+1;
             Load_App_Data(current_index);
             TimerStartApp.Enabled := true;
             end
          else
             begin
             lblStatus.Caption := LNG_MAIN_STARTING;
             lblStatus2.Caption := '';
             TimerMainApp.Interval := main_delay;
             TimerMainApp.Enabled  := true;
             end;

          end;
        exit;
      end;
   end;

// start app
if current_admin then RunAsAdmin(0, current_path,'')
                 else ShellExecute(0, 'open', PChar(current_path),nil,PChar(ExtractFilePath(current_path)),SW_SHOWNORMAL);

// if current app has a process that must exist before continuing
if current_find <> '' then
   begin
   lblStatus2.Caption := LNG_PROCESS_WAITING;
   TimerDetectApp.Enabled := true;
   end
else
  begin
  if current_index < apps.RowCount-1 then
     begin
     current_index := current_index+1;
     Load_App_Data(current_index);
     TimerStartApp.Enabled := true;
     end
  else
     begin
     lblStatus.Caption := LNG_MAIN_STARTING;
     lblStatus2.Caption := '';
     TimerMainApp.Interval := main_delay;
     TimerMainApp.Enabled  := true;
     end;
  end;


end;

procedure TfrmMain.TimerCloseTimer(Sender: TObject);
begin
Close;
end;

procedure TfrmMain.TimerDetectAppTimer(Sender: TObject);
var pid:cardinal;
begin
// wait for process or asume started if no process name given
if ( processExists(current_find, pid) ) OR (current_find = '') then
  begin
  TimerDetectApp.Enabled := false;
  if current_index < apps.RowCount-1 then
     begin
     current_index := current_index+1;
     Load_App_Data(current_index);
     TimerStartApp.Enabled := true;
     end
  else
     begin
     lblStatus.Caption := LNG_MAIN_STARTING;
     lblStatus2.Caption := '';
     TimerMainApp.Interval := main_delay;
     TimerMainApp.Enabled  := true;
     end;
  end
else
  begin
  wait_for_count_cycle := wait_for_count_cycle+1;
  // if app doesn't start within a minute (60 seconds * 10 checks per second)
  if wait_for_count_cycle > 600 then
    begin
    lblStatus2.Caption := LNG_ERR_PROCESS_TIMEOUT;
    TimerDetectApp.Enabled := false;

    if current_required then TimerClose.Enabled := true
    else
      begin
      if current_index < apps.RowCount-1 then
         begin
         current_index := current_index+1;
         Load_App_Data(current_index);
         TimerStartApp.Enabled := true;
         end
      else
         begin
         lblStatus.Caption := LNG_MAIN_STARTING;
         lblStatus2.Caption := '';
         TimerMainApp.Interval := main_delay;
         TimerMainApp.Enabled  := true;
         end;

      end;
    exit;

    end;
  end;

end;



procedure TfrmMain.TimerMainAppTimer(Sender: TObject);
begin
TimerMainApp.Enabled := false;

if not FileExists(main_path) then
   begin
   lblStatus.Caption := LNG_MAIN_NOT_FOUND;

   LocateApp.FileName := '';
   if LocateApp.Execute then
      begin
      lblStatus2.Caption := LNG_MAIN_LOCATED;
      main_path := LocateApp.FileName;
      ini.WriteString(MAIN_APP_SECTION, 'Path', main_path);
      ini.UpdateFile;
      end
   else
      begin
        lblStatus2.Caption := LNG_ERR_MAIN_NOT_FOUND;
        TimerClose.Enabled := true;
      end;
   end;

if main_admin then RunAsAdmin(0, main_path,'')
              else ShellExecute(0, 'open', PChar(main_path),nil,PChar(ExtractFilePath(main_path)),SW_SHOWNORMAL);

lblStatus.Caption := LNG_SHUT_DOWN;
lblStatus2.Caption := '';

TimerClose.Enabled := true;

end;

end.
