#include-once

Global Enum $HOTKEY_FIELD_HOTKEY = 0, _
            $HOTKEY_FIELD_ACTION, _
            $HOTKEY_FIELD_TARGET, _
            $HOTKEY_FIELD_PARAMETERS, _
            $HOTKEY_FIELD_OPTIONS, _
            $HOTKEY_FIELD_CTRL_SIDE, _
            $HOTKEY_FIELD_ALT_SIDE, _
            $HOTKEY_FIELD_SHIFT_SIDE, _
            $HOTKEY_FIELD_WIN_SIDE, _
            $HOTKEY_FIELD_CAPS_LOCK, _
            $HOTKEY_FIELD_NUM_LOCK, _
            $HOTKEY_FIELD_SCROLL_LOCK, _
            $HOTKEY_FIELD_COUNT

Global Const $HOTKEY_ACTION_FILE = "file"
Global Const $HOTKEY_ACTION_FOLDER = "folder"
Global Const $HOTKEY_ACTION_URL = "url"
Global Const $HOTKEY_ACTION_TEXT = "text"
Global Const $HOTKEY_ACTION_WINDOW = "window"
Global Const $HOTKEY_ACTION_COMMAND = "command"
Global Const $HOTKEY_ACTION_SYSTEM = "system"
Global Const $HOTKEY_ACTION_MEDIA = "media"

Global Const $HOTKEY_OPTION_NONE = 0
Global Const $HOTKEY_OPTION_ADMIN = 1
Global Const $HOTKEY_OPTION_SINGLETON = 2
Global Const $HOTKEY_OPTION_ALL = BitOR($HOTKEY_OPTION_ADMIN, $HOTKEY_OPTION_SINGLETON)
Global Const $HOTKEY_SIDE_EITHER = 0, $HOTKEY_SIDE_LEFT = 1, $HOTKEY_SIDE_RIGHT = 2
Global Const $HOTKEY_LOCK_ANY = 0, $HOTKEY_LOCK_ON = 1, $HOTKEY_LOCK_OFF = 2

Func _HotkeyModel_Create($sHotkey, $sAction, $sTarget, $sParameters = "", $iOptions = $HOTKEY_OPTION_NONE)
    Local $aRecord[$HOTKEY_FIELD_COUNT]
    $aRecord[$HOTKEY_FIELD_HOTKEY] = $sHotkey
    $aRecord[$HOTKEY_FIELD_ACTION] = $sAction
    $aRecord[$HOTKEY_FIELD_TARGET] = $sTarget
    $aRecord[$HOTKEY_FIELD_PARAMETERS] = $sParameters
    $aRecord[$HOTKEY_FIELD_OPTIONS] = $iOptions
    Local $i
    For $i = $HOTKEY_FIELD_CTRL_SIDE To $HOTKEY_FIELD_SCROLL_LOCK
        $aRecord[$i] = 0
    Next
    Return $aRecord
EndFunc

Func _HotkeyModel_IsAction($sAction)
    Switch $sAction
        Case $HOTKEY_ACTION_FILE, $HOTKEY_ACTION_FOLDER, $HOTKEY_ACTION_URL, $HOTKEY_ACTION_TEXT, _
             $HOTKEY_ACTION_WINDOW, $HOTKEY_ACTION_COMMAND, $HOTKEY_ACTION_SYSTEM, $HOTKEY_ACTION_MEDIA
            Return True
    EndSwitch
    Return False
EndFunc

Func _HotkeyModel_IsValid(ByRef $aRecord)
    If Not IsArray($aRecord) Or UBound($aRecord) <> $HOTKEY_FIELD_COUNT Then Return SetError(1, 0, False)
    If Not IsString($aRecord[$HOTKEY_FIELD_HOTKEY]) Or $aRecord[$HOTKEY_FIELD_HOTKEY] = "" Then Return SetError(2, 0, False)
    If Not _HotkeyModel_IsAction($aRecord[$HOTKEY_FIELD_ACTION]) Then Return SetError(3, 0, False)
    If Not IsString($aRecord[$HOTKEY_FIELD_TARGET]) Or $aRecord[$HOTKEY_FIELD_TARGET] = "" Then Return SetError(4, 0, False)
    If Not IsString($aRecord[$HOTKEY_FIELD_PARAMETERS]) Then Return SetError(5, 0, False)
    If Not IsInt($aRecord[$HOTKEY_FIELD_OPTIONS]) Then Return SetError(6, 0, False)
    If BitAND($aRecord[$HOTKEY_FIELD_OPTIONS], BitNOT($HOTKEY_OPTION_ALL)) <> 0 Then Return SetError(7, 0, False)
    If $aRecord[$HOTKEY_FIELD_ACTION] <> $HOTKEY_ACTION_FILE And $aRecord[$HOTKEY_FIELD_PARAMETERS] <> "" Then Return SetError(8, 0, False)
    Local $i
    For $i = $HOTKEY_FIELD_CTRL_SIDE To $HOTKEY_FIELD_SCROLL_LOCK
        If Not IsInt($aRecord[$i]) Or $aRecord[$i] < 0 Or $aRecord[$i] > 2 Then Return SetError(9, $i, False)
    Next
    Local $sModifiers = StringRegExpReplace($aRecord[$HOTKEY_FIELD_HOTKEY], "[^\^!+#].*$", "")
    If $aRecord[$HOTKEY_FIELD_CTRL_SIDE] <> $HOTKEY_SIDE_EITHER And Not StringInStr($sModifiers, "^") Then Return SetError(10, $HOTKEY_FIELD_CTRL_SIDE, False)
    If $aRecord[$HOTKEY_FIELD_ALT_SIDE] <> $HOTKEY_SIDE_EITHER And Not StringInStr($sModifiers, "!") Then Return SetError(10, $HOTKEY_FIELD_ALT_SIDE, False)
    If $aRecord[$HOTKEY_FIELD_SHIFT_SIDE] <> $HOTKEY_SIDE_EITHER And Not StringInStr($sModifiers, "+") Then Return SetError(10, $HOTKEY_FIELD_SHIFT_SIDE, False)
    If $aRecord[$HOTKEY_FIELD_WIN_SIDE] <> $HOTKEY_SIDE_EITHER And Not StringInStr($sModifiers, "#") Then Return SetError(10, $HOTKEY_FIELD_WIN_SIDE, False)
    Return True
EndFunc

Func _HotkeyModel_HasRestrictions(ByRef $aRecord)
    Local $i
    For $i = $HOTKEY_FIELD_CTRL_SIDE To $HOTKEY_FIELD_SCROLL_LOCK
        If $aRecord[$i] <> 0 Then Return True
    Next
    Return False
EndFunc

Func _HotkeyModel_ActionLabel($sAction)
    Switch $sAction
        Case $HOTKEY_ACTION_FILE
            Return "File"
        Case $HOTKEY_ACTION_FOLDER
            Return "Folder"
        Case $HOTKEY_ACTION_URL
            Return "URL"
        Case $HOTKEY_ACTION_TEXT
            Return "Text"
        Case $HOTKEY_ACTION_WINDOW
            Return "Window"
        Case $HOTKEY_ACTION_COMMAND
            Return "Advanced Command"
        Case $HOTKEY_ACTION_SYSTEM, $HOTKEY_ACTION_MEDIA
            Return "System"
    EndSwitch
    Return SetError(1, 0, "")
EndFunc

Func _HotkeyModel_ActionFromLabel($sLabel)
    Switch StringLower($sLabel)
        Case "file"
            Return $HOTKEY_ACTION_FILE
        Case "folder"
            Return $HOTKEY_ACTION_FOLDER
        Case "url"
            Return $HOTKEY_ACTION_URL
        Case "text"
            Return $HOTKEY_ACTION_TEXT
        Case "window"
            Return $HOTKEY_ACTION_WINDOW
        Case "command", "advanced command"
            Return $HOTKEY_ACTION_COMMAND
        Case "system"
            Return $HOTKEY_ACTION_SYSTEM
    EndSwitch
    Return SetError(1, 0, "")
EndFunc

Func _HotkeyModel_HasOption(ByRef $aRecord, $iOption)
    Return BitAND($aRecord[$HOTKEY_FIELD_OPTIONS], $iOption) = $iOption
EndFunc
