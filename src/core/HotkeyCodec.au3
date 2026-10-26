#include-once

#include <String.au3>
#include "HotkeyModel.au3"

Global Const $HOTKEY_CODEC_EQUAL = "[HkzEq]"
Global Const $HOTKEY_CODEC_PARAMETER = "[HkzParam]"
Global Const $HOTKEY_CODEC_NEWLINE = "[HkzNL]"
Global Const $HOTKEY_CODEC_OPTION_ADMIN = "[HkzOptAdmin]"
Global Const $HOTKEY_CODEC_OPTION_SINGLETON = "[HkzOptOne]"
Global Const $HOTKEY_CODEC_KEY_NAMES = "`|1|2|3|4|5|6|7|8|9|0|-|=|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|[|]|\|;|'|,|.|/|Space|Backspace|Enter|Up|Down|Left|Right|Escape|F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|Print Screen key|Pause key|Insert|Delete|Home|End|Page Up|Page Down|Numpad 1|Numpad 2|Numpad 3|Numpad 4|Numpad 5|Numpad 6|Numpad 7|Numpad 8|Numpad 9|Numpad 0|Numpad Dot|Numpad Divide|Numpad Multiply|Numpad Subtract|Numpad Add"

Func _HotkeyCodec_EncodeKey($sKey)
    If StringLen($sKey) > 1 Then
        If $sKey = "Escape" Then $sKey = "ESCAPE"
        If $sKey = "Print Screen key" Then $sKey = "PRINTSCREEN"
        If $sKey = "Pause key" Then $sKey = "PAUSE"
        If $sKey = "Page Up" Then $sKey = "PGUP"
        If $sKey = "Page Down" Then $sKey = "PGDN"
        If StringLeft($sKey, 7) = "Numpad " Then $sKey = "NUMPAD" & StringReplace(StringTrimLeft($sKey, 7), " ", "")
        If $sKey = "NUMPADDIVIDE" Then $sKey = "NUMPADDIV"
        $sKey = "{" & StringUpper($sKey) & "}"
    ElseIf $sKey = "=" Then
        $sKey = "{HkzEq}"
    Else
        $sKey = StringLower($sKey)
    EndIf
    Return $sKey
EndFunc

Func _HotkeyCodec_DecodeKey($sKey)
    If StringLen($sKey) = 1 Then Return StringUpper($sKey)
    Switch StringUpper($sKey)
        Case "{ESCAPE}"
            Return "Escape"
        Case "{PRINTSCREEN}"
            Return "Print Screen key"
        Case "{PAUSE}"
            Return "Pause key"
        Case "{PGUP}"
            Return "Page Up"
        Case "{PGDN}"
            Return "Page Down"
        Case "{HKZEQ}", "{=}"
            Return "="
    EndSwitch
    If StringLeft(StringUpper($sKey), 7) = "{NUMPAD" Then
        Local $sNumpadKey = StringTrimRight(StringTrimLeft(StringUpper($sKey), 7), 1)
        Switch $sNumpadKey
            Case "DIV"
                $sNumpadKey = "Divide"
            Case "MULT"
                $sNumpadKey = "Multiply"
            Case "SUB"
                $sNumpadKey = "Subtract"
            Case "ADD"
                $sNumpadKey = "Add"
            Case "DOT"
                $sNumpadKey = "Dot"
        EndSwitch
        Return "Numpad " & $sNumpadKey
    EndIf
    Return _StringTitleCase(StringReplace(StringReplace($sKey, "{", ""), "}", ""))
EndFunc

Func _HotkeyCodec_DecodeHotkey($sHotkey)
    Local $sDecoded = ""
    If StringInStr($sHotkey, "^") Then $sDecoded &= "Ctrl + "
    If StringInStr($sHotkey, "!") Then $sDecoded &= "Alt + "
    If StringInStr($sHotkey, "+") Then $sDecoded &= "Shift + "
    If StringInStr($sHotkey, "#") Then $sDecoded &= "Win + "
    Local $sKey = StringReplace(StringReplace(StringReplace(StringReplace($sHotkey, "^", ""), "!", ""), "+", ""), "#", "")
    Return $sDecoded & _HotkeyCodec_DecodeKey($sKey)
EndFunc

Func _HotkeyCodec_EncodeHotkey($sHotkey)
    Local $sEncoded = ""
    If StringInStr($sHotkey, "Ctrl + ") Then $sEncoded &= "^"
    If StringInStr($sHotkey, "Alt + ") Then $sEncoded &= "!"
    If StringInStr($sHotkey, "Shift + ") Then $sEncoded &= "+"
    If StringInStr($sHotkey, "Win + ") Then $sEncoded &= "#"
    Local $sKey = StringReplace(StringReplace(StringReplace(StringReplace($sHotkey, "Ctrl + ", ""), "Alt + ", ""), "Shift + ", ""), "Win + ", "")
    Return $sEncoded & _HotkeyCodec_EncodeKey($sKey)
EndFunc

Func _HotkeyCodec_NormalizeHotkey($sHotkey)
    Return StringLower(_HotkeyCodec_EncodeHotkey(_HotkeyCodec_DecodeHotkey($sHotkey)))
EndFunc

Func _HotkeyCodec_DecodeLegacy($sHotkey, $sValue, $sPlainAction = $HOTKEY_ACTION_FILE)
    Local $iOptions = $HOTKEY_OPTION_NONE
    If StringInStr($sValue, $HOTKEY_CODEC_OPTION_ADMIN) Then
        $iOptions = BitOR($iOptions, $HOTKEY_OPTION_ADMIN)
        $sValue = StringReplace($sValue, $HOTKEY_CODEC_OPTION_ADMIN, "")
    EndIf
    If StringInStr($sValue, $HOTKEY_CODEC_OPTION_SINGLETON) Then
        $iOptions = BitOR($iOptions, $HOTKEY_OPTION_SINGLETON)
        $sValue = StringReplace($sValue, $HOTKEY_CODEC_OPTION_SINGLETON, "")
    EndIf

    Local $sAction = $sPlainAction
    If StringLeft($sValue, 11) = "[HkzSndTxt]" Then
        $sAction = $HOTKEY_ACTION_TEXT
        $sValue = StringTrimLeft($sValue, 11)
    ElseIf StringLeft($sValue, 7) = "[HkzWM]" Then
        $sAction = $HOTKEY_ACTION_WINDOW
        $sValue = StringTrimLeft($sValue, 7)
    ElseIf StringLeft($sValue, 8) = "[HkzCmd]" Then
        $sAction = $HOTKEY_ACTION_COMMAND
        $sValue = StringTrimLeft($sValue, 8)
    ElseIf StringLeft($sValue, 11) = "[HkzSysSnd]" Then
        $sAction = $HOTKEY_ACTION_MEDIA
        $sValue = StringTrimLeft($sValue, 11)
    ElseIf StringLeft($sValue, 8) = "[HkzExe]" Then
        $sAction = $HOTKEY_ACTION_SYSTEM
        $sValue = StringTrimLeft($sValue, 8)
    EndIf
    If StringLeft($sValue, 4) = "[Hkz" Then Return SetError(3, 0, 0)

    Local $sParameters = ""
    If $sAction = $HOTKEY_ACTION_FILE And StringInStr($sValue, $HOTKEY_CODEC_PARAMETER) Then
        Local $aParts = StringSplit($sValue, $HOTKEY_CODEC_PARAMETER, 1)
        If Not IsArray($aParts) Or $aParts[0] <> 2 Then Return SetError(1, 0, 0)
        $sValue = $aParts[1]
        $sParameters = $aParts[2]
    EndIf

    $sValue = StringReplace($sValue, $HOTKEY_CODEC_EQUAL, "=")
    $sParameters = StringReplace($sParameters, $HOTKEY_CODEC_EQUAL, "=")
    If $sAction = $HOTKEY_ACTION_TEXT Then $sValue = StringReplace($sValue, $HOTKEY_CODEC_NEWLINE, @LF)

    Local $aRecord = _HotkeyModel_Create(StringReplace($sHotkey, "{HkzEq}", "{=}"), $sAction, $sValue, $sParameters, $iOptions)
    If Not _HotkeyModel_IsValid($aRecord) Then Return SetError(2, @error, 0)
    Return $aRecord
EndFunc

Func _HotkeyCodec_EncodeLegacy(ByRef $aRecord)
    If Not _HotkeyModel_IsValid($aRecord) Then Return SetError(1, @error, "")
    Local $sValue = $aRecord[$HOTKEY_FIELD_TARGET]
    Switch $aRecord[$HOTKEY_FIELD_ACTION]
        Case $HOTKEY_ACTION_TEXT
            $sValue = "[HkzSndTxt]" & StringReplace(StringReplace($sValue, @CRLF, $HOTKEY_CODEC_NEWLINE), @LF, $HOTKEY_CODEC_NEWLINE)
        Case $HOTKEY_ACTION_WINDOW
            $sValue = "[HkzWM]" & $sValue
        Case $HOTKEY_ACTION_COMMAND
            $sValue = "[HkzCmd]" & $sValue
        Case $HOTKEY_ACTION_MEDIA
            $sValue = "[HkzSysSnd]" & $sValue
        Case $HOTKEY_ACTION_SYSTEM
            $sValue = "[HkzExe]" & $sValue
        Case $HOTKEY_ACTION_FILE
            If $aRecord[$HOTKEY_FIELD_PARAMETERS] <> "" Then $sValue &= $HOTKEY_CODEC_PARAMETER & $aRecord[$HOTKEY_FIELD_PARAMETERS]
    EndSwitch
    $sValue = StringReplace($sValue, "=", $HOTKEY_CODEC_EQUAL)
    If _HotkeyModel_HasOption($aRecord, $HOTKEY_OPTION_ADMIN) Then $sValue &= $HOTKEY_CODEC_OPTION_ADMIN
    If _HotkeyModel_HasOption($aRecord, $HOTKEY_OPTION_SINGLETON) Then $sValue &= $HOTKEY_CODEC_OPTION_SINGLETON
    Return $sValue
EndFunc

Func _HotkeyCodec_EncodeIniKey(ByRef $aRecord)
    Return StringReplace($aRecord[$HOTKEY_FIELD_HOTKEY], "{=}", "{HkzEq}")
EndFunc

Func _HotkeyCodec_ExpandTags($sValue, ByRef $aTags)
    If Not IsArray($aTags) Or UBound($aTags, 2) <> 2 Then Return SetError(1, 0, "")
    Local $i
    For $i = 0 To UBound($aTags, 1) - 1
        $sValue = StringReplace($sValue, $aTags[$i][0], $aTags[$i][1])
    Next
    Return $sValue
EndFunc
