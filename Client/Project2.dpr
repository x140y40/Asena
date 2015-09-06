program Project2;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  untClientObject in 'untClientObject.pas',
  untUtil in 'untUtil.pas',
  untCommands in 'untCommands.pas',
  untUtils in '..\Server\untUtils.pas',
  untFilemanager in 'untFilemanager.pas' {Form2},
  untControl in 'untControl.pas' {Form3};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.
