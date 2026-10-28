#include "..\src\core\InputState.au3"
Opt("MustDeclareVars", 1)
Global $g_iFailures = 0, $g_iCount = 0
Global $aState = _InputState_Create(), $aRecord = _HotkeyModel_Create("^!+#a", $HOTKEY_ACTION_TEXT, "test")
_Check(_InputState_Matches($aRecord, $aState), "defaults match")
Global $i, $j
For $i = 0 To 3
    For $j = 1 To 2
        $aRecord[$HOTKEY_FIELD_CTRL_SIDE + $i] = $j
        _Check(Not _InputState_Matches($aRecord, $aState), "required side absent")
        $aState[$i * 2 + $j - 1] = True
        _Check(_InputState_Matches($aRecord, $aState), "required side present")
        $aState[$i * 2 + 2 - $j] = True
        _Check(_InputState_Matches($aRecord, $aState), "both sides held")
        $aState[$i * 2 + $j - 1] = False
        _Check(Not _InputState_Matches($aRecord, $aState), "opposite side alone rejected")
        $aState[$i * 2 + 2 - $j] = False
        $aRecord[$HOTKEY_FIELD_CTRL_SIDE + $i] = 0
    Next
Next
For $i = 0 To 2
    $aRecord[$HOTKEY_FIELD_CAPS_LOCK + $i] = $HOTKEY_LOCK_ON
    _Check(Not _InputState_Matches($aRecord, $aState), "lock on requires on")
    $aState[$INPUT_CAPS + $i] = True
    _Check(_InputState_Matches($aRecord, $aState), "lock on matches")
    $aRecord[$HOTKEY_FIELD_CAPS_LOCK + $i] = $HOTKEY_LOCK_OFF
    _Check(Not _InputState_Matches($aRecord, $aState), "lock off requires off")
    $aState[$INPUT_CAPS + $i] = False
    _Check(_InputState_Matches($aRecord, $aState), "lock off matches")
    $aRecord[$HOTKEY_FIELD_CAPS_LOCK + $i] = 0
Next
$aRecord[$HOTKEY_FIELD_CAPS_LOCK] = $HOTKEY_LOCK_ON
$aRecord[$HOTKEY_FIELD_NUM_LOCK] = $HOTKEY_LOCK_OFF
$aRecord[$HOTKEY_FIELD_SCROLL_LOCK] = $HOTKEY_LOCK_ON
_Check(_InputState_ReadLocks($aState, "_FakeKeyState"), "read toggle bits")
_Check(_InputState_Matches($aRecord, $aState), "conditions use AND and toggle bit")
$aState[$INPUT_NUM] = True
_Check(Not _InputState_Matches($aRecord, $aState), "one mismatch rejects")
If $g_iFailures Then Exit 1
ConsoleWrite("PASSED: " & $g_iCount & " input-state assertions" & @CRLF)
Func _FakeKeyState($iKey)
    If $iKey = 0x90 Then Return 0x8000
    Return 1
EndFunc
Func _Check($bValue, $sMessage)
    $g_iCount += 1
    If Not $bValue Then
        $g_iFailures += 1
        ConsoleWrite("FAIL: " & $sMessage & @CRLF)
    EndIf
EndFunc
