#include-once

#include <Crypt.au3>
#include <Date.au3>
#include <String.au3>

Global $aTags[13][2]

Func _TextActions_Paste($sText)
    Local $sOldClipboard = ClipGet()
    ClipPut($sText)
    Send("^v")
    ClipPut($sOldClipboard)
EndFunc

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
    Local $sString = ''
    For $i = 1 To $length
        $sString &= $aChars[Random(1, $aChars[0], 1)]
    Next
    Return $sString
EndFunc

Func _Base64Encode($sData)
    Local $oXml = ObjCreate("Msxml2.DOMDocument")
    If Not IsObj($oXml) Then
        SetError(1, 1, 0)
    EndIf

    Local $oElement = $oXml.createElement("b64")
    If Not IsObj($oElement) Then
        SetError(2, 2, 0)
    EndIf

    $oElement.dataType = "bin.base64"
    $oElement.nodeTypedValue = Binary($sData)
    Local $sReturn = $oElement.Text

    If StringLen($sReturn) = 0 Then
        SetError(3, 3, 0)
    EndIf

    Return $sReturn
EndFunc

Func _Base64Decode($sData)
    Local $oXml = ObjCreate("Msxml2.DOMDocument")
    If Not IsObj($oXml) Then
        SetError(1, 1, 0)
    EndIf

    Local $oElement = $oXml.createElement("b64")
    If Not IsObj($oElement) Then
        SetError(2, 2, 0)
    EndIf

    $oElement.dataType = "bin.base64"
    $oElement.Text = $sData
    Local $sReturn = BinaryToString($oElement.nodeTypedValue, 4)

    If StringLen($sReturn) = 0 Then
        SetError(3, 3, 0)
    EndIf

    Return $sReturn
EndFunc

Func uuid()
    Return StringFormat('%04x%04x-%04x-%04x-%04x-%04x%04x%04x', _
            Random(0, 0xffff), Random(0, 0xffff), _
            Random(0, 0xffff), _
            BitOR(Random(0, 0x0fff), 0x4000), _
            BitOR(Random(0, 0x3fff), 0x8000), _
            Random(0, 0xffff), Random(0, 0xffff), Random(0, 0xffff) _
        )
EndFunc
