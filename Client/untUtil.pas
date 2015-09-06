unit untUtil;

interface

uses
  Windows,

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

implementation
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
