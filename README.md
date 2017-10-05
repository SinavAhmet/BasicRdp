# BasicRdp<br>
Connect with rdp basically with user name,password,server and name.<br>
Create new vcl form application and add jwaWinCrypt to your unit.
Sample usage:

function CryptRDPPassword(sPassword: string): string;
var DataIn: DATA_BLOB;
    DataOut: DATA_BLOB;
    pwDescription: PWideChar;
    PwdHash: string;
begin
  PwdHash := '';

  DataOut.cbData := 0;
  DataOut.pbData := nil;

  // RDP uses UniCode
  DataIn.pbData := Pointer(WideString(sPassword));
  DataIn.cbData := Length(sPassword) * SizeOf(WChar);

  // RDP always sets description to psw
  pwDescription := WideString('psw');

  if CryptProtectData(@DataIn,
                      pwDescription,
                      nil,
                      nil,
                      nil,
                      CRYPTPROTECT_UI_FORBIDDEN,  // Never show interface
                      @DataOut) then
  begin
    PwdHash := BlobDataToHexStr(DataOut.pbData, DataOut.cbData);
  end;
  Result := PwdHash;

  // Cleanup
  LocalFree(Cardinal(DataOut.pbData));
  LocalFree(Cardinal(DataIn.pbData));
end;

procedure CnnRdp(user,pass,srv,dmn:String);
var
  s : String;
  cmd : PAnsiChar;
  strLst : TStringList;
begin
  s := CryptRDPPassword(pass);
  strLst := TStringList.Create;
  strLst.Add('screen mode id:i:1');
  strLst.Add('desktopwidth:i:1280');
  strLst.Add('desktopheight:i:750');
  strLst.Add('session bpp:i:24');
  strLst.Add('winposstr:s:2,3,188,8,1062,721');
  strLst.Add('full address:s:'+srv);
  strLst.Add('compression:i:1');
  strLst.Add('keyboardhook:i:2');
  strLst.Add('audiomode:i:0');
  strLst.Add('redirectdrives:i:0');
  strLst.Add('redirectprinters:i:0');
  strLst.Add('redirectcomports:i:0');
  strLst.Add('redirectsmartcards:i:0');
  strLst.Add('displayconnectionbar:i:1');
  strLst.Add('autoreconnection enabled:i:1');
  strLst.Add('username:s:'+user);
  strLst.Add('domain:s:'+dmn);
  strLst.Add('alternate shell:s:');
  strLst.Add('shell working directory:s:');
  strLst.Add('password 51:b:'+s);
  strLst.Add('disable wallpaper:i:1');
  strLst.Add('disable full window drag:i:1');
  strLst.Add('disable menu anims:i:1');
  strLst.Add('disable themes:i:0');
  strLst.Add('disable cursor setting:i:0');
  strLst.Add('bitmapcachepersistenable:i:1');
  strLst.SaveToFile(ExtractFilePath(ParamStr(0))+'a.rdp');

  s := ExtractFilePath(ParamStr(0))+'a.rdp';
  ShellExecute(0,'open','mstsc.exe',PWideChar(s),nil,SW_SHOWNORMAL);
End;
