unit untUtil;

interface

uses
  Windows,
  Sysutils,
  shlwapi,
  Classes;

type
  LPSocketHeader = ^TSocketHeader;
  TSocketHeader = packed Record
    bCommand: Byte;
    dwStreamID: DWORD;
    dwPacketLen: DWORD;
    dwDecompressedLen: DWORD;
    dwTotalLen: DWORD;
  end;

Function Explode(sDelimiter: String; sSource: String): TStringList;
function FormatByteSize(const bytes: Longword): string;
function GetFileAttributes(cAttr:Cardinal):String;

implementation
function GetFileAttributes(cAttr:Cardinal):String;
begin
  Result := '';
  if ((cAttr and FILE_ATTRIBUTE_DIRECTORY) <> 0) then
    Result := Result + 'R';

  if ((cAttr and FILE_ATTRIBUTE_HIDDEN) <> 0) then
    Result := Result + 'H';

  if ((cAttr and FILE_ATTRIBUTE_SYSTEM) <> 0) then
    Result := Result + 'S';

  if ((cAttr and FILE_ATTRIBUTE_ARCHIVE) <> 0) then
    Result := Result + 'A';

  if ((cAttr and FILE_ATTRIBUTE_NORMAL) <> 0) then
    Result := Result + 'N';
end;

function FormatByteSize(const bytes: Longword): string;
var
  B: byte;
  KB: word;
  MB: Longword;
  GB: Longword;
  TB: UInt64;
begin
  B  := 1; //byte
  KB := 1024 * B; //kilobyte
  MB := 1000 * KB; //megabyte
  GB := 1000 * MB; //gigabyte
  TB := 1000 * GB; //teraabyte

  if bytes > TB then
    result := FormatFloat('#.## TB', bytes / TB)
  else
    if bytes > GB then
      result := FormatFloat('#.## GB', bytes / GB)
    else
      if bytes > MB then
        result := FormatFloat('#.## MB', bytes / MB)
      else
        if bytes > KB then
          result := FormatFloat('#.## KB', bytes / KB)
        else
          result := FormatFloat('#.## Bytes', bytes) ;
  if bytes = 0 then
    Result := '0 Bytes';
end;

Function Explode(sDelimiter: String; sSource: String): TStringList;
Var
  c: Word;
Begin
  Result := TStringList.Create;
  C := 0;
  While sSource <> '' Do
  Begin
    If Pos(sDelimiter, sSource) > 0 Then
    Begin
      Result.Add(Copy(sSource, 1, Pos(sDelimiter, sSource) - 1 ));
      Delete(sSource, 1, Length(Result[c]) + Length(sDelimiter));
    End
    Else
    Begin
      Result.Add(sSource);
      sSource := ''
    End;
    Inc(c);
  End;
End;
end.
