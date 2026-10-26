#include-once

#include "..\core\HotkeyModel.au3"
#include "..\core\HotkeyCodec.au3"
#include "ProcessActions.au3"
#include "SystemActions.au3"
#include "WindowActions.au3"

Global Const $ACTION_VALIDATION_ERROR_MODEL = 1
Global Const $ACTION_VALIDATION_ERROR_HOTKEY = 2
Global Const $ACTION_VALIDATION_ERROR_TARGET = 3
Global Const $ACTION_VALIDATION_ERROR_PARAMETERS = 4
Global Const $ACTION_VALIDATION_ERROR_ACTION = 5

Func _ActionValidator_ValidateRecord(ByRef $aRecord, $bRequireExistingPath = False)
    If Not _HotkeyModel_IsValid($aRecord) Then Return SetError($ACTION_VALIDATION_ERROR_MODEL, @error, False)
    If Not _ActionValidator_IsHotkey($aRecord[$HOTKEY_FIELD_HOTKEY]) Then Return SetError($ACTION_VALIDATION_ERROR_HOTKEY, 0, False)
    If _ActionValidator_ContainsLegacyMarker($aRecord[$HOTKEY_FIELD_TARGET]) Then Return SetError($ACTION_VALIDATION_ERROR_TARGET, 1, False)
    If _ActionValidator_ContainsLegacyMarker($aRecord[$HOTKEY_FIELD_PARAMETERS]) Then Return SetError($ACTION_VALIDATION_ERROR_PARAMETERS, 1, False)
    If StringRegExp($aRecord[$HOTKEY_FIELD_PARAMETERS], "[\r\n]") Then Return SetError($ACTION_VALIDATION_ERROR_PARAMETERS, 2, False)

    Switch $aRecord[$HOTKEY_FIELD_ACTION]
        Case $HOTKEY_ACTION_FILE
            If Not _ActionValidator_IsFileTarget($aRecord[$HOTKEY_FIELD_TARGET], $bRequireExistingPath) Then Return SetError($ACTION_VALIDATION_ERROR_TARGET, 2, False)
        Case $HOTKEY_ACTION_FOLDER
            If Not _ActionValidator_IsFolderTarget($aRecord[$HOTKEY_FIELD_TARGET], $bRequireExistingPath) Then Return SetError($ACTION_VALIDATION_ERROR_TARGET, 3, False)
        Case $HOTKEY_ACTION_URL
            If Not StringRegExp($aRecord[$HOTKEY_FIELD_TARGET], "(?i)^(?:https?|ftp)://[^\s]+$") Then Return SetError($ACTION_VALIDATION_ERROR_TARGET, 4, False)
        Case $HOTKEY_ACTION_TEXT
            If $aRecord[$HOTKEY_FIELD_TARGET] = "" Then Return SetError($ACTION_VALIDATION_ERROR_TARGET, 5, False)
        Case $HOTKEY_ACTION_WINDOW
            If Not _WindowActions_IsValid($aRecord[$HOTKEY_FIELD_TARGET]) Then Return SetError($ACTION_VALIDATION_ERROR_ACTION, 1, False)
        Case $HOTKEY_ACTION_COMMAND
            If StringRegExp($aRecord[$HOTKEY_FIELD_TARGET], "[\r\n]") Then Return SetError($ACTION_VALIDATION_ERROR_TARGET, 6, False)
        Case $HOTKEY_ACTION_SYSTEM
            If _SystemActions_GetId($aRecord[$HOTKEY_FIELD_TARGET]) = $SYSTEM_ACTION_NONE Then Return SetError($ACTION_VALIDATION_ERROR_ACTION, 2, False)
        Case $HOTKEY_ACTION_MEDIA
            If Not _ProcessActions_IsMediaTarget($aRecord[$HOTKEY_FIELD_TARGET]) Then Return SetError($ACTION_VALIDATION_ERROR_ACTION, 3, False)
        Case Else
            Return SetError($ACTION_VALIDATION_ERROR_ACTION, 4, False)
    EndSwitch
    Return True
EndFunc

Func _ActionValidator_IsHotkey($sHotkey)
    If StringRegExp($sHotkey, "[\r\n\s]") Then Return False
    Return StringRegExp($sHotkey, "^[\^!+#]*(?:\{[A-Za-z0-9=]+\}|.)$") = 1
EndFunc

Func _ActionValidator_IsFileTarget($sTarget, $bRequireExistingPath)
    If $sTarget = "" Or StringRegExp($sTarget, '[\r\n\x00"*?|]') Then Return False
    If StringRegExp($sTarget, "(?i)^[A-Z]:[^\\]") Then Return False
    If Not $bRequireExistingPath Then Return True
    _aTags()
    $sTarget = _HotkeyCodec_ExpandTags($sTarget, $aTags)
    If StringRegExp($sTarget, "[<>]") Then Return False
    If Not StringRegExp($sTarget, "(?i)^(?:[A-Z]:\\|\\\\)") Then Return True
    Local $sAttributes = FileGetAttrib($sTarget)
    Return Not @error And Not StringInStr($sAttributes, "D")
EndFunc

Func _ActionValidator_IsFolderTarget($sTarget, $bRequireExistingPath)
    If $sTarget = "" Or StringRegExp($sTarget, '[\r\n\x00"*?|]') Then Return False
    If StringLeft($sTarget, 3) = "::{" Then Return True
    If StringRegExp($sTarget, "(?i)^[A-Z]:[^\\]") Then Return False
    If Not $bRequireExistingPath Then Return True
    _aTags()
    $sTarget = _HotkeyCodec_ExpandTags($sTarget, $aTags)
    If StringRegExp($sTarget, "[<>]") Then Return False
    Return StringInStr(FileGetAttrib($sTarget), "D") > 0
EndFunc

Func _ActionValidator_ContainsLegacyMarker($sValue)
    Return StringRegExp($sValue, "(?i)\[Hkz[A-Za-z]+\]") = 1
EndFunc
