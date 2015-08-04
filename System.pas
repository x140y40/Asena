unit System;

interface

procedure _HandleFinally;

type

TGUID = record

D1: LongWord;

D2: Word;

D3: Word;

D4: array [0..7] of Byte;

end;

PInitContext = ^TInitContext;

TInitContext = record

OuterContext: PInitContext; 

ExcFrame: Pointer; 

InitTable: pointer; 

InitCount: Integer; 

Module: pointer; 

DLLSaveEBP: Pointer; 

DLLSaveEBX: Pointer; 

DLLSaveESI: Pointer; 

DLLSaveEDI: Pointer; 

ExitProcessTLS: procedure; 

DLLInitState: Byte; 

end;

procedure _ROUND;
procedure       _TRUNC;
function Get8087CW: Word;
procedure Set8087CW(NewCW: Word);
procedure       Move( const Source; var Dest; count : Integer );
var
  Default8087CW: Word = $1332;

implementation

procedure       Move( const Source; var Dest; count : Integer );
{$IFDEF PUREPASCAL}
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
{$ELSE}
asm
{     ->EAX     Pointer to source       }
{       EDX     Pointer to destination  }
{       ECX     Count                   }

        PUSH    ESI
        PUSH    EDI

        MOV     ESI,EAX
        MOV     EDI,EDX

        MOV     EAX,ECX

        CMP     EDI,ESI
        JA      @@down
        JE      @@exit

        SAR     ECX,2           { copy count DIV 4 dwords       }
        JS      @@exit

        REP     MOVSD

        MOV     ECX,EAX
        AND     ECX,03H
        REP     MOVSB           { copy count MOD 4 bytes        }
        JMP     @@exit

@@down:
        LEA     ESI,[ESI+ECX-4] { point ESI to last dword of source     }
        LEA     EDI,[EDI+ECX-4] { point EDI to last dword of dest       }

        SAR     ECX,2           { copy count DIV 4 dwords       }
        JS      @@exit
        STD
        REP     MOVSD

        MOV     ECX,EAX
        AND     ECX,03H         { copy count MOD 4 bytes        }
        ADD     ESI,4-1         { point to last byte of rest    }
        ADD     EDI,4-1
        REP     MOVSB
        CLD
@@exit:
        POP     EDI
        POP     ESI
end;
{$ENDIF}

procedure Set8087CW(NewCW: Word);
begin
  Default8087CW := NewCW;
  asm
        FNCLEX  // don't raise pending exceptions enabled by the new flags
{$IFDEF PIC}
        MOV     EAX,[EBX].OFFSET Default8087CW
        FLDCW   [EAX]
{$ELSE}
        FLDCW   Default8087CW
{$ENDIF}
  end;
end;

procedure       _ROUND;
asm
        { ->    FST(0)  Extended argument       }
        { <-    EDX:EAX Result                  }

        SUB     ESP,8
        FISTP   qword ptr [ESP]
        FWAIT
        POP     EAX
        POP     EDX
end;
procedure       _TRUNC;
asm
       { ->    FST(0)   Extended argument       }
       { <-    EDX:EAX  Result                  }

        SUB     ESP,12
        FNSTCW  [ESP].Word          // save
        FNSTCW  [ESP+2].Word        // scratch
        FWAIT
        OR      [ESP+2].Word, $0F00  // trunc toward zero, full precision
        FLDCW   [ESP+2].Word
        FISTP   qword ptr [ESP+4]
        FWAIT
        FLDCW   [ESP].Word
        POP     ECX
        POP     EAX
        POP     EDX
end;
function Get8087CW: Word;
asm
        PUSH    0
        FNSTCW  [ESP].Word
        POP     EAX
end;
procedure _HandleFinally;
asm
end;

end.

