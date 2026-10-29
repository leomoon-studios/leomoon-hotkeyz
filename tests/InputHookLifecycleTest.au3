#include "..\src\core\InputHook.au3"
Opt("MustDeclareVars", 1)
Global $g_iChecks = 0, $g_iFailures = 0
Global $aRules = _HotkeyRepository_CreateTable(1), $aRecord = _HotkeyModel_Create("^{F9}", $HOTKEY_ACTION_TEXT, "example")
$aRecord[$HOTKEY_FIELD_CTRL_SIDE] = $HOTKEY_SIDE_LEFT
_Check(_HotkeyRepository_SetRecord($aRules, 1, $aRecord), "create rule")
_Check(_InputHook_Configure($aRules), "configure rule")
Global $aBad = _HotkeyRepository_CreateTable(1)
$aRecord[$HOTKEY_FIELD_HOTKEY] = "^{UNKNOWN}"
_Check(_HotkeyRepository_SetRecord($aBad, 1, $aRecord), "create unsupported rule")
_Check(Not _InputHook_Configure($aBad), "reject unsupported key")
_Check($g_aInputRuleKeys[1][0] = 0x78, "failed update preserves existing rule")
$g_iInputQueueWrite = 1
_Check(Not _InputHook_Configure($aRules), "pending event prevents update")
_Check(Not _InputHook_DisableRules(), "pending event prevents disable")
_Check(Not _InputHook_Stop(), "pending event prevents stop")
_Check($g_bInputCaptureMatches, "failed disable preserves rules")
$g_aInputQueue[0][0] = 0x78
$g_aInputQueue[0][$INPUT_CTRL_LEFT + 2] = True
$g_aInputQueue[0][$INPUT_STATE_COUNT + 2] = 1
Global $aCapturedRecord, $aCapturedState
_Check(_InputHook_ReadMatch($aCapturedRecord, $aCapturedState), "read queued match")
_Check($aCapturedRecord[$HOTKEY_FIELD_TARGET] = "example" And $aCapturedState[$INPUT_CTRL_LEFT], "queued action and snapshot retained")
$aRecord[$HOTKEY_FIELD_HOTKEY] = "^{F10}"
$aRecord[$HOTKEY_FIELD_TARGET] = "changed"
_Check(_HotkeyRepository_SetRecord($aRules, 1, $aRecord), "prepare replacement")
_Check(_InputHook_Configure($aRules), "update after queue drained")
_Check($aCapturedRecord[$HOTKEY_FIELD_TARGET] = "example", "drained match retains original action after reload")
$g_aInputConsumed[0x78] = True
_Check(Not _InputHook_Configure($aRules), "held consumed key prevents update")
_Check(Not _InputHook_DisableRules(), "held consumed key prevents disable")
_Check(Not _InputHook_Stop(), "held consumed key prevents stop")
$g_aInputConsumed[0x78] = False
; A full queue forwards the whole key sequence, including repeats and key-up.
$g_aInputState[$INPUT_CTRL_LEFT] = True
$g_iInputQueueRead = 0
$g_iInputQueueWrite = $INPUT_QUEUE_SIZE - 1
Global $tEvent = DllStructCreate("dword vk;dword scan;dword flags;dword time;ulong_ptr extra")
DllStructSetData($tEvent, "vk", 0x79)
_InputHook_Callback(0, 0x0100, DllStructGetPtr($tEvent))
_Check($g_aInputForwarded[0x79] And Not $g_aInputConsumed[0x79], "overflow forwards key-down")
$g_iInputQueueRead = $g_iInputQueueWrite
_InputHook_Callback(0, 0x0100, DllStructGetPtr($tEvent))
_Check(Not $g_aInputConsumed[0x79] And $g_iInputQueueRead = $g_iInputQueueWrite, "repeat remains forwarded after overflow")
_InputHook_Callback(0, 0x0101, DllStructGetPtr($tEvent))
_Check(Not $g_aInputForwarded[0x79], "forwarded key-up clears state")
_Check(_InputHook_DisableRules(), "disable after drain and release")
_Check(_InputHook_Stop(), "stop after drain and release")
If $g_iFailures Then Exit 1
ConsoleWrite("PASSED: " & $g_iChecks & " hook lifecycle assertions" & @CRLF)
Func _Check($bValue, $sMessage)
    $g_iChecks += 1
    If Not $bValue Then
        $g_iFailures += 1
        ConsoleWrite("FAIL: " & $sMessage & @CRLF)
    EndIf
EndFunc
