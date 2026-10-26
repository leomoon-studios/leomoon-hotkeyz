#include-once

#include <Crypt.au3>
#include <Date.au3>
#include <String.au3>

Global $aTags[13][2]

Func _aTags()
    $aTags[0][0] = '<HOUR>'
    $aTags[0][1] = @HOUR
    $aTags[1][0] = '<MINUTE>'
    $aTags[1][1] = @MIN
    $aTags[2][0] = '<SECOND>'
    $aTags[2][1] = @SEC
    $aTags[3][0] = '<YEAR>'
    $aTags[3][1] = @YEAR
    $aTags[4][0] = '<MONTHNAME>'
    $aTags[4][1] = _DateToMonth(@MON, 2)
    $aTags[5][0] = '<MONTHNUMBER>'
    $aTags[5][1] = @MON
    $aTags[6][0] = '<DAYNAME>'
    $aTags[6][1] = _DateDayOfWeek(@WDAY)
    $aTags[7][0] = '<DAYNUMBER>'
    $aTags[7][1] = @MDAY
    $aTags[8][0] = '<COMPUTERNAME>'
    $aTags[8][1] = @ComputerName
    $aTags[9][0] = '<USERNAME>'
    $aTags[9][1] = @UserName
    $aTags[10][0] = '[HkzNL]'
    $aTags[10][1] = @LF
    $aTags[11][0] = '<YYYYMMDD>'
    $aTags[11][1] = @YEAR&@MON&@MDAY
    $aTags[12][0] = '<YYYY-MM-DD>'
    $aTags[12][1] = @YEAR&'-'&@MON&'-'&@MDAY
EndFunc

Func _generator($input)
    Local $length = 20
    Local $i, $aChars
    Switch $input
        Case '<RAND_PPP>'
            $aChars = StringSplit("!#%+23456789:=?@ABCDEFGHJKLMNPRSTUVWXYZabcdefghijkmnopqrstuvwxyz", "")
        Case '<RAND_LETTERS>'
            $aChars = StringSplit("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", "")
        Case '<RAND_LETTERS_NUMBERS>'
            $aChars = StringSplit("23456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", "")
        Case '<RAND_NUMBERS>'
            $aChars = StringSplit("0123456789", "")
    EndSwitch
    If Not IsArray($aChars) Then Return SetError(1, 0, "")
    Local $sString = ''
    For $i = 1 To $length
        Local $iIndex = _TextActions_CryptoIndex($aChars[0])
        If @error Then Return SetError(2, @error, "")
        $sString &= $aChars[$iIndex + 1]
    Next
    Return $sString
EndFunc

Func _TextActions_CryptoIndex($iCount)
    If $iCount < 1 Or $iCount > 256 Then Return SetError(1, 0, 0)
    Local $iLimit = Floor(256 / $iCount) * $iCount
    Local $tByte = DllStructCreate("byte")
    While 1
        If Not _Crypt_GenRandom($tByte, 1) Then Return SetError(2, @error, 0)
        Local $iValue = DllStructGetData($tByte, 1)
        If $iValue < $iLimit Then Return Mod($iValue, $iCount)
    WEnd
EndFunc

Func _Base64Encode($sData)
    If $sData = "" Then Return ""
    Local $oXml = ObjCreate("Msxml2.DOMDocument.6.0")
    If Not IsObj($oXml) Then Return SetError(1, 0, "")

    Local $oElement = $oXml.createElement("b64")
    If Not IsObj($oElement) Then Return SetError(2, 0, "")

    $oElement.dataType = "bin.base64"
    $oElement.nodeTypedValue = StringToBinary($sData, 4)
    Local $sReturn = StringRegExpReplace($oElement.Text, "\s", "")
    If $sReturn = "" Then Return SetError(3, 0, "")
    Return $sReturn
EndFunc

Func _Base64Decode($sData)
    If $sData = "" Then Return ""
    If Mod(StringLen($sData), 4) <> 0 Or Not StringRegExp($sData, "^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$") Then Return SetError(1, 0, "")
    Local $oXml = ObjCreate("Msxml2.DOMDocument.6.0")
    If Not IsObj($oXml) Then Return SetError(2, 0, "")

    Local $oElement = $oXml.createElement("b64")
    If Not IsObj($oElement) Then Return SetError(3, 0, "")

    $oElement.dataType = "bin.base64"
    $oElement.Text = $sData
    Local $sReturn = BinaryToString($oElement.nodeTypedValue, 4)
    Local $iDecodeError = @error
    If $iDecodeError Then Return SetError(4, $iDecodeError, "")
    Local $sCanonical = _Base64Encode($sReturn)
    If @error Or $sCanonical <> $sData Then Return SetError(5, 0, "")
    Return $sReturn
EndFunc

Func uuid()
    Local $tBytes = DllStructCreate("byte[16]")
    If Not _Crypt_GenRandom($tBytes, 16) Then Return SetError(1, @error, "")
    DllStructSetData($tBytes, 1, BitOR(BitAND(DllStructGetData($tBytes, 1, 7), 0x0F), 0x40), 7)
    DllStructSetData($tBytes, 1, BitOR(BitAND(DllStructGetData($tBytes, 1, 9), 0x3F), 0x80), 9)
    Local $sHex = "", $i
    For $i = 1 To 16
        $sHex &= StringFormat("%02x", DllStructGetData($tBytes, 1, $i))
    Next
    Return StringLeft($sHex, 8) & "-" & StringMid($sHex, 9, 4) & "-" & StringMid($sHex, 13, 4) & "-" & StringMid($sHex, 17, 4) & "-" & StringRight($sHex, 12)
EndFunc

Func _TextActions_Transform($sAction, $sText)
    Switch $sAction
        Case "Upper Case Selected Text"
            Return StringUpper($sText)
        Case "Lower Case Selected Text"
            Return StringLower($sText)
        Case "Title Case Selected Text"
            Return _StringTitleCase($sText)
        Case "Reverse Selected Text"
            Return StringReverse($sText)
        Case "MD5 Selected Text"
            Return StringLower(StringTrimLeft(_Crypt_HashData($sText, $CALG_MD5), 2))
        Case "SHA1 Selected Text"
            Return StringLower(StringTrimLeft(_Crypt_HashData($sText, $CALG_SHA1), 2))
        Case "SHA-256 Selected Text"
            Return StringLower(StringTrimLeft(_Crypt_HashData($sText, $CALG_SHA_256), 2))
        Case "SHA-512 Selected Text"
            Return StringLower(StringTrimLeft(_Crypt_HashData($sText, $CALG_SHA_512), 2))
        Case "Base64 Encode Selected Text"
            Return _Base64Encode($sText)
        Case "Base64 Decode Selected Text"
            Return _Base64Decode($sText)
    EndSwitch
    Return SetError(1, 0, "")
EndFunc
