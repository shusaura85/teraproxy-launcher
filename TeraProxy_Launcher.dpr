program TeraProxy_Launcher;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {frmMain},
  uFunctions in 'uFunctions.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
