#include-once
#include "HotkeyModel.au3"

; Snapshot layout: left/right state for Ctrl, Alt, Shift, Win, then lock toggles.
Global Enum $INPUT_CTRL_LEFT = 0, $INPUT_CTRL_RIGHT, $INPUT_ALT_LEFT, $INPUT_ALT_RIGHT, _
    $INPUT_SHIFT_LEFT, $INPUT_SHIFT_RIGHT, $INPUT_WIN_LEFT, $INPUT_WIN_RIGHT, _
    $INPUT_CAPS, $INPUT_NUM, $INPUT_SCROLL, $INPUT_STATE_COUNT

Func _InputState_Create()
    Local $aState[$INPUT_STATE_COUNT]
    Return $aState
EndFunc

; Call at the input event; GetKeyState's low bit is the toggle, not key-down state.
Func _InputState_ReadLocks(ByRef $aState, $sReader = "_InputState_GetKeyState")
    If Not IsArray($aState) Or UBound($aState) <> $INPUT_STATE_COUNT Then Return SetError(1, 0, False)
    Local $aKeys[3] = [0x14, 0x90, 0x91], $i, $vState
    For $i = 0 To 2
        $vState = Call($sReader, $aKeys[$i])
        If @error Then Return SetError(2, $i, False)
        $aState[$INPUT_CAPS + $i] = BitAND($vState, 1) <> 0
    Next
    Return True
EndFunc

Func _InputState_GetKeyState($iKey)
    Local $aResult = DllCall("user32.dll", "short", "GetKeyState", "int", $iKey)
    If @error Or Not IsArray($aResult) Then Return SetError(1, 0, 0)
    Return $aResult[0]
EndFunc

Func _InputState_Matches(ByRef $aRecord, ByRef $aState)
    If Not _HotkeyModel_IsValid($aRecord) Or Not IsArray($aState) Then Return SetError(1, 0, False)
    If UBound($aState) <> $INPUT_STATE_COUNT Then Return SetError(1, 0, False)
    Local $i, $iSide, $iLock
    For $i = 0 To 3
        $iSide = $aRecord[$HOTKEY_FIELD_CTRL_SIDE + $i]
        If $iSide = $HOTKEY_SIDE_LEFT And Not $aState[$i * 2] Then Return False
        If $iSide = $HOTKEY_SIDE_RIGHT And Not $aState[$i * 2 + 1] Then Return False
    Next
    For $i = 0 To 2
        $iLock = $aRecord[$HOTKEY_FIELD_CAPS_LOCK + $i]
        If $iLock = $HOTKEY_LOCK_ON And Not $aState[$INPUT_CAPS + $i] Then Return False
        If $iLock = $HOTKEY_LOCK_OFF And $aState[$INPUT_CAPS + $i] Then Return False
    Next
    Return True
EndFunc
