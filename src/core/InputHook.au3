#include-once
#include "InputState.au3"
#include "HotkeyRepository.au3"
#include "InputKey.au3"

; Hook decisions are queued; actions are never executed in the callback.
Global $g_hInputHook = 0, $g_hInputCallback = 0
Global $g_aInputState = _InputState_Create()
Global Const $INPUT_QUEUE_SIZE = 64
Global $g_aInputQueue[$INPUT_QUEUE_SIZE][$INPUT_STATE_COUNT + 3]
Global $g_iInputQueueRead = 0, $g_iInputQueueWrite = 0, $g_iInputQueueDropped = 0
Global $g_aInputRules = _HotkeyRepository_CreateTable(0)
Global $g_aInputRuleKeys[1][2], $g_aInputConsumed[256], $g_aInputForwarded[256]
Global $g_bInputCaptureMatches = False, $g_bInputAcceptInjected = False

; Compile the complete candidate before installing it, preserving the current rules on failure.
Func _InputHook_Configure(ByRef $aRecords, $bAcceptInjected = False)
    If Not _HotkeyRepository_ValidateTable($aRecords) Then Return SetError(1, 0, False)
    Local $iCount = _HotkeyRepository_Count($aRecords), $aKeys[$iCount + 1][2], $i, $aKey
    For $i = 1 To $iCount
        $aKey = _InputKey_Compile($aRecords[$i][$HOTKEY_FIELD_HOTKEY])
        If @error Or Not IsArray($aKey) Then Return SetError(2, $i, False)
        $aKeys[$i][0] = $aKey[0]
        $aKeys[$i][1] = $aKey[1]
    Next
    Return _InputHook_SetRules($aRecords, $aKeys, $bAcceptInjected)
EndFunc
; Rules are precompiled VK and modifier masks (Ctrl=1, Alt=2, Shift=4, Win=8).
; Replacing rules is atomic: invalid input leaves the previous configuration intact.
Func _InputHook_SetRules(ByRef $aRecords, ByRef $aKeys, $bAcceptInjected = False)
    If Not _HotkeyRepository_ValidateTable($aRecords) Or Not IsArray($aKeys) Then Return SetError(1, 0, False)
    Local $iCount = _HotkeyRepository_Count($aRecords), $i, $j
    ; Do not reinterpret queued matches or orphan a consumed key-up after reload.
    If $g_iInputQueueRead <> $g_iInputQueueWrite Then Return SetError(4, 0, False)
    For $i = 0 To 255
        If $g_aInputConsumed[$i] Then Return SetError(4, $i, False)
    Next
    If UBound($aKeys, 0) <> 2 Or UBound($aKeys, 1) <> $iCount + 1 Or UBound($aKeys, 2) <> 2 Then Return SetError(1, 0, False)
    For $i = 1 To $iCount
        If Not IsInt($aKeys[$i][0]) Or $aKeys[$i][0] < 1 Or $aKeys[$i][0] > 255 Or Not IsInt($aKeys[$i][1]) Or $aKeys[$i][1] < 0 Or $aKeys[$i][1] > 15 Then Return SetError(2, $i, False)
        For $j = 1 To $i - 1
            If $aKeys[$i][0] = $aKeys[$j][0] And $aKeys[$i][1] = $aKeys[$j][1] Then Return SetError(3, $i, False)
        Next
    Next
    $g_aInputRules = $aRecords
    $g_aInputRuleKeys = $aKeys
    $g_bInputAcceptInjected = $bAcceptInjected
    $g_bInputCaptureMatches = True
    Return True
EndFunc

Func _InputHook_DisableRules()
    If Not _InputHook_CanUpdate() Then Return SetError(1, @extended, False)
    $g_bInputCaptureMatches = False
    $g_aInputRules = _HotkeyRepository_CreateTable(0)
    Local $aEmpty[1][2]
    $g_aInputRuleKeys = $aEmpty
    Return True
EndFunc

; Defer updates until all captured matches are read and consumed keys are released.
Func _InputHook_CanUpdate()
    If $g_iInputQueueRead <> $g_iInputQueueWrite Then Return SetError(1, 0, False)
    Local $i
    For $i = 0 To 255
        If $g_aInputConsumed[$i] Then Return SetError(2, $i, False)
    Next
    Return True
EndFunc
Func _InputHook_ModifierMask()
    Local $i, $iMask = 0
    For $i = 0 To 3
        If $g_aInputState[$i * 2] Or $g_aInputState[$i * 2 + 1] Then $iMask = BitOR($iMask, 2 ^ $i)
    Next
    Return $iMask
EndFunc

Func _InputHook_Match($iVk)
    Local $i, $aRecord, $iMask = _InputHook_ModifierMask()
    For $i = 1 To _HotkeyRepository_Count($g_aInputRules)
        If $g_aInputRuleKeys[$i][0] <> $iVk Or $g_aInputRuleKeys[$i][1] <> $iMask Then ContinueLoop
        $aRecord = _HotkeyRepository_GetRecord($g_aInputRules, $i)
        If _InputState_Matches($aRecord, $g_aInputState) Then Return $i
    Next
    Return 0
EndFunc

Func _InputHook_Start()
    If $g_hInputHook Then Return True
    Local $aKeys[8] = [0xA2, 0xA3, 0xA4, 0xA5, 0xA0, 0xA1, 0x5B, 0x5C], $i, $aResult
    For $i = 0 To 7
        $aResult = DllCall("user32.dll", "short", "GetAsyncKeyState", "int", $aKeys[$i])
        If @error Or Not IsArray($aResult) Then Return SetError(1, $i, False)
        $g_aInputState[$i] = BitAND($aResult[0], 0x8000) <> 0
    Next
    If Not _InputState_ReadLocks($g_aInputState) Then Return SetError(2, @extended, False)
    $g_iInputQueueRead = 0
    $g_iInputQueueWrite = 0
    $g_iInputQueueDropped = 0
    For $i = 0 To 255
        $g_aInputConsumed[$i] = False
        $g_aInputForwarded[$i] = False
    Next
    $g_hInputCallback = DllCallbackRegister("_InputHook_Callback", "lresult", "int;wparam;lparam")
    If @error Or Not $g_hInputCallback Then Return SetError(3, 0, False)
    $aResult = DllCall("user32.dll", "handle", "SetWindowsHookExW", "int", 13, "ptr", DllCallbackGetPtr($g_hInputCallback), "handle", 0, "dword", 0)
    If @error Or Not IsArray($aResult) Or Not $aResult[0] Then
        DllCallbackFree($g_hInputCallback)
        $g_hInputCallback = 0
        Return SetError(4, 0, False)
    EndIf
    $g_hInputHook = $aResult[0]
    Return True
EndFunc

Func _InputHook_Stop($bForce = False)
    If Not $bForce And Not _InputHook_CanUpdate() Then Return SetError(2, @extended, False)
    If $g_hInputHook Then
        Local $aResult = DllCall("user32.dll", "bool", "UnhookWindowsHookEx", "handle", $g_hInputHook)
        If @error Or Not IsArray($aResult) Or Not $aResult[0] Then Return SetError(1, 0, False)
        $g_hInputHook = 0
    EndIf
    If $g_hInputCallback Then DllCallbackFree($g_hInputCallback)
    $g_hInputCallback = 0
    $g_iInputQueueRead = 0
    $g_iInputQueueWrite = 0
    Return True
EndFunc

; Returns VK, injected flag and the captured snapshot, or @error when empty.
Func _InputHook_Read()
    If $g_iInputQueueRead = $g_iInputQueueWrite Then Return SetError(1, 0, 0)
    Local $aEvent[$INPUT_STATE_COUNT + 3], $i
    For $i = 0 To $INPUT_STATE_COUNT + 2
        $aEvent[$i] = $g_aInputQueue[$g_iInputQueueRead][$i]
    Next
    $g_iInputQueueRead = Mod($g_iInputQueueRead + 1, $INPUT_QUEUE_SIZE)
    Return $aEvent
EndFunc

; Resolve the queued rule while updates are still blocked. The returned record is
; a copy, so a subsequent rules update cannot change the pending action.
Func _InputHook_ReadMatch(ByRef $aRecord, ByRef $aSnapshot)
    Local $aEvent = _InputHook_Read()
    If @error Or Not IsArray($aEvent) Then Return SetError(1, 0, False)
    Local $iRule = $aEvent[$INPUT_STATE_COUNT + 2], $i
    If $iRule < 1 Or $iRule > _HotkeyRepository_Count($g_aInputRules) Then Return SetError(2, $iRule, False)
    $aRecord = _HotkeyRepository_GetRecord($g_aInputRules, $iRule)
    $aSnapshot = _InputState_Create()
    For $i = 0 To $INPUT_STATE_COUNT - 1
        $aSnapshot[$i] = $aEvent[$i + 2]
    Next
    Return True
EndFunc
Func _InputHook_Callback($iCode, $wParam, $lParam)
    If $iCode >= 0 Then
        Local $tEvent = DllStructCreate("dword vk;dword scan;dword flags;dword time;ulong_ptr extra", $lParam)
        Local $iVk = DllStructGetData($tEvent, "vk")
        Local $bDown = ($wParam = 0x0100 Or $wParam = 0x0104)
        Local $bUp = ($wParam = 0x0101 Or $wParam = 0x0105)
        Local $iSide = -1
        Switch $iVk
            Case 0xA2
                $iSide = $INPUT_CTRL_LEFT
            Case 0xA3
                $iSide = $INPUT_CTRL_RIGHT
            Case 0xA4
                $iSide = $INPUT_ALT_LEFT
            Case 0xA5
                $iSide = $INPUT_ALT_RIGHT
            Case 0xA0
                $iSide = $INPUT_SHIFT_LEFT
            Case 0xA1
                $iSide = $INPUT_SHIFT_RIGHT
            Case 0x5B
                $iSide = $INPUT_WIN_LEFT
            Case 0x5C
                $iSide = $INPUT_WIN_RIGHT
        EndSwitch
        If $iSide >= 0 And ($bDown Or $bUp) Then $g_aInputState[$iSide] = $bDown
        If $iSide < 0 And $iVk >= 0 And $iVk < 256 And $g_aInputForwarded[$iVk] Then
            If $bUp Then $g_aInputForwarded[$iVk] = False
            Return _InputHook_Forward($iCode, $wParam, $lParam)
        EndIf
        If $iSide < 0 And $iVk >= 0 And $iVk < 256 And $bUp And $g_aInputConsumed[$iVk] Then
            $g_aInputConsumed[$iVk] = False
            Return 1
        EndIf
        If $iSide < 0 And $iVk >= 0 And $iVk < 256 And $bDown And $g_aInputConsumed[$iVk] Then Return 1
        If $iSide < 0 And $bDown And _InputState_ReadLocks($g_aInputState) Then
            Local $bInjected = BitAND(DllStructGetData($tEvent, "flags"), 0x10) <> 0
            Local $iMatched = 0
            If $g_bInputCaptureMatches Then
                If Not $bInjected Or $g_bInputAcceptInjected Then $iMatched = _InputHook_Match($iVk)
                If Not $iMatched Then
                    If $iVk < 256 Then $g_aInputForwarded[$iVk] = True
                    Return _InputHook_Forward($iCode, $wParam, $lParam)
                EndIf
            EndIf
            Local $iNext = Mod($g_iInputQueueWrite + 1, $INPUT_QUEUE_SIZE)
            If $iNext <> $g_iInputQueueRead Then
                $g_aInputQueue[$g_iInputQueueWrite][0] = $iVk
                $g_aInputQueue[$g_iInputQueueWrite][1] = BitAND(DllStructGetData($tEvent, "flags"), 0x10) <> 0
                Local $i
                For $i = 0 To $INPUT_STATE_COUNT - 1
                    $g_aInputQueue[$g_iInputQueueWrite][$i + 2] = $g_aInputState[$i]
                Next
                $g_aInputQueue[$g_iInputQueueWrite][$INPUT_STATE_COUNT + 2] = $iMatched
                $g_iInputQueueWrite = $iNext
                If $iMatched And $iVk < 256 Then
                    $g_aInputConsumed[$iVk] = True
                    Return 1
                EndIf
            Else
                $g_iInputQueueDropped += 1
                If $g_bInputCaptureMatches And $iVk < 256 Then $g_aInputForwarded[$iVk] = True
            EndIf
        EndIf
    EndIf
    Return _InputHook_Forward($iCode, $wParam, $lParam)
EndFunc

Func _InputHook_Forward($iCode, $wParam, $lParam)
    Local $aNext = DllCall("user32.dll", "lresult", "CallNextHookEx", "handle", $g_hInputHook, "int", $iCode, "wparam", $wParam, "lparam", $lParam)
    If @error Or Not IsArray($aNext) Then Return 0
    Return $aNext[0]
EndFunc
