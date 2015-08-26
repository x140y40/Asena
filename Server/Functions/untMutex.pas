unit untMutex;

interface

uses
  Windows,
  untUtils;

procedure MutexCheck(pAPI:PAPIRec);

implementation

procedure MutexCheck(pAPI:PAPIRec);
var
  xCreateMutexW:function(lpMutexAttributes: PSecurityAttributes; bInitialOwner: Integer; lpName: PWideChar): THandle; stdcall;
  xGetLastError:function:DWORD; stdcall;
  strMutex:Array[0..4] of WideChar;
begin
  strMutex[0]:='a';strMutex[1]:='a';strMutex[2]:='a';strMutex[3]:='a';strMutex[4]:=#0;
  xCreateMutexW := pAPI.xGetProcAddressEx(pAPI.hKernel32, $2D789102, 12);
  xGetLastError := pAPI.xGetProcAddressEx(pAPI.hKernel32, $D2E536B7, 12);
  xCreateMutexW(nil, 0, @strMutex[0]);
  if xGetLastError = ERROR_ALREADY_EXISTS then
    pAPI.xExitProcess(0);
end;
procedure MutexCheck_END();begin end;

end.
