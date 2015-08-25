program Project2;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  untClientObject in 'untClientObject.pas',
  untUtils in 'untUtils.pas',
  untCommands in 'untCommands.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
