#include-once

#include "..\core\HotkeyCodec.au3"
#include "ActionValidator.au3"
#include "TextActions.au3"
#include "..\core\InputState.au3"
#include "ClipboardTransaction.au3"

Global Enum $ACTION_ROUTE_NONE = 0, _
            $ACTION_ROUTE_FILE, _
            $ACTION_ROUTE_FOLDER, _
            $ACTION_ROUTE_URL, _
            $ACTION_ROUTE_TEXT, _
            $ACTION_ROUTE_WINDOW, _
            $ACTION_ROUTE_COMMAND, _
            $ACTION_ROUTE_SYSTEM, _
            $ACTION_ROUTE_MEDIA

Global $g_sActionLockReader = "_InputState_GetKeyState"
Global Const $ACTION_DISPATCH_ERROR_INPUT_STATE = 4
Global Const $ACTION_DISPATCH_ERROR_INVALID = 1
Global Const $ACTION_DISPATCH_ERROR_HANDLER = 2
Global Const $ACTION_DISPATCH_ERROR_TARGET_NOT_FOUND = 3

Func _ActionDispatcher_GetRoute($sAction)
    Switch $sAction
        Case $HOTKEY_ACTION_FILE
            Return $ACTION_ROUTE_FILE
        Case $HOTKEY_ACTION_FOLDER
            Return $ACTION_ROUTE_FOLDER
        Case $HOTKEY_ACTION_URL
            Return $ACTION_ROUTE_URL
        Case $HOTKEY_ACTION_TEXT
            Return $ACTION_ROUTE_TEXT
        Case $HOTKEY_ACTION_WINDOW
            Return $ACTION_ROUTE_WINDOW
        Case $HOTKEY_ACTION_COMMAND
            Return $ACTION_ROUTE_COMMAND
        Case $HOTKEY_ACTION_SYSTEM
            Return $ACTION_ROUTE_SYSTEM
        Case $HOTKEY_ACTION_MEDIA
            Return $ACTION_ROUTE_MEDIA
    EndSwitch
    Return $ACTION_ROUTE_NONE
EndFunc

Func _ActionDispatcher_Prepare(ByRef $aRecord, ByRef $aTags)
    If Not _ActionValidator_ValidateRecord($aRecord, False) Then Return SetError($ACTION_DISPATCH_ERROR_INVALID, @error, 0)
    ; Side-specific input remains unsupported; lock conditions use callback-time state.
    If _HotkeyModel_HasSideRestrictions($aRecord) Then Return SetError($ACTION_DISPATCH_ERROR_INVALID, 0, 0)
    If _HotkeyModel_HasLockConditions($aRecord) Then
        Local $aState = _InputState_Create()
        If Not _InputState_ReadLocks($aState, $g_sActionLockReader) Then Return SetError($ACTION_DISPATCH_ERROR_INPUT_STATE, @extended, 0)
        If Not _InputState_Matches($aRecord, $aState) Then Return SetError(0, 0, False)
    EndIf
    Local $aPrepared = _HotkeyModel_Create( _
        $aRecord[$HOTKEY_FIELD_HOTKEY], _
        $aRecord[$HOTKEY_FIELD_ACTION], _
        _HotkeyCodec_ExpandTags($aRecord[$HOTKEY_FIELD_TARGET], $aTags), _
        _HotkeyCodec_ExpandTags($aRecord[$HOTKEY_FIELD_PARAMETERS], $aTags), _
        $aRecord[$HOTKEY_FIELD_OPTIONS])
    ; Legacy INI values do not store whether a plain path is a file or folder.
    ; A path containing tags may have been classified before it could be expanded.
    If $aPrepared[$HOTKEY_FIELD_ACTION] = $HOTKEY_ACTION_FILE And $aPrepared[$HOTKEY_FIELD_PARAMETERS] = "" Then
        If StringInStr(FileGetAttrib($aPrepared[$HOTKEY_FIELD_TARGET]), "D") Then $aPrepared[$HOTKEY_FIELD_ACTION] = $HOTKEY_ACTION_FOLDER
    EndIf
    ; Only concrete filesystem paths can be checked here. Bare commands such as
    ; code and shell namespaces must still be resolved by ShellExecute.
    If $aPrepared[$HOTKEY_FIELD_ACTION] = $HOTKEY_ACTION_FILE Or $aPrepared[$HOTKEY_FIELD_ACTION] = $HOTKEY_ACTION_FOLDER Then
        If StringRegExp($aPrepared[$HOTKEY_FIELD_TARGET], "(?i)^(?:[A-Z]:\\|\\\\)") And Not FileExists($aPrepared[$HOTKEY_FIELD_TARGET]) Then Return SetError($ACTION_DISPATCH_ERROR_TARGET_NOT_FOUND, 0, 0)
    EndIf
    If Not _ActionValidator_ValidateRecord($aPrepared, True) Then Return SetError($ACTION_DISPATCH_ERROR_INVALID, @error, 0)
    Return $aPrepared
EndFunc

Func _ActionDispatcher_Dispatch(ByRef $aRecord, ByRef $aTags)
    Local $aPrepared = _ActionDispatcher_Prepare($aRecord, $aTags)
    If @error Then Return SetError(@error, @extended, False)
    ; A condition mismatch is a successful no-op, not an action failure.
    If Not IsArray($aPrepared) Then Return True
    Local $sVerb = ""
    If _HotkeyModel_HasOption($aPrepared, $HOTKEY_OPTION_ADMIN) Then $sVerb = "runas"
    Local $bSingleton = _HotkeyModel_HasOption($aPrepared, $HOTKEY_OPTION_SINGLETON)
    Local $vResult
    Switch _ActionDispatcher_GetRoute($aPrepared[$HOTKEY_FIELD_ACTION])
        Case $ACTION_ROUTE_FILE, $ACTION_ROUTE_FOLDER, $ACTION_ROUTE_URL
            $vResult = _ProcessActions_ExecuteTarget($aPrepared[$HOTKEY_FIELD_TARGET], $aPrepared[$HOTKEY_FIELD_PARAMETERS], $sVerb, $bSingleton, $aPrepared[$HOTKEY_FIELD_ACTION] = $HOTKEY_ACTION_FILE)
        Case $ACTION_ROUTE_TEXT
            $vResult = _ClipboardTransaction_Paste($aPrepared[$HOTKEY_FIELD_TARGET])
        Case $ACTION_ROUTE_WINDOW
            $vResult = _WindowActions_Execute($aPrepared[$HOTKEY_FIELD_TARGET])
        Case $ACTION_ROUTE_COMMAND
            $vResult = _ProcessActions_ExecuteCommand($aPrepared[$HOTKEY_FIELD_TARGET], $sVerb)
        Case $ACTION_ROUTE_SYSTEM
            $vResult = _SystemActions_Execute($aPrepared[$HOTKEY_FIELD_TARGET])
        Case $ACTION_ROUTE_MEDIA
            $vResult = _ProcessActions_ExecuteMedia($aPrepared[$HOTKEY_FIELD_TARGET])
        Case Else
            Return SetError($ACTION_DISPATCH_ERROR_INVALID, 0, False)
    EndSwitch
    Local $iHandlerError = @error
    If Not $vResult Then Return SetError($ACTION_DISPATCH_ERROR_HANDLER, $iHandlerError, False)
    Return True
EndFunc
