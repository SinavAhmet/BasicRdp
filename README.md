# BasicRdp<br>
Connect with rdp basically with user name,password,server and name.<br>
Create new vcl form application and add jwaWinCrypt to your unit.<br>
Sample usage:<br>
<br>
function CryptRDPPassword(sPassword: string): string;<br>
var DataIn: DATA_BLOB;<br>
    DataOut: DATA_BLOB;<br>
    pwDescription: PWideChar;<br>
    PwdHash: string;<br>
begin<br>
  PwdHash := '';<br>
<br>
  DataOut.cbData := 0;<br>
  DataOut.pbData := nil;<br>
<br>
  // RDP uses UniCode<br>
  DataIn.pbData := Pointer(WideString(sPassword));<br>
  DataIn.cbData := Length(sPassword) * SizeOf(WChar);<br>
<br>
  // RDP always sets description to psw<br>
  pwDescription := WideString('psw');<br>
<br>
  if CryptProtectData(@DataIn,<br>
                      pwDescription,<br>
                      nil,<br>
                      nil,<br>
                      nil,<br>
                      CRYPTPROTECT_UI_FORBIDDEN,  // Never show interface<br>
                      @DataOut) then<br>
  begin<br>
    PwdHash := BlobDataToHexStr(DataOut.pbData, DataOut.cbData);<br>
  end;<br>
  Result := PwdHash;<br>
<br>
  // Cleanup<br>
  LocalFree(Cardinal(DataOut.pbData));<br>
  LocalFree(Cardinal(DataIn.pbData));<br>
end;<br>
<br>
procedure CnnRdp(user,pass,srv,dmn:String);<br>
var<br>
  s : String;<br>
  cmd : PAnsiChar;<br>
  strLst : TStringList;<br>
begin<br>
  s := CryptRDPPassword(pass);<br>
  strLst := TStringList.Create;<br>
  strLst.Add('screen mode id:i:1');<br>
  strLst.Add('desktopwidth:i:1280');<br>
  strLst.Add('desktopheight:i:750');<br>
  strLst.Add('session bpp:i:24');<br>
  strLst.Add('winposstr:s:2,3,188,8,1062,721');<br>
  strLst.Add('full address:s:'+srv);<br>
  strLst.Add('compression:i:1');<br>
  strLst.Add('keyboardhook:i:2');<br>
  strLst.Add('audiomode:i:0');<br>
  strLst.Add('redirectdrives:i:0');<br>
  strLst.Add('redirectprinters:i:0');<br>
  strLst.Add('redirectcomports:i:0');<br>
  strLst.Add('redirectsmartcards:i:0');<br>
  strLst.Add('displayconnectionbar:i:1');<br>
  strLst.Add('autoreconnection enabled:i:1');<br>
  strLst.Add('username:s:'+user);<br>
  strLst.Add('domain:s:'+dmn);<br>
  strLst.Add('alternate shell:s:');<br>
  strLst.Add('shell working directory:s:');<br>
  strLst.Add('password 51:b:'+s);<br>
  strLst.Add('disable wallpaper:i:1');<br>
  strLst.Add('disable full window drag:i:1');<br>
  strLst.Add('disable menu anims:i:1');<br>
  strLst.Add('disable themes:i:0');<br>
  strLst.Add('disable cursor setting:i:0');<br>
  strLst.Add('bitmapcachepersistenable:i:1');<br>
  strLst.SaveToFile(ExtractFilePath(ParamStr(0))+'a.rdp');<br>
<br>
  s := ExtractFilePath(ParamStr(0))+'a.rdp';<br>
  ShellExecute(0,'open','mstsc.exe',PWideChar(s),nil,SW_SHOWNORMAL);<br>
End;<br>
