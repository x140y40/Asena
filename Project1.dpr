program Project1;

uses
  Windows;

type
  TAPIRec = packed record
    hKernel32, hUser32, hShell32 : Cardinal;
    xExitProcess:procedure(uExitCode: UINT); stdcall;
    xLoadLibraryA:function(lpLibFileName: PChar): Cardinal; stdcall;
    xMessageBoxA:function(hWnd: HWND; lpText, lpCaption: PAnsiChar; uType: UINT): Integer; stdcall;
    xVirtualAlloc:function(lpvAddress: Pointer; dwSize, flAllocationType, flProtect: DWORD): Pointer; stdcall;
    xGetModuleFileNameW:function(hModule: HINST; lpFilename: PWideChar; nSize: DWORD): DWORD; stdcall;
    xlstrlenW:function(lpString: PWideChar): Integer; stdcall;
    xlstrcmpW:function(lpString1, lpString2: PWideChar): Integer; stdcall;
    xlstrcatW:function(lpString1, lpString2: PWideChar): PWideChar; stdcall;
  end;
  PAPIRec = ^TAPIRec;
  
function AllocMem(pAPI:PAPIRec; dwSize:Cardinal):Pointer;
begin
  Result := pAPI.xVirtualAlloc(nil, dwSize, MEM_COMMIT, PAGE_READWRITE);
end;

function LastDelimiter(pAPI:PAPIRec; S: PWideChar; Delimiter: WideChar): Integer;
var
  i: Integer;
begin
  result := -1;
  i := pAPI.xlstrlenW(s);
  if (i = 0) then
    Exit;
  while S[i] <> Delimiter do
  begin
    if i < 0 then
      break;
    dec(i);
  end;
  result := i;
end;

procedure ExtractFilePath(pAPI:PAPIRec; szFileName:PWideChar);
var
  I: Integer;
  strSlash:Array[0..1] of WideChar;
begin
  strSlash[0] := '\';strSlash[0] := #0;
  I := LastDelimiter(pAPI, szFilename, strSlash[0]) * 2;
  ZeroMemory(Pointer(DWORD(szFileName) + i), (lstrlenW(szFileName) * 2) - i);
end;

function GetCurrentDir(pAPI:PAPIRec):PWideChar;
var
  strSlash:Array[0..1] of WideChar;
begin
  strSlash[0] := '\';strSlash[0] := #0;
  Result := AllocMem(pAPI, MAX_PATH * 2);
  if Result <> nil then
  begin
    pAPI.xGetModuleFileNameW(0, Result, MAX_PATH * 2);
    ExtractFilePath(pAPI, Result);
    if pAPI.xlstrcmpW(PWideChar(DWORD(Result) + ((pAPI.xlstrlenW(Result) - 1) * 2) ), @strSlash) <> 0 then
      pAPI.xlstrcatW(Result, @strSlash);
  end;
end;

procedure CopyMySelf(pGetProcAddress, pGetModuleHandle:Cardinal);
begin

end;

procedure resolver;
  procedure LoadLib(pAPI:PAPIRec);stdcall;
  var
    strUser32:Array[0..10] of Char;
    strShell32:Array[0..11] of Char;
  begin
    strUser32[0]:='u';strUser32[1]:='s';strUser32[2] := 'e';strUser32[3]:='r';strUser32[4]:='3';strUser32[5]:='2';strUser32[6]:='.';strUser32[7]:='d';strUser32[8]:='l';strUser32[9]:='l';strUser32[10]:=#0;
    strShell32[0]:='s';strShell32[1]:='h';strShell32[2]:='e';strShell32[3]:='l';strShell32[4]:='l';strShell32[5]:='3';strShell32[6]:='2';strShell32[7]:='.';strShell32[8]:='d';strShell32[9]:='l';strShell32[10]:='l';strShell32[11]:=#0;
    pAPI.hUser32 := pAPI.xLoadLibraryA(@strUser32[0]);
    pAPI.hShell32 := pAPI.xLoadLibraryA(@strShell32[0]);
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
  pAPI.hKernel32 := hKernel32;
  pAPI.xLoadLibraryA := GetProcAddressEx(hKernel32, $3FC1BD8D, 12);
  LoadLib(pAPI);
  pAPI.xExitProcess := GetProcAddressEx(hKernel32, $251097CC, 11);
  pAPI.xMessageBoxA := GetProcAddressEx(pAPI.hUser32, $572D5D8E, 11);
  pAPI.xVirtualAlloc := pVirtualAlloc;
  pAPI.xGetModuleFileNameW := GetProcAddressEx(hKernel32, $FC6B42F1, 18);
  pAPI.xlstrlenW := GetProcAddressEx(hKernel32, $1DDA9F5D, 8);
  pAPI.xlstrcmpW := GetProcAddressEx(hKernel32, $9FEBE16C, 8);
  pAPI.xlstrcatW := GetProcAddressEx(hKernel32, $F29DDD0C, 8);
  pAPI.xMessageBoxA(0, nil, nil, 0);
  pAPI.xExitProcess(0);
end;

begin
   resolver;
  { TODO -oUser -cConsole Main : Insert code here }
end.
