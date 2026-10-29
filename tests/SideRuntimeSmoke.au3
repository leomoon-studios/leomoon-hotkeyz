#NoTrayIcon
; Interactive test: creates a temporary INI in Temp and registers
; test hotkeys. It never changes the Windows startup registry value.
#include "..\src\resources\ExtMsgBox.au3"
#include "..\src\core\AppConstants.au3"
#include "..\src\core\ActionCatalog.au3"
#include "..\src\core\HotkeyRepository.au3"
#include "..\src\gui\GuiState.au3"
#include "..\src\actions\TextActions.au3"
#include "..\src\actions\SystemActions.au3"
#include "..\src\actions\WindowActions.au3"
#include "..\src\actions\ProcessActions.au3"
#include "..\src\actions\ActionDispatcher.au3"
#include "..\src\app\HotkeyRegistry.au3"
#include "..\src\app\TrayController.au3"
#include "..\src\gui\HotkeyEditor.au3"
#include "..\src\gui\MainWindow.au3"

Opt("MustDeclareVars", 1)
Opt("GUIOnEventMode", 1)
Global $aVks[8] = [0xA2, 0xA3, 0xA4, 0xA5, 0xA0, 0xA1, 0x5B, 0x5C]
Global $aKeys[4] = ["^{F9}", "!{F9}", "+{F9}", "#{F9}"]
Global $g_iRuns = 0, $g_iFailed = 0, $g_iChild = 0
Global $g_iTestLocks = 0
Global $g_bTestSend = False
Global $sProfile = @TempDir & "\hkz-side-runtime-" & @AutoItPID & ".ini"
If $CmdLine[0] Then
    If $CmdLine[1] = "conflict" Then
        If HotKeySet("^{F9}", "HotKeyPressed") Then Exit 9
        Exit 0
    EndIf
    Sleep(500)
    If $CmdLine[1] = "ordinary" Then
        _SendSideKey(0xA2, False)
        _SendSideKey(0x79, False)
        _SendSideKey(0x79, True)
        _SendSideKey(0xA2, True)
        Exit 0
    EndIf
    Global $iGroup, $iRepeat, $iSides = Number($CmdLine[1]), $iRepeats = 1
    If $CmdLine[1] = "delayed" Then $iSides = 1
    If $CmdLine[1] = "repeat" Or $CmdLine[1] = "overflow" Then
        $iSides = 1
        $iRepeats = 3
        If $CmdLine[1] = "overflow" Then $iRepeats = 40
    EndIf
    For $iGroup = 0 To 3
        If BitAND($iSides, 1) Then _SendSideKey($aVks[$iGroup * 2], False)
        If BitAND($iSides, 2) Then _SendSideKey($aVks[$iGroup * 2 + 1], False)
        For $iRepeat = 1 To $iRepeats
            _SendSideKey(0x78, False)
            Sleep(5)
        Next
        _SendSideKey(0x78, True)
        If BitAND($iSides, 2) Then _SendSideKey($aVks[$iGroup * 2 + 1], True)
        If BitAND($iSides, 1) Then _SendSideKey($aVks[$iGroup * 2], True)
        Sleep(80)
    Next
    If $CmdLine[1] = "delayed" Then ControlClick("HotKeyz side deferred dispatch", "", "Button1")
    Sleep(200)
    Exit 0
EndIf
OnAutoItExitRegister("_CleanupSideRuntime")
_ProcessActions_ConfigureShellBackend("_SideSpy")
Global $aTable = _HotkeyRepository_CreateTable(4), $aRecord, $i
For $i = 0 To 3
    $aRecord = _HotkeyModel_Create($aKeys[$i], $HOTKEY_ACTION_COMMAND, "echo test")
    $aRecord[$HOTKEY_FIELD_CTRL_SIDE + $i] = $HOTKEY_SIDE_LEFT
    _HotkeyRepository_SetRecord($aTable, $i + 1, $aRecord)
Next
If Not _HotkeyRepository_Save($sProfile, $aTable) Then Exit 2
If Not _iniToApply($sProfile) Or $g_iSideCount <> 4 Then Exit 3
_ScenarioSide("1")
_CheckSide($g_iRuns = 4, "left presses execute")
_ScenarioSide("2")
_CheckSide($g_iRuns = 4, "right presses skip")
_ScenarioSide("3")
_CheckSide($g_iRuns = 8, "both sides satisfy left restriction")
_toggle()
_SideHotkeys_Poll()
_CheckSide($g_iSideCount = 0 And $g_hSideHook = 0, "disable removes observer")
_toggle()
_ScenarioSide("1")
_CheckSide($g_iRuns = 12, "re-enable restores side shortcuts")
$g_iChild = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" delayed', "", @SW_HIDE)
MsgBox(0, "HotKeyz side deferred dispatch", "The sender closes this dialog", 5)
_CheckSide($g_iRuns = 12, "no action dispatch inside dialog or observer")
_WaitSide()
_CheckSide($g_iRuns = 16, "delayed records preserve press-time sides")
_CheckSide($g_iSideMisses = 0, "no dropped observations")
_ScenarioSide("repeat")
_CheckSide($g_iRuns = 28, "each repeated key-down executes once")
$g_iChild = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" conflict', "", @SW_HIDE)
ProcessWaitClose($g_iChild, 5)
Global $iConflictExit = @extended
_CheckSide($iConflictExit = 0, "another process cannot register an owned shortcut")
Global $aReserved = _HotkeyModel_Create("#l", $HOTKEY_ACTION_COMMAND, "echo reserved")
$aReserved[$HOTKEY_FIELD_WIN_SIDE] = $HOTKEY_SIDE_LEFT
_CheckSide(Not _SideHotkeys_Register($aReserved), "reserved Win+L cannot bypass registration")
; Observe presses but reload before the normal-loop consumer can run them.
$g_iChild = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" 1', "", @SW_HIDE)
_WaitSideWithoutDispatch()
_CheckSide($g_iSideRead <> $g_iSideQueueWrite, "presses queued before reload")
_HotkeyRegistry_ClearTable($aHotkeys)
_CheckSide(_iniToApply($sProfile), "reload side profile")
_WaitSide()
_CheckSide($g_iRuns = 28, "deleted registration cannot execute stale actions")
; Exercise right-side requirements and lock gates together with a deterministic
; lock reader; physical lock-state reads are covered by LockRuntimeSmoke.
_HotkeyRegistry_ClearTable($aHotkeys)
For $i = 0 To 3
    $aRecord = _HotkeyRepository_GetRecord($aTable, $i + 1)
    $aRecord[$HOTKEY_FIELD_CTRL_SIDE + $i] = $HOTKEY_SIDE_RIGHT
    $aRecord[$HOTKEY_FIELD_CAPS_LOCK] = $HOTKEY_LOCK_ON
    _HotkeyRepository_SetRecord($aTable, $i + 1, $aRecord)
Next
_HotkeyRepository_Save($sProfile, $aTable)
_iniToApply($sProfile)
$g_sActionLockReader = "_SideLockReader"
_ScenarioSide("2")
_CheckSide($g_iRuns = 28, "right side with false lock skips")
$g_iTestLocks = 1
_ScenarioSide("1")
_CheckSide($g_iRuns = 28, "true lock with wrong side skips")
_ScenarioSide("2")
_CheckSide($g_iRuns = 32, "right side and true lock execute")
; Force removal without clearing our stored handle, as Windows may do on timeout.
DllCall("user32.dll", "bool", "UnhookWindowsHookEx", "handle", $g_hSideHook)
Sleep(600)
_SideHotkeys_Poll()
_ScenarioSide("2")
_CheckSide($g_iRuns = 36, "observer recovers after removal and loop pause")
; Restore left-side fixtures, then fill the bounded queue without dispatch.
_HotkeyRegistry_ClearTable($aHotkeys)
For $i = 0 To 3
    $aRecord = _HotkeyRepository_GetRecord($aTable, $i + 1)
    $aRecord[$HOTKEY_FIELD_CTRL_SIDE + $i] = $HOTKEY_SIDE_LEFT
    _HotkeyRepository_SetRecord($aTable, $i + 1, $aRecord)
Next
_HotkeyRepository_Save($sProfile, $aTable)
_iniToApply($sProfile)
$g_iChild = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" overflow', "", @SW_HIDE)
_WaitSideWithoutDispatch()
_CheckSide($g_iSideMisses = 33, "overflow drops only the 33 events beyond queue capacity")
_WaitSide()
_CheckSide($g_iRuns = 163, "127 queued presses dispatch exactly once")
; A command action is allowed to receive external injected presses while running,
; but HotKeyz's own Send must not recursively trigger the registered action.
$g_bTestSend = True
_ScenarioSide("1")
$g_bTestSend = False
_CheckSide($g_iRuns = 167, "action-generated input does not recursively execute")
Global $aFailedTable = _HotkeyRepository_CreateTable(5)
For $i = 1 To 4
    $aRecord = _HotkeyRepository_GetRecord($aHotkeys, $i)
    _HotkeyRepository_SetRecord($aFailedTable, $i, $aRecord)
Next
_HotkeyRepository_SetRecord($aFailedTable, 5, $aReserved)
_CheckSide(Not _HotkeyRegistry_ApplyBindings("", $aHotkeys, "^!+{F11}", $aFailedTable), "failed apply reports registration error")
_CheckSide($g_iSideCount = 4, "failed apply restores prior side bindings")
_ScenarioSide("1")
_CheckSide($g_iRuns = 171, "restored bindings still dispatch")
; Register with a modifier already held: no initial modifier down event exists
; for the new observer, so its snapshot must use the prior processed key state.
_HotkeyRegistry_ClearTable($aHotkeys)
_SideHotkeys_Poll()
_SendSideKey(0xA2, False)
Sleep(50)
_iniToApply($sProfile)
_SendSideKey(0x78, False)
_SendSideKey(0x78, True)
_SendSideKey(0xA2, True)
_WaitSide()
_CheckSide($g_iRuns = 172, "modifier held before observer startup is recognized")
_HotkeyRegistry_ClearTable($aHotkeys)
$aRecord = _HotkeyModel_Create("^{F10}", $HOTKEY_ACTION_COMMAND, "echo ordinary")
$aRecord[$HOTKEY_FIELD_CAPS_LOCK] = $HOTKEY_LOCK_ON
_HotkeyRepository_SetRecord($aFailedTable, 5, $aRecord)
_HotkeyRepository_Save($sProfile, $aFailedTable)
_iniToApply($sProfile)
_ScenarioSide("ordinary")
_CheckSide($g_iRuns = 173, "ordinary lock-only callback coexists with side observer")
If $g_iFailed Then Exit 1
ConsoleWrite("PASSED: side hotkeys, both sides, locks, repeat, conflicts, reload, overflow, observer recovery, deferred dispatch; x64=" & @AutoItX64 & @CRLF)
Func _SideLockReader($iVk)
    #forceref $iVk
    Return $g_iTestLocks
EndFunc
Func _WaitSideWithoutDispatch()
    Local $hTimer = TimerInit()
    While ProcessExists($g_iChild) And TimerDiff($hTimer) < 6000
        Sleep(5)
    WEnd
    _CheckSide(Not ProcessExists($g_iChild), "sender completed")
EndFunc
Func _ScenarioSide($sMode)
    $g_iChild = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" ' & $sMode, "", @SW_HIDE)
    _WaitSide()
EndFunc
Func _WaitSide()
    Local $hTimer = TimerInit()
    While ProcessExists($g_iChild) And TimerDiff($hTimer) < 6000
        _SideHotkeys_Poll()
        Sleep(5)
    WEnd
    _CheckSide(Not ProcessExists($g_iChild), "sender completed")
    Local $j
    For $j = 1 To 130
        _SideHotkeys_Poll()
        Sleep(1)
    Next
EndFunc
Func _SideSpy($sFile, $sArgs, $sDir, $sVerb, $iShow)
    #forceref $sFile, $sArgs, $sDir, $sVerb, $iShow
    $g_iRuns += 1
    If $g_bTestSend Then _InputSend_Keys("^{F9}")
    Return 123
EndFunc
Func _CheckSide($bOk, $sMessage)
    If Not $bOk Then
        $g_iFailed += 1
        ConsoleWrite("FAIL: " & $sMessage & "; runs=" & $g_iRuns & "; misses=" & $g_iSideMisses & @CRLF)
    EndIf
EndFunc
Func _CleanupSideRuntime()
    If $g_iChild And ProcessExists($g_iChild) Then ProcessClose($g_iChild)
    _HotkeyRegistry_ClearTable($aHotkeys)
    _SideHotkeys_Shutdown()
    FileDelete($sProfile)
    FileDelete($sProfile & ".bak")
EndFunc
Func _SendSideKey($iVk, $bUp)
    Local $aScan = DllCall("user32.dll", "uint", "MapVirtualKeyW", "uint", $iVk, "uint", 0)
    Local $iFlags = 0
    If $iVk = 0xA3 Or $iVk = 0xA5 Or $iVk = 0x5B Or $iVk = 0x5C Then $iFlags = 1
    If $bUp Then $iFlags = BitOR($iFlags, 2)
    DllCall("user32.dll", "none", "keybd_event", "byte", $iVk, "byte", $aScan[0], "dword", $iFlags, "ulong_ptr", 0)
EndFunc
