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
Global $g_iActions = 0, $g_iFailures = 0, $g_iChild = 0, $g_sBlockMode = "", $g_iDuringBlock = 0
If $CmdLine[0] Then
    Switch $CmdLine[1]
        Case "sender"
            Sleep(650)
            _SendSequence(0xA2)
            Sleep(550)
            _SendSequence(0xA3)
            Sleep(550)
            _SendSequence(0xA2)
            Exit 0
        Case "sleeper"
            Sleep(3500)
            Exit 0
        Case "single"
            Sleep(250)
            _SendSequence(0xA2)
            Exit 0
    EndSwitch
EndIf
OnAutoItExitRegister("_BlockCleanup")
_ProcessActions_ConfigureShellBackend("_BlockSpy")
Global $aRecord = _HotkeyModel_Create("^+{F9}", $HOTKEY_ACTION_COMMAND, "echo test")
$aRecord[$HOTKEY_FIELD_CTRL_SIDE] = $HOTKEY_SIDE_LEFT
Global $aBlockTable = _HotkeyRepository_CreateTable(1)
_HotkeyRepository_SetRecord($aBlockTable, 1, $aRecord)
If Not _HotkeyRegistry_SetTable($aBlockTable, "HotKeyPressed") Then
    ConsoleWrite("FAIL: test shortcut unavailable" & @CRLF)
    Exit 2
EndIf
_BlockScenario("RunWait")
_BlockScenario("native Sleep")
If $g_iFailures Then Exit 1
ConsoleWrite("PASSED: blocking action observation and recovery; x64=" & @AutoItX64 & @CRLF)
Func _BlockScenario($sMode)
    _SideHotkeys_Poll()
    Local $iBefore = $g_iActions
    $g_iDuringBlock = 0
    $g_sBlockMode = $sMode
    $g_iChild = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" sender', "", @SW_HIDE)
    Local $hTimer = TimerInit()
    Local $aTriggerState = _InputState_Create()
    $aTriggerState[$INPUT_CTRL_LEFT] = True
    $aTriggerState[$INPUT_SHIFT_LEFT] = True
    _HotkeyRegistry_ExecuteRecord($aRecord, False, $aTriggerState)
    Local $iDuration = Round(TimerDiff($hTimer))
    $g_sBlockMode = ""
    Local $iPending = Mod($g_iSideQueueWrite - $g_iSideRead + 128, 128)
    Local $j
    For $j = 1 To 120
        _SideHotkeys_Poll()
        Sleep(2)
    Next
    If ProcessExists($g_iChild) Then ProcessClose($g_iChild)
    Local $iExecuted = $g_iActions - $iBefore - 1
    ConsoleWrite($sMode & ": duration=" & $iDuration & "ms; queue_after=" & $iPending & "; during_action=" & $g_iDuringBlock & "; deferred_matches=" & $iExecuted & "; observer_handle=" & ($g_hSideHook <> 0) & @CRLF)
    If $iDuration < 2500 Or $g_iDuringBlock <> 0 Or $iExecuted < 0 Or $iExecuted > 2 Then
        $g_iFailures += 1
        ConsoleWrite("FAIL: action did not block, dispatched reentrantly, or produced an unexpected action count" & @CRLF)
    EndIf
    $iBefore = $g_iActions
    $g_iChild = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" single', "", @SW_HIDE)
    Local $hWait = TimerInit()
    While ProcessExists($g_iChild) And TimerDiff($hWait) < 6000
        _SideHotkeys_Poll()
        Sleep(5)
    WEnd
    For $j = 1 To 100
        _SideHotkeys_Poll()
        Sleep(2)
    Next
    If $g_iActions <> $iBefore + 1 Then
        $g_iFailures += 1
        ConsoleWrite("FAIL: shortcut did not recover after " & $sMode & @CRLF)
    EndIf
EndFunc
Func _BlockSpy($sFile, $sArgs, $sDir, $sVerb, $iShow)
    #forceref $sFile, $sArgs, $sDir, $sVerb, $iShow
    $g_iActions += 1
    If $g_sBlockMode = "" Then Return 123
    Local $iEntryCount = $g_iActions
    If $g_sBlockMode = "RunWait" Then
        RunWait('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" sleeper', "", @SW_HIDE)
    Else
        DllCall("kernel32.dll", "none", "Sleep", "dword", 3500)
    EndIf
    $g_iDuringBlock = $g_iActions - $iEntryCount
    Return 123
EndFunc
Func _SendSequence($iCtrl)
    _SendKey($iCtrl, False)
    _SendKey(0xA0, False)
    _SendKey(0x78, False)
    _SendKey(0x78, True)
    _SendKey(0xA0, True)
    _SendKey($iCtrl, True)
EndFunc
Func _SendKey($iVk, $bUp)
    Local $aScan = DllCall("user32.dll", "uint", "MapVirtualKeyW", "uint", $iVk, "uint", 0), $iFlags = 0
    If $iVk = 0xA3 Then $iFlags = 1
    If $bUp Then $iFlags = BitOR($iFlags, 2)
    DllCall("user32.dll", "none", "keybd_event", "byte", $iVk, "byte", $aScan[0], "dword", $iFlags, "ulong_ptr", 0)
EndFunc
Func _BlockCleanup()
    If $g_iChild And ProcessExists($g_iChild) Then ProcessClose($g_iChild)
    _HotkeyRegistry_ClearTable($aBlockTable)
    _SideHotkeys_Shutdown()
EndFunc
