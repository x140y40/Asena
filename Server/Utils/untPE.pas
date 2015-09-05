unit untPE;

interface

uses
  Windows,
  Classes;

type
  TPEFile = class(TObject)
  private
    mFile:TMemoryStream;
    IDH:  TImageDosHeader;
    INH:  TImageNtHeaders;
    ISH:  TImageSectionHeader;
    dwSizeAll: Cardinal;
    procedure CreateImageHeader;
    procedure CreateNTHeader;
    procedure CreateSectionHeader;
  protected
  public
    procedure AddFunction(pFunc, pFuncEnd:Pointer);
    procedure FixSectionLen;
    procedure CustomizeLoader;
    procedure CreatePEBase;
    procedure SaveFile(strFile:String);
    constructor Create;
  end;

implementation

constructor TPEFile.Create;
begin
  mFile := TMemoryStream.Create;
  dwSizeAll := 0;
end;

procedure TPEFile.CreatePEBase;
begin
  CreateImageHeader;
  CreateNTHeader;
  CreateSectionHeader;
end;

procedure TPEFile.CreateImageHeader;
begin
  FillChar(IDH, 64, $0);
  IDH.e_magic := IMAGE_DOS_SIGNATURE;
  IDH._lfanew := $40;

  mFile.WriteBuffer(IDH, 64);
end;

procedure TPEFile.CreateNTHeader;
begin
  FillChar(INH, 248, $0);
  INH.Signature := IMAGE_NT_SIGNATURE;
  INH.FileHeader.Machine := $014C;
  INH.FileHeader.NumberOfSections := 1;
  INH.FileHeader.SizeOfOptionalHeader := $E0;
  INH.FileHeader.Characteristics := $010F;

  INH.OptionalHeader.Magic := $010B;
  INH.OptionalHeader.MajorLinkerVersion := 1;
  INH.OptionalHeader.MinorLinkerVersion := 2;
  INH.OptionalHeader.SizeOfCode := $200;
  INH.OptionalHeader.SizeOfInitializedData := $200;
  INH.OptionalHeader.AddressOfEntryPoint := $1000;
  INH.OptionalHeader.BaseOfCode := $1000;
  INH.OptionalHeader.BaseOfData := $1000;
  INH.OptionalHeader.ImageBase := $00400000;
  INH.OptionalHeader.SectionAlignment := $1000;
  INH.OptionalHeader.FileAlignment := $200;
  INH.OptionalHeader.SizeOfImage := $2000;
  INH.OptionalHeader.SizeOfHeaders := $200;
  INH.OptionalHeader.Subsystem := 2;
  INH.OptionalHeader.SizeOfStackReserve := $100000;
  INH.OptionalHeader.SizeOfStackCommit := $4000;
  INH.OptionalHeader.SizeOfHeapReserve := $100000;
  INH.OptionalHeader.SizeOfHeapCommit := $1000;
  INH.OptionalHeader.NumberOfRvaAndSizes := $10;
  INH.OptionalHeader.MajorSubsystemVersion := 4;
  INH.OptionalHeader.MajorOperatingSystemVersion := 4;

  mFile.Seek($40, soBeginning);
  mFile.WriteBuffer(INH, 248);
end;

procedure TPEFile.CreateSectionHeader;
var
  dwSpace:  Cardinal;
  pBuff:    Pointer;
const
  szText:   ansistring = '.text';
begin
  FillChar(ISH, 40, $0);
  CopyMemory(@ISH.Name[0], @szText[1], Length(szText));
  ISH.PointerToRawData := $200;
  ISH.SizeOfRawData := 0;
  ISH.VirtualAddress := $1000;
  ISH.Misc.VirtualSize := $1000;
  ISH.Characteristics := $60000060;

  mFile.Seek($40 + 248, soBeginning);
  mFile.WriteBuffer(ISH, 40);

  dwSpace := $200 - (64 + 248 + 40);
  GetMem(pBuff, dwSpace);
  mFile.Seek(0, soEnd);
  mFile.WriteBuffer(pBuff^, dwSpace);
  FreeMem(pBuff);
end;

procedure TPEFile.AddFunction(pFunc, pFuncEnd:Pointer);
var
  dwSize:Cardinal;
begin
  dwSize := DWORD(pFuncEnd) - DWORD(pFunc);
  dwSizeAll := dwSizeAll + dwSize;
  mFile.Seek(0, soEnd);
  mFile.WriteBuffer(pFunc^, dwSize);
end;

procedure TPEFile.FixSectionLen;
begin
  ISH.SizeOfRawData := dwSizeAll;

  mFile.Seek($40 + 248, soBeginning);
  mFile.WriteBuffer(ISH, 40);
end;

procedure TPEFile.CustomizeLoader;
var
  i:Integer;
  lResLen:Cardinal;
begin
  mFile.Seek(0, soBeginning);
  lResLen := dwSizeAll + $00401000;
  for i := 0 to mFile.Size - 1 do
  begin
    if (PDWORD(Pointer(DWORD(mFile.Memory) + i))^ = $DEADC0DE) then
    begin
      mFile.Seek(i, soBeginning);
      mFile.WriteBuffer(lResLen, SizeOf(DWORD));
      break;
    end;
  end;
end;

procedure TPEFile.SaveFile(strFile:String);
begin
  FixSectionLen;
  mFile.Position := 0;
  mFile.SaveToFile(strFile);
end;
end.
