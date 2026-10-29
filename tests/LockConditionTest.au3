#include "..\src\core\AppConstants.au3"
#include "..\src\app\HotkeyRegistry.au3"
#include "..\src\actions\ProcessActions.au3"
Opt("MustDeclareVars", 1)
Global $g_iCalls = 0, $g_iReads = 0, $g_bReadFailure = False, $g_iFailures = 0, $g_iChecks = 0
Global $g_aLocks[3] = [0, 0, 0]
Global $aTagsTest[1][2] = [["<USERNAME>", "test"]]
Global $aRecord = _HotkeyModel_Create("^!a", $HOTKEY_ACTION_COMMAND, "echo test")
$g_sActionLockReader = "_ReadLock"
_ProcessActions_ConfigureShellBackend("_ShellSpy")
Global $i, $j, $bResult, $iError
For $i = 0 To 2
    For $j = 0 To 2
        $aRecord[$HOTKEY_FIELD_CAPS_LOCK + $i] = $j
        $g_aLocks[$i] = 0
        $g_iCalls = 0
        _Check(_ActionDispatcher_Dispatch($aRecord, $aTagsTest), "off state dispatch succeeds or skips")
        _Check($g_iCalls = Number($j <> $HOTKEY_LOCK_ON), "off state action count")
        $g_aLocks[$i] = 1
        $g_iCalls = 0
        _Check(_ActionDispatcher_Dispatch($aRecord, $aTagsTest), "on state dispatch succeeds or skips")
        _Check($g_iCalls = Number($j <> $HOTKEY_LOCK_OFF), "on state action count")
    Next
    $aRecord[$HOTKEY_FIELD_CAPS_LOCK + $i] = 0
    $g_aLocks[$i] = 0
Next
$aRecord[$HOTKEY_FIELD_CAPS_LOCK] = 1
$aRecord[$HOTKEY_FIELD_NUM_LOCK] = 2
$g_aLocks[0] = 1
$g_iReads = 0
$g_iCalls = 0
_Check(_ActionDispatcher_Dispatch($aRecord, $aTagsTest) And $g_iCalls = 1, "AND matches")
_Check($g_iReads = 3, "read snapshot once")
$g_aLocks[1] = 1
$g_iCalls = 0
_Check(_ActionDispatcher_Dispatch($aRecord, $aTagsTest) And $g_iCalls = 0, "AND mismatch skips")
$aRecord[$HOTKEY_FIELD_ACTION] = $HOTKEY_ACTION_FILE
$aRecord[$HOTKEY_FIELD_TARGET] = @TempDir & "\hotkeyz-absent-" & @AutoItPID & "\missing.exe"
$g_sLastApplicationError = ""
_Check(_HotkeyRegistry_ExecuteRecord($aRecord, False), "mismatch skips missing target")
_Check($g_sLastApplicationError = "", "mismatch reports no error")
$g_bReadFailure = True
$bResult = _ActionDispatcher_Dispatch($aRecord, $aTagsTest)
$iError = @error
_Check(Not $bResult And $iError = $ACTION_DISPATCH_ERROR_INPUT_STATE, "read failure distinguished")
If $g_iFailures Then Exit 1
ConsoleWrite("PASSED: " & $g_iChecks & " lock dispatch assertions" & @CRLF)
Func _ReadLock($iKey)
    $g_iReads += 1
    If $g_bReadFailure Then Return SetError(1, 0, 0)
    Switch $iKey
        Case 0x14
            Return $g_aLocks[0]
        Case 0x90
            Return $g_aLocks[1]
        Case 0x91
            Return $g_aLocks[2]
    EndSwitch
EndFunc
Func _ShellSpy($sFile, $sArgs, $sDirectory, $sVerb, $iShow)
    #forceref $sFile, $sArgs, $sDirectory, $sVerb, $iShow
    $g_iCalls += 1
    Return 123
EndFunc
Func _Check($bOk, $sMessage)
    $g_iChecks += 1
    If Not $bOk Then
        $g_iFailures += 1
        ConsoleWrite("FAIL: " & $sMessage & @CRLF)
    EndIf
EndFunc
