#include-once

#include "..\actions\ActionValidator.au3"
#include "..\core\ActionCatalog.au3"
#include "..\core\HotkeyRepository.au3"

Global Enum $EDITOR_VALUE_HOTKEY = 0, _
            $EDITOR_VALUE_ACTION, _
            $EDITOR_VALUE_TARGET, _
            $EDITOR_VALUE_PARAMETERS, _
            $EDITOR_VALUE_OPTIONS, _
            $EDITOR_VALUE_MOVE_ENABLED, _
            $EDITOR_VALUE_MOVE_X, _
            $EDITOR_VALUE_MOVE_Y, _
            $EDITOR_VALUE_RESIZE_ENABLED, _
            $EDITOR_VALUE_RESIZE_WIDTH, _
            $EDITOR_VALUE_RESIZE_HEIGHT, _
            $EDITOR_VALUE_CTRL_SIDE, _
            $EDITOR_VALUE_ALT_SIDE, _
            $EDITOR_VALUE_SHIFT_SIDE, _
            $EDITOR_VALUE_WIN_SIDE, _
            $EDITOR_VALUE_CAPS_LOCK, _
            $EDITOR_VALUE_NUM_LOCK, _
            $EDITOR_VALUE_SCROLL_LOCK, _
            $EDITOR_VALUE_COUNT

Global Const $EDITOR_MODEL_ERROR_INPUT = 1
Global Const $EDITOR_MODEL_ERROR_HOTKEY = 2
Global Const $EDITOR_MODEL_ERROR_NUMBER = 3
Global Const $EDITOR_MODEL_ERROR_RECORD = 4
Global Const $EDITOR_MODEL_ERROR_DUPLICATE = 5
Global Const $EDITOR_MODEL_ERROR_OPTICAL = 6

Func _HotkeyEditorModel_CreateValues($sHotkey, $sAction, $sTarget, $sParameters = "", $iOptions = $HOTKEY_OPTION_NONE, $bMove = False, $sX = "", $sY = "", $bResize = False, $sWidth = "", $sHeight = "")
    Local $aValues[$EDITOR_VALUE_COUNT] = [$sHotkey, $sAction, $sTarget, $sParameters, $iOptions, $bMove, $sX, $sY, $bResize, $sWidth, $sHeight, 0, 0, 0, 0, 0, 0, 0]
    Return $aValues
EndFunc

Func _HotkeyEditorModel_ToRecord(ByRef $aValues, $bRequireExistingPath = False)
    If Not IsArray($aValues) Or UBound($aValues) <> $EDITOR_VALUE_COUNT Then Return SetError($EDITOR_MODEL_ERROR_INPUT, 0, 0)
    Local $sHotkey = _HotkeyCodec_NormalizeHotkey($aValues[$EDITOR_VALUE_HOTKEY])
    If Not _HotkeyEditorModel_IsModifiedHotkey($sHotkey) Then Return SetError($EDITOR_MODEL_ERROR_HOTKEY, 0, 0)
    Local $sTarget = $aValues[$EDITOR_VALUE_TARGET]
    If $aValues[$EDITOR_VALUE_ACTION] = $HOTKEY_ACTION_WINDOW And $sTarget = $ACTION_CATALOG_CUSTOM_WINDOW Then
        $sTarget = _HotkeyEditorModel_BuildGeometry($aValues[$EDITOR_VALUE_MOVE_ENABLED], $aValues[$EDITOR_VALUE_MOVE_X], $aValues[$EDITOR_VALUE_MOVE_Y], $aValues[$EDITOR_VALUE_RESIZE_ENABLED], $aValues[$EDITOR_VALUE_RESIZE_WIDTH], $aValues[$EDITOR_VALUE_RESIZE_HEIGHT])
        If @error Then Return SetError($EDITOR_MODEL_ERROR_NUMBER, @error, 0)
    EndIf
    Local $aRecord = _HotkeyModel_Create($sHotkey, $aValues[$EDITOR_VALUE_ACTION], $sTarget, $aValues[$EDITOR_VALUE_PARAMETERS], $aValues[$EDITOR_VALUE_OPTIONS])
    Local $i
    For $i = 0 To 6
        $aRecord[$HOTKEY_FIELD_CTRL_SIDE + $i] = $aValues[$EDITOR_VALUE_CTRL_SIDE + $i]
    Next
    If Not _ActionValidator_ValidateRecord($aRecord, $bRequireExistingPath) Then Return SetError($EDITOR_MODEL_ERROR_RECORD, @error, 0)
    Return $aRecord
EndFunc

Func _HotkeyEditorModel_BuildGeometry($bMove, $sX, $sY, $bResize, $sWidth, $sHeight)
    If Not $bMove And Not $bResize Then Return SetError(1, 0, "")
    Local $sAction = ""
    If $bMove Then
        If Not StringRegExp($sX, "^-?\d+$") Or Not StringRegExp($sY, "^-?\d+$") Then Return SetError(2, 0, "")
        $sAction = "Move to " & Number($sX) & "," & Number($sY)
    EndIf
    If $bResize Then
        If Not StringRegExp($sWidth, "^[1-9]\d*$") Or Not StringRegExp($sHeight, "^[1-9]\d*$") Then Return SetError(3, 0, "")
        If $sAction <> "" Then $sAction &= " & "
        $sAction &= "Resize to " & Number($sWidth) & "x" & Number($sHeight)
    EndIf
    Return $sAction
EndFunc

Func _HotkeyEditorModel_IsModifiedHotkey($sHotkey)
    If Not _ActionValidator_IsHotkey($sHotkey) Then Return False
    If StringRegExp($sHotkey, "^[\^!+#]+") <> 1 Then Return False
    Return StringRegExpReplace($sHotkey, "^[\^!+#]+", "") <> ""
EndFunc

Func _HotkeyEditorModel_FindDuplicate(ByRef $aRecords, $sHotkey, $iExcludeRow = 0)
    If Not IsArray($aRecords) Then Return SetError($EDITOR_MODEL_ERROR_INPUT, 0, 0)
    Local $sNormalized = _HotkeyCodec_NormalizeHotkey($sHotkey)
    Local $i
    For $i = 1 To _HotkeyRepository_Count($aRecords)
        If $i <> $iExcludeRow And $sNormalized = _HotkeyCodec_NormalizeHotkey($aRecords[$i][$HOTKEY_FIELD_HOTKEY]) Then Return $i
    Next
    Return 0
EndFunc

Func _HotkeyEditorModel_ValidateToggle($sToggleHotkey, ByRef $aRecords)
    Local $sNormalized = _HotkeyCodec_NormalizeHotkey($sToggleHotkey)
    If Not _HotkeyEditorModel_IsModifiedHotkey($sNormalized) Then Return SetError($EDITOR_MODEL_ERROR_HOTKEY, 0, False)
    If _HotkeyEditorModel_FindDuplicate($aRecords, $sNormalized) Then Return SetError($EDITOR_MODEL_ERROR_DUPLICATE, @error, False)
    Return True
EndFunc

Func _HotkeyEditorModel_Upsert(ByRef $aRecords, ByRef $aRecord, $iRow = 0)
    If Not _HotkeyRepository_ValidateTable($aRecords) Or Not _ActionValidator_ValidateRecord($aRecord, False) Then Return SetError($EDITOR_MODEL_ERROR_RECORD, 0, 0)
    Local $iCount = _HotkeyRepository_Count($aRecords)
    If $iRow < 0 Or $iRow > $iCount Then Return SetError($EDITOR_MODEL_ERROR_INPUT, 0, 0)
    If _HotkeyEditorModel_FindDuplicate($aRecords, $aRecord[$HOTKEY_FIELD_HOTKEY], $iRow) Then Return SetError($EDITOR_MODEL_ERROR_DUPLICATE, @error, 0)
    Local $iUpdatedCount = $iCount
    If $iRow = 0 Then $iUpdatedCount += 1
    Local $aUpdated = _HotkeyRepository_CreateTable($iUpdatedCount)
    Local $i, $aExisting
    For $i = 1 To $iCount
        $aExisting = _HotkeyRepository_GetRecord($aRecords, $i)
        _HotkeyRepository_SetRecord($aUpdated, $i, $aExisting)
    Next
    If $iRow = 0 Then $iRow = $iCount + 1
    _HotkeyRepository_SetRecord($aUpdated, $iRow, $aRecord)
    Return $aUpdated
EndFunc

Func _HotkeyEditorModel_Delete(ByRef $aRecords, $iRow)
    If Not _HotkeyRepository_ValidateTable($aRecords) Then Return SetError($EDITOR_MODEL_ERROR_INPUT, 0, 0)
    Local $iCount = _HotkeyRepository_Count($aRecords)
    If $iRow < 1 Or $iRow > $iCount Then Return SetError($EDITOR_MODEL_ERROR_INPUT, 0, 0)
    Local $aUpdated = _HotkeyRepository_CreateTable($iCount - 1)
    Local $i, $iTarget = 1, $aExisting
    For $i = 1 To $iCount
        If $i = $iRow Then ContinueLoop
        $aExisting = _HotkeyRepository_GetRecord($aRecords, $i)
        _HotkeyRepository_SetRecord($aUpdated, $iTarget, $aExisting)
        $iTarget += 1
    Next
    Local $iSelection = $iRow
    If $iSelection > $iCount - 1 Then $iSelection = $iCount - 1
    Return SetExtended($iSelection, $aUpdated)
EndFunc

Func _HotkeyEditorModel_Cancel(ByRef $aRecords)
    If Not _HotkeyRepository_ValidateTable($aRecords) Then Return SetError($EDITOR_MODEL_ERROR_INPUT, 0, 0)
    Local $aUnchanged = _HotkeyRepository_CreateTable(_HotkeyRepository_Count($aRecords))
    Local $i, $aRecord
    For $i = 1 To _HotkeyRepository_Count($aRecords)
        $aRecord = _HotkeyRepository_GetRecord($aRecords, $i)
        _HotkeyRepository_SetRecord($aUnchanged, $i, $aRecord)
    Next
    Return $aUnchanged
EndFunc

Func _HotkeyEditorModel_StartupEnabled($iCheckboxState)
    Return BitAND($iCheckboxState, 1) = 1
EndFunc

Func _HotkeyEditorModel_ShouldCloseSettings($bSaveSucceeded, $bStartupSucceeded)
    Return $bSaveSucceeded And $bStartupSucceeded
EndFunc
