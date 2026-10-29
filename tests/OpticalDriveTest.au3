#NoTrayIcon
; No hardware commands: every tray operation below uses a spy.
#include "..\src\core\AppConstants.au3"
#include "..\src\app\HotkeyRegistry.au3"
#include "..\src\gui\HotkeyEditorModel.au3"
Opt("MustDeclareVars", 1)
Global $g_iChecks = 0, $g_iFailures = 0, $g_iTrayCalls = 0, $g_iBindings = 0
Global $g_iListMode = 0, $g_iTrayResult = 1, $g_bTrayError = False
Global $g_sLastDrive = "", $g_sLastOperation = ""
Global $g_sTrayState = "closed", $g_iStateReads = 0
Global $g_sProfile = @TempDir & "\hkz-optical-test-" & @AutoItPID & ".ini"
If FileExists($g_sProfile) Or FileExists($g_sProfile & ".bak") Then Exit 2
OnAutoItExitRegister("_CleanupOptical")
$g_sOpticalListHandler = "_OpticalListSpy"
$g_sOpticalTrayHandler = "_OpticalTraySpy"
Global $aOpen = _HotkeyModel_Create("^!{F9}", $HOTKEY_ACTION_SYSTEM, "Open optical drive tray D:")
Global $aClose = _HotkeyModel_Create("^!{F10}", $HOTKEY_ACTION_SYSTEM, "Close optical drive tray E:")
Global $aTagsTest[1][2] = [["<USERNAME>", "test"]]
Global $bResult, $iError, $i
_CheckOptical(_SystemActions_GetId($aOpen[$HOTKEY_FIELD_TARGET]) = $SYSTEM_ACTION_OPEN_OPTICAL_TRAY, "fixed open identifier")
_CheckOptical(_SystemActions_GetId($aClose[$HOTKEY_FIELD_TARGET]) = $SYSTEM_ACTION_CLOSE_OPTICAL_TRAY, "fixed close identifier")
_CheckOptical(_OpticalDriveModel_Target($OPTICAL_ACTION_OPEN, "d:") = "Open optical drive tray D:", "canonical drive letter")
Global $aInvalid[8] = ["Open optical drive tray", "Open optical drive tray D:\", "Open optical drive tray DD:", "Open optical drive tray \\server\drive", "Open optical drive tray D: extra", "Flip optical drive tray D:", "Close optical drive tray D:" & @LF, "Open optical drive tray D:|Lock"]
For $i = 0 To UBound($aInvalid) - 1
    _CheckOptical(_SystemActions_GetId($aInvalid[$i]) = $SYSTEM_ACTION_NONE, "reject malformed action " & $i)
    _CheckOptical(Not _OpticalDriveActions_Execute($aInvalid[$i]), "malformed input never executes " & $i)
Next
_CheckOptical($g_iTrayCalls = 0, "no malformed calls reached tray backend")
Global $aDrives = _OpticalDriveActions_List()
_CheckOptical(IsArray($aDrives) And $aDrives[0] = 0, "no optical drives")
_CheckOptical(_ActionValidator_ValidateRecord($aOpen, False), "bulk validation accepts disconnected drive")
_CheckOptical(Not _ActionValidator_ValidateRecord($aOpen, True), "editor rejects unavailable drive")
$bResult = _ActionDispatcher_Dispatch($aOpen, $aTagsTest)
$iError = @error
_CheckOptical(Not $bResult And $iError = $ACTION_DISPATCH_ERROR_OPTICAL_MISSING, "missing drive has distinct execution error")
_CheckOptical($g_iTrayCalls = 0, "missing drive never invokes CDTray")
_HotkeyRegistry_ExecuteRecord($aOpen, False)
_CheckOptical(StringInStr($g_sLastApplicationError, "selected optical drive is not connected") > 0, "missing drive error explains problem")
$g_iListMode = 1
$aDrives = _OpticalDriveActions_List()
_CheckOptical($aDrives[0] = 2 And $aDrives[1] = "D:" And $aDrives[2] = "E:", "multiple drives normalized")
_CheckOptical(_ActionValidator_ValidateRecord($aOpen, True), "empty optical drive accepted without media check")
For $i = 1 To 3
    _CheckOptical(_ActionDispatcher_Dispatch($aOpen, $aTagsTest), "repeated open succeeds")
    _CheckOptical($g_sLastDrive = "D:" And $g_sLastOperation = "open", "open routes exact drive and operation")
    _CheckOptical(_ActionDispatcher_Dispatch($aClose, $aTagsTest), "repeated close succeeds")
    _CheckOptical($g_sLastDrive = "E:" And $g_sLastOperation = "closed", "close uses closed operation")
Next
_CheckOptical($g_iTrayCalls = 6, "one command per action")
$g_iListMode = 2
$bResult = _ActionDispatcher_Dispatch($aOpen, $aTagsTest)
$iError = @error
_CheckOptical(Not $bResult And $iError = $ACTION_DISPATCH_ERROR_OPTICAL_MISSING And $g_iTrayCalls = 6, "selected drive removed does not operate another drive")
_CheckOptical(_ActionDispatcher_Dispatch($aClose, $aTagsTest), "remaining drive continues working")
$g_iTrayResult = 0
$bResult = _ActionDispatcher_Dispatch($aClose, $aTagsTest)
$iError = @error
_CheckOptical(Not $bResult And $iError = $ACTION_DISPATCH_ERROR_OPTICAL_OPERATION, "locked or failed tray command distinguished")
_HotkeyRegistry_ExecuteRecord($aClose, False)
_CheckOptical(StringInStr($g_sLastApplicationError, "locked by another application") > 0 And StringInStr($g_sLastApplicationError, "closed by hand") > 0, "failure message explains locked and manual-close drives")
$g_iTrayResult = 1
$g_bTrayError = True
_CheckOptical(Not _OpticalDriveActions_Execute($aClose[$HOTKEY_FIELD_TARGET]), "backend error cannot report success")
$g_bTrayError = False
_CheckOptical(_OpticalDriveActions_Execute($aClose[$HOTKEY_FIELD_TARGET]), "manual-close hardware success means request accepted, no closure probe")
$g_iListMode = 3
$bResult = _ActionDispatcher_Dispatch($aClose, $aTagsTest)
$iError = @error
_CheckOptical(Not $bResult And $iError = $ACTION_DISPATCH_ERROR_OPTICAL_ENUMERATION, "enumeration error separated from no drives")
$g_iListMode = 4
_CheckOptical(Not _OpticalDriveActions_IsAvailable("D:"), "invalid enumeration fails closed")
; Conditions gate execution before drive checks, and profile persistence is
; independent of currently connected hardware.
$g_iListMode = 0
$aOpen[$HOTKEY_FIELD_CAPS_LOCK] = $HOTKEY_LOCK_ON
Global $aSnapshot = _InputState_Create(), $iBeforeCalls = $g_iTrayCalls
_CheckOptical(_ActionDispatcher_Dispatch($aOpen, $aTagsTest, $aSnapshot) And $g_iTrayCalls = $iBeforeCalls, "false condition quietly skips missing drive")
Global $aTable = _HotkeyRepository_CreateTable(2)
_HotkeyRepository_SetRecord($aTable, 1, $aOpen)
_HotkeyRepository_SetRecord($aTable, 2, $aClose)
_CheckOptical(_HotkeyRepository_Save($g_sProfile, $aTable), "save disconnected drives")
Global $aReloaded = _HotkeyRepository_Load($g_sProfile)
_CheckOptical(IsArray($aReloaded) And _HotkeyRepository_Count($aReloaded) = 2, "reload imported optical profile")
_CheckOptical($aReloaded[1][$HOTKEY_FIELD_TARGET] = $aOpen[$HOTKEY_FIELD_TARGET] And $aReloaded[2][$HOTKEY_FIELD_TARGET] = $aClose[$HOTKEY_FIELD_TARGET], "selected drive and operations retained")
_CheckOptical($aReloaded[1][$HOTKEY_FIELD_CAPS_LOCK] = $HOTKEY_LOCK_ON, "restrictions retained")
_HotkeyRegistry_ConfigureHotkeyBackend("_OpticalBindingSpy")
_CheckOptical(_iniToApply($g_sProfile) And $g_iBindings = 2, "startup registers disconnected drive actions")
Global $aOther = _HotkeyModel_Create("^!a", $HOTKEY_ACTION_TEXT, "ordinary")
_CheckOptical(_ActionValidator_ValidateRecord($aOther, False), "unrelated action remains valid")
$g_iListMode = 1
$g_sOpticalStateHandler = "_OpticalStateSpy"
Global $aToggle = _HotkeyModel_Create("^!t", $HOTKEY_ACTION_SYSTEM, "Open/close optical drive tray D:")
_CheckOptical(_ActionDispatcher_Dispatch($aToggle, $aTagsTest) And $g_sLastOperation = "open", "closed tray toggles open")
$g_sTrayState = "open"
_CheckOptical(_ActionDispatcher_Dispatch($aToggle, $aTagsTest) And $g_sLastOperation = "closed", "open tray toggles closed after external change")
_CheckOptical($g_iStateReads = 2, "toggle reads state every press")
$g_sTrayState = "not ready"
$iBeforeCalls = $g_iTrayCalls
$bResult = _ActionDispatcher_Dispatch($aToggle, $aTagsTest)
$iError = @error
_CheckOptical(Not $bResult And $iError = $ACTION_DISPATCH_ERROR_OPTICAL_STATE And $g_iTrayCalls = $iBeforeCalls, "unknown state never guesses or operates")
Global $aToggleDecoded = _HotkeyCodec_DecodeLegacy("^!t", _HotkeyCodec_EncodeLegacy($aToggle))
_CheckOptical(IsArray($aToggleDecoded) And $aToggleDecoded[$HOTKEY_FIELD_TARGET] = $aToggle[$HOTKEY_FIELD_TARGET], "toggle profile round trip")
ConsoleWrite("Optical assertions: " & $g_iChecks & "; failures: " & $g_iFailures & @CRLF)
If $g_iFailures Then Exit 1

Func _OpticalListSpy()
    Switch $g_iListMode
        Case 0
            Local $aEmpty[1] = [0]
            Return $aEmpty
        Case 1
            Local $aMultiple[3] = [2, "d:", "e:"]
            Return $aMultiple
        Case 2
            Local $aRemaining[2] = [1, "E:"]
            Return $aRemaining
        Case 3
            Return SetError(1, 0, 0)
        Case Else
            Local $aInvalidDrives[2] = [2, "D:"]
            Return $aInvalidDrives
    EndSwitch
EndFunc
Func _OpticalStateSpy($sDrive)
    _CheckOptical($sDrive = "D:", "query selected drive")
    $g_iStateReads += 1
    Return $g_sTrayState
EndFunc
Func _OpticalTraySpy($sDrive, $sOperation)
    $g_iTrayCalls += 1
    $g_sLastDrive = $sDrive
    $g_sLastOperation = $sOperation
    If $g_bTrayError Then Return SetError(1, 0, 1)
    Return $g_iTrayResult
EndFunc
Func _OpticalBindingSpy($sHotkey, $sHandler)
    #forceref $sHotkey, $sHandler
    $g_iBindings += 1
    Return True
EndFunc
Func _CheckOptical($bOk, $sMessage)
    $g_iChecks += 1
    If $bOk Then Return
    $g_iFailures += 1
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
EndFunc
Func _CleanupOptical()
    FileDelete($g_sProfile)
    FileDelete($g_sProfile & ".bak")
    FileDelete($g_sProfile & ".tmp")
EndFunc
