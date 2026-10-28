#include-once
#include "HotkeyCodec.au3"

; Returns [virtual key, exact modifier mask]. Characters use the current layout.
Func _InputKey_Compile($sHotkey)
    Local $sKey = StringRegExpReplace($sHotkey, "^[\^!+#]+", "")
    Local $sModifiers = StringLeft($sHotkey, StringLen($sHotkey) - StringLen($sKey))
    Local $iMask = 0, $iVk = 0, $aResult
    If StringInStr($sModifiers, "^") Then $iMask = BitOR($iMask, 1)
    If StringInStr($sModifiers, "!") Then $iMask = BitOR($iMask, 2)
    If StringInStr($sModifiers, "+") Then $iMask = BitOR($iMask, 4)
    If StringInStr($sModifiers, "#") Then $iMask = BitOR($iMask, 8)
    If $iMask = 0 Or $sKey = "" Then Return SetError(1, 0, 0)
    If StringUpper($sKey) = "{HKZEQ}" Or $sKey = "{=}" Then $sKey = "="
    If StringLen($sKey) = 1 Then
        $aResult = DllCall("user32.dll", "short", "VkKeyScanW", "ushort", AscW($sKey))
        If @error Or Not IsArray($aResult) Or $aResult[0] = -1 Then Return SetError(2, 0, 0)
        $iVk = BitAND($aResult[0], 0xFF)
    Else
        Local $sName = StringUpper($sKey)
        If StringRegExp($sName, "^\{F([1-9]|1[0-2])\}$") Then
            $iVk = 0x70 + Number(StringTrimRight(StringTrimLeft($sName, 2), 1)) - 1
        ElseIf StringRegExp($sName, "^\{NUMPAD[0-9]\}$") Then
            $iVk = 0x60 + Number(StringTrimRight(StringTrimLeft($sName, 7), 1))
        Else
            Switch $sName
                Case "{SPACE}"
                    $iVk = 0x20
                Case "{BACKSPACE}"
                    $iVk = 0x08
                Case "{ENTER}"
                    $iVk = 0x0D
                Case "{ESCAPE}"
                    $iVk = 0x1B
                Case "{UP}"
                    $iVk = 0x26
                Case "{DOWN}"
                    $iVk = 0x28
                Case "{LEFT}"
                    $iVk = 0x25
                Case "{RIGHT}"
                    $iVk = 0x27
                Case "{PRINTSCREEN}"
                    $iVk = 0x2C
                Case "{PAUSE}"
                    $iVk = 0x13
                Case "{INSERT}"
                    $iVk = 0x2D
                Case "{DELETE}"
                    $iVk = 0x2E
                Case "{HOME}"
                    $iVk = 0x24
                Case "{END}"
                    $iVk = 0x23
                Case "{PGUP}"
                    $iVk = 0x21
                Case "{PGDN}"
                    $iVk = 0x22
                Case "{NUMPADDOT}"
                    $iVk = 0x6E
                Case "{NUMPADDIV}", "{NUMPADDIVIDE}"
                    $iVk = 0x6F
                Case "{NUMPADMULT}", "{NUMPADMULTIPLY}"
                    $iVk = 0x6A
                Case "{NUMPADSUB}", "{NUMPADSUBTRACT}"
                    $iVk = 0x6D
                Case "{NUMPADADD}"
                    $iVk = 0x6B
            EndSwitch
        EndIf
    EndIf
    If $iVk = 0 Then Return SetError(2, 0, 0)
    Local $aKey[2] = [$iVk, $iMask]
    Return $aKey
EndFunc
