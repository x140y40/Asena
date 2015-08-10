program Project1;

uses
  Windows,
  untStartUp in 'Functions\untStartUp.pas',
  untUtils in 'untUtils.pas',
  untInstallation in 'Functions\untInstallation.pas',
  untLoader in 'Loader\untLoader.pas';

procedure CreatePEBase(hFile:DWORD);
var
  IDH:  TImageDosHeader;
  INH:  TImageNtHeaders;
  ISH:  TImageSectionHeader;
  dwNull: DWORD;
  pBuff:  Pointer;
  dwSpace:  DWORD;
  dwSize:Cardinal;
const
  szText:   string = '.text';
begin

  dwSize := DWORD(@resolver_end) - DWORD(@resolver_start);

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

  SetFilePointer(hFile, 0, nil, FILE_BEGIN);
  WriteFile(hFile, IDH, 64, dwNull, nil);
  SetFilePointer(hFile, $40, nil, FILE_BEGIN);
  WriteFile(hFile, INH, 248, dwNull, nil);
  SetFilePointer(hFile, $40 + 248, nil, FILE_BEGIN);
  WriteFile(hFile, ISH, 40, dwNull, nil);

  dwSpace := $200 - (64 + 248 + 40);
  GetMem(pBuff, dwSpace);
  SetFilePointer(hFile, 0, nil, FILE_END);
  WriteFile(hFile, pBuff^, dwSpace, dwNull, nil);
  FreeMem(pBuff);
end;

procedure BuildSetup();
var
  hFile:  DWORD;
  dwNull: DWORD;
  pBuff:  Pointer;
  dwPos:  DWORD;
  pFunc:  Pointer;
  dwSize: DWORD;
  dwLen:DWORD;
begin
  dwSize := DWORD(@resolver_end) - DWORD(@resolver_start);
  hFile := CreateFile('Test.exe', GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_ALWAYS, 0, 0);
  if hFile <> INVALID_HANDLE_VALUE then
  begin
    CreatePEBase(hFile);
    GetMem(pBuff, dwSize);
    ZeroMemory(pBuff, dwSize);
    pFunc := @resolver_start;
    CopyMemory(pBuff, pFunc, dwSize);
    SetFilePointer(hFile, 0, nil, FILE_END);
    WriteFile(hFile, pBuff^, dwSize, dwNull, nil);
    FreeMem(pBuff);
    CloseHandle(hFile);
  end;
end;
begin
   BuildSetup;
end.
