unit CryptUtil;
////////////////////////////////////////////////////////////////////////////////
//
//   Unit        :  CryptUtil.pas
//   Author      :  rllibby
//   Date        :  06.05.2006
//   Description :  Sample unit that demonstrates using the Crypto API to
//                  (en/de)code data string values. If the Crypto API is not
//                  available, then Base64 encoding is used instead.
//
//   The DIMime.pas unit can be downloaded from:
//
//      http://www.zeitungsjunge.de/delphi/mime
//
////////////////////////////////////////////////////////////////////////////////
interface

////////////////////////////////////////////////////////////////////////////////
//   Include units
////////////////////////////////////////////////////////////////////////////////
uses
  Windows, SysUtils, DIMime;

////////////////////////////////////////////////////////////////////////////////
//   Constant declarations
////////////////////////////////////////////////////////////////////////////////
const
  CRYPT_HEADER      =  #3#4;
  CRYPT_LIBRARY     =  'Crypt32.dll';
  CRYPT_PROTECT     =  'CryptProtectData';
  CRYPT_UNPROTECT   =  'CryptUnprotectData';

////////////////////////////////////////////////////////////////////////////////
//   Type declarations
////////////////////////////////////////////////////////////////////////////////
type
  TLargeByteArray      =  Array [0..Pred(MaxInt)] of Byte;
  PLargeByteArray      =  ^TLargeByteArray;

  _CRYPTOAPI_BLOB      =  packed record
     cbData:           DWORD;
     pbData:           PLargeByteArray;
  end;

  TCryptoApiBlob       =  _CRYPTOAPI_BLOB;
  PCrypyoApiBlob       =  ^TCryptoApiBlob;
  CRYPT_INTEGER_BLOB   =  _CRYPTOAPI_BLOB;
  PCRYPT_INTEGER_BLOB  =  ^CRYPT_INTEGER_BLOB;
  CRYPT_UINT_BLOB      =  _CRYPTOAPI_BLOB;
  PCRYPT_UINT_BLOB     =  ^CRYPT_INTEGER_BLOB;
  CRYPT_OBJID_BLOB     =  _CRYPTOAPI_BLOB;
  PCRYPT_OBJID_BLOB    =  ^CRYPT_INTEGER_BLOB;
  CERT_NAME_BLOB       =  _CRYPTOAPI_BLOB;
  PCERT_NAME_BLOB      =  ^CRYPT_INTEGER_BLOB;
  CERT_RDN_VALUE_BLOB  =  _CRYPTOAPI_BLOB;
  PCERT_RDN_VALUE_BLOB =  ^CRYPT_INTEGER_BLOB;
  CERT_BLOB            =  _CRYPTOAPI_BLOB;
  PCERT_BLOB           =  ^CRYPT_INTEGER_BLOB;
  CRL_BLOB             =  _CRYPTOAPI_BLOB;
  PCRL_BLOB            =  ^CRYPT_INTEGER_BLOB;
  DATA_BLOB            =  _CRYPTOAPI_BLOB;
  PDATA_BLOB           =  ^CRYPT_INTEGER_BLOB;
  CRYPT_DATA_BLOB      =  _CRYPTOAPI_BLOB;
  PCRYPT_DATA_BLOB     =  ^CRYPT_INTEGER_BLOB;
  CRYPT_HASH_BLOB      =  _CRYPTOAPI_BLOB;
  PCRYPT_HASH_BLOB     =  ^CRYPT_INTEGER_BLOB;
  CRYPT_DIGEST_BLOB    =  _CRYPTOAPI_BLOB;
  PCRYPT_DIGEST_BLOB   =  ^CRYPT_INTEGER_BLOB;
  CRYPT_DER_BLOB       =  _CRYPTOAPI_BLOB;
  PCRYPT_DER_BLOB      =  ^CRYPT_INTEGER_BLOB;
  CRYPT_ATTR_BLOB      =  _CRYPTOAPI_BLOB;
  PCRYPT_ATTR_BLOB     =  ^CRYPT_INTEGER_BLOB;

type
  _CRYPTPROTECT_PROMPTSTRUCT =  packed record
     cbSize:           DWORD;
     dwPromptFlags:    DWORD;
     hwndApp:          HWND;
     szPrompt:         LPCWSTR;
  end;
  TCryptProtectPromptStruct  =  _CRYPTPROTECT_PROMPTSTRUCT;
  PCryptProtectPromptStruct  =  ^TCryptProtectPromptStruct;
  CRYPTPROTECT_PROMPTSTRUCT  =  _CRYPTPROTECT_PROMPTSTRUCT;
  PCRYPTPROTECT_PROMPTSTRUCT =  ^_CRYPTPROTECT_PROMPTSTRUCT;

////////////////////////////////////////////////////////////////////////////////
//   Function prototypes
////////////////////////////////////////////////////////////////////////////////
type
  TCryptProtect     =  function(pDataIn:          PDATA_BLOB;
                                szDataDescr:      LPCWSTR;
                                pOptionalEntropy: PDATA_BLOB;
                                pReserved:        Pointer;
                                pPromptStruct:    PCRYPTPROTECT_PROMPTSTRUCT;
                                dwFlags:          DWORD;
                                pDataOut:         PDATA_BLOB): BOOL; stdcall;

  TCryptUnprotect   =  function(pDataIn:          PDATA_BLOB;
                                var ppszDataDescr:LPWSTR;
                                pOptionalEntropy: PDATA_BLOB;
                                pReserved:        Pointer;
                                pPromptStruct:    PCRYPTPROTECT_PROMPTSTRUCT;
                                dwFlags:          DWORD;
                                pDataOut:         PDATA_BLOB): BOOL; stdcall;


////////////////////////////////////////////////////////////////////////////////
//   Functions
////////////////////////////////////////////////////////////////////////////////
function   CryptEncode(Value: String): String;
function   CryptDecode(Value: String): String;

implementation

////////////////////////////////////////////////////////////////////////////////
//   Protected variables
////////////////////////////////////////////////////////////////////////////////
var
  hCryptLib:        THandle           =  0;
  CryptProtect:     TCryptProtect     =  nil;
  CryptUnprotect:   TCryptUnprotect   =  nil;

procedure FreeDataBlob(var Data: DATA_BLOB);
begin

  // Check pointer to data
  if Assigned(Data.pbData) then LocalFree(HLOCAL(Data.pbData));

  // Clear struct
  FillChar(Data, SizeOf(DATA_BLOB), 0);

end;

function GetDataBlobText(Data: DATA_BLOB): String;
begin

  // Check blob pointer
  if (Data.cbData > 0) and Assigned(Data.pbData) then
     // Set result string
     SetString(result, PChar(Data.pbData), Data.cbData)
  else
     // Set null result
     SetLength(result, 0);

end;

function SetDataBlobText(Text: String; var Data: DATA_BLOB): Boolean;
begin

  // Clear struct
  FillChar(Data, SizeOf(DATA_BLOB), 0);

  // Check passed text
  if (Length(Text) > 0) then
  begin
     // Allocate memory for text
     Data.pbData:=Pointer(LocalAlloc(LPTR, Succ(Length(Text))));
     // Check pointer
     if Assigned(Data.pbData) then
     begin
        // Set buffer length
        Data.cbData:=Length(Text);
        // Move data
        Move(Pointer(Text)^, Data.pbData^, Data.cbData);
        // Success
        result:=True;
     end
     else
        // Failed to allocate memory
        result:=False;
  end
  else
     // Nothing to copy over
     result:=True;

end;

function CryptDecode(Value: String): String;
var  DataIn:        DATA_BLOB;
     DataOut:       DATA_BLOB;
     lpwszDesc:     PWideChar;
begin

  // Check value
  if (Length(Value) = 0) then
     // No encoding
     result:=EmptyStr
  else
  begin
     // Check string header
     if not(Pos(CRYPT_HEADER, Value) = 1) then
        // Use Base64 decoding on the string
        result:=MimeDecodeString(Value)
     // Check function pointer
     else if Assigned(@CryptUnProtect) then
     begin
        // Clear structs
        FillChar(DataIn, SizeOf(DATA_BLOB), 0);
        FillChar(DataOut, SizeOf(DATA_BLOB), 0);
        // Set text to be decrypted
        if SetDataBlobText(Copy(Value, Succ(Length(CRYPT_HEADER)), MaxInt), DataIn) then
        begin
           // Resource protection
           try
              // Decrypt the data
              if CryptUnprotect(@DataIn, lpwszDesc, nil, nil, nil, 0, @DataOut) then
              begin
                 // Resource protection
                 try
                    // Set result string
                    result:=GetDataBlobText(DataOut);
                 finally
                    // Free memory
                    FreeDataBlob(DataOut);
                    LocalFree(HLOCAL(lpwszDesc));
                 end;
              end
              else
                 // Failure
                 SetLength(result, 0);
           finally
              // Free memory
              FreeDataBlob(DataIn);
           end;
        end
        else
           // Failure
           SetLength(result, 0);
     end
     else
        // Can't decrypt the value because the required function is not available
        SetLength(result, 0);
  end;

end;

function CryptEncode(Value: String): String;
var  DataIn:        DATA_BLOB;
     DataOut:       DATA_BLOB;
begin

  // Check value
  if (Length(Value) = 0) then
     // No encoding
     result:=EmptyStr
  else
  begin
     // Check function address
     if (@CryptProtect = nil) then
        // Use Base64 encoding on the string
        result:=MimeEncodeString(Value)
     else
     begin
        // Clear structs
        FillChar(DataIn, SizeOf(DATA_BLOB), 0);
        FillChar(DataOut, SizeOf(DATA_BLOB), 0);
        // Set text to be encrypted
        if SetDataBlobText(Value, DataIn) then
        begin
           // Resource protection
           try
              // Encrypt the data
              if CryptProtect(@DataIn, PWideChar(WideString(#0)), nil, nil, nil, 0, @DataOut) then
              begin
                 // Resource protection
                 try
                    // Set result string
                    result:=CRYPT_HEADER+GetDataBlobText(DataOut);
                 finally
                    // Free memory
                    FreeDataBlob(DataOut);
                 end;
              end
              else
                 // Failure
                 SetLength(result, 0);
           finally
              // Free memory
              FreeDataBlob(DataIn);
           end;
        end
        else
           // Failure
           SetLength(result, 0);
     end;
  end;

end;

initialization

  // Attempt to load the library
  hCryptLib:=LoadLibrary(CRYPT_LIBRARY);

  // Check library handle
  if (hCryptLib <> 0) then
  begin
     // Attempt to bind to the crypt functions
     @CryptProtect:=GetProcAddress(hCryptLib, CRYPT_PROTECT);
     @CryptUnprotect:=GetProcAddress(hCryptLib, CRYPT_UNPROTECT);
  end;

finalization

  // Clear function pointers
  @CryptProtect:=nil;
  @CryptUnprotect:=nil;

  // Check library handle
  if (hCryptLib <> 0) then
  begin
     // Unload the library
     FreeLibrary(hCryptLib);
     // Clear handle
     hCryptLib:=0;
  end;

end.