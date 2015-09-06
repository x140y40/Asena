unit untUtils;

interface

uses
  Windows;

type
  TAPIRec = packed record
    hKernel32, hUser32, hShell32, hShFolder, hAdvapi32: Cardinal;
    xGetProcAddressEx:function(hBase, hHash, dwLen:Cardinal):Pointer;stdcall;
    xGetProcAddress:function(hModule: HMODULE; lpProcName: LPCSTR): FARPROC; stdcall;
    xAllocMem:function(pAPI:Pointer; dwSize:Cardinal):Pointer;stdcall;
    xFreeMem:procedure(pAPI:Pointer; pData:Pointer);stdcall;
    xExitProcess:procedure(uExitCode: UINT); stdcall;
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
    xRtlGetCompressionWorkSpaceSize: function (CompressionFormatAndEngine: ULONG; CompressBufferWorkSpaceSize, CompressFragmentWorkSpaceSize : PULONG): Cardinal; stdcall; external ntdll name 'RtlGetCompressionWorkSpaceSize';
    xRtlCompressBuffer:function(CompressionFormatAndEngine: ULONG; SourceBuffer: Pointer; SourceBufferLength: ULONG; DestinationBuffer: Pointer; DestinationBufferLength: ULONG;SourceChunkSize: ULONG; pDestinationSize: PULONG; WorkspaceBuffer: Pointer): Cardinal; stdcall; external ntdll name 'RtlCompressBuffer';
    xRtlDeCompressBuffer:function (CompressionFormatAndEngine:ULONG; DestinationBuffer: Pointer; DestinationBufferLength: ULONG; SourceBuffer: Pointer; SourceBufferLength: ULONG;pDestinationSize: PULONG): Cardinal; stdcall; external ntdll name 'RtlDecompressBuffer';
  end;
  PAPIRec = ^TAPIRec;

implementation

end.
