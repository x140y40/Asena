unit untUtils;

interface

uses
  Windows;

type
  TAPIRec = packed record
    hKernel32, hUser32, hShell32, hShFolder : Cardinal;
    xExitProcess:procedure(uExitCode: UINT); stdcall;
    xLoadLibraryA:function(lpLibFileName: PChar): Cardinal; stdcall;
    xMessageBoxW:function(hWnd: HWND; lpText, lpCaption: PWideChar; uType: UINT): Integer; stdcall;
    xVirtualAlloc:function(lpvAddress: Pointer; dwSize, flAllocationType, flProtect: DWORD): Pointer; stdcall;
    xGetModuleFileNameW:function(hModule: HINST; lpFilename: PWideChar; nSize: DWORD): DWORD; stdcall;
    xlstrlenW:function(lpString: PWideChar): Integer; stdcall;
    xlstrcmpW:function(lpString1, lpString2: PWideChar): Integer; stdcall;
    xlstrcatW:function(lpString1, lpString2: PWideChar): PWideChar; stdcall;
    xCopyFileW:function(lpExistingFileName, lpNewFileName: PWideChar; bFailIfExists: BOOL): BOOL; stdcall;
    xShellExecuteW:function(hWnd: HWND; Operation, FileName, Parameters, Directory: PWideChar; ShowCmd: Integer): HINST; stdcall;
    xSHGetFolderPathW:function(hwnd: HWND; csidl: Integer; hToken: THandle; dwFlags: DWORD; pszPath: PWideChar): HResult; stdcall;
    xwsprintfW:function(Output: PWideChar; Format: PWideChar): Integer; cdecl varargs;
  end;
  PAPIRec = ^TAPIRec;

implementation

end.
