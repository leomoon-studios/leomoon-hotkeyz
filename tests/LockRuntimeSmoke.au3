#NoTrayIcon
; Interactive test: creates a temporary INI beside this script and registers
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
Opt("SendCapslockMode", 0)
Opt("GUIOnEventMode", 1)
Global $g_iExecuted = 0, $g_iFailures = 0, $g_bOwner = False
Global $aOriginal = _InputState_Create(), $g_iChild = 0
Global $sProfile = @TempDir & "\hkz-lock-runtime-" & @AutoItPID & ".ini"
If $CmdLine[0] Then
    If $CmdLine[1] = "conflict" Then
        If HotKeySet("^!{F9}", "HotKeyPressed") Then Exit 9
        Exit 0
    EndIf
    Sleep(400)
    If $CmdLine[1] = "delayed" Then
        Send("{CAPSLOCK off}")
        Sleep(60)
        Send("^!{F9}")
        Sleep(80)
        Send("{CAPSLOCK on}")
        Sleep(100)
        ControlClick("HotKeyz delayed callback test", "", "Button1")
    ElseIf $CmdLine[1] = "rapid" Then
        Global $i
        For $i = 1 To 5
            Send("{CAPSLOCK off}")
            Sleep(20)
            Send("^!{F9}")
            Sleep(30)
            Send("{CAPSLOCK on}")
            Sleep(20)
            Send("^!{F9}")
            Sleep(30)
        Next
    Else
        Send("{CAPSLOCK " & $CmdLine[1] & "}")
        Sleep(60)
        Send("^!{F9}")
    EndIf
    Sleep(150)
    Exit 0
EndIf
If Not _InputState_ReadLocks($aOriginal) Then Exit 2
$g_bOwner = True
OnAutoItExitRegister("_CleanupRuntime")
_ProcessActions_ConfigureShellBackend("_RuntimeSpy")
_CheckRuntime(Not HotKeySet("#l", "HotKeyPressed"), "Windows-reserved Win+L is unavailable")
HotKeySet("#l")
Global $aTable = _HotkeyRepository_CreateTable(1), $aRecord = _HotkeyModel_Create("^!{F9}", $HOTKEY_ACTION_COMMAND, "echo harmless-test")
$aRecord[$HOTKEY_FIELD_CAPS_LOCK] = $HOTKEY_LOCK_ON
_HotkeyRepository_SetRecord($aTable, 1, $aRecord)
If Not _HotkeyRepository_Save($sProfile, $aTable) Or Not _iniToApply($sProfile) Then Exit 3
$g_iChild = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" conflict', "", @SW_HIDE)
ProcessWaitClose($g_iChild, 5)
Global $iConflictExit = @extended
_CheckRuntime($iConflictExit = 0, "second process cannot register owned conditional shortcut")
_SendScenario("off")
_CheckRuntime($g_iExecuted = 0, "off skips")
_SendScenario("on")
_CheckRuntime($g_iExecuted = 1, "on executes")
_toggle()
_SendScenario("on")
_CheckRuntime($g_iExecuted = 1, "disabled does not execute")
_toggle()
_SendScenario("on")
_CheckRuntime($g_iExecuted = 2, "re-enabled executes")
_SendScenario("rapid")
_CheckRuntime($g_iExecuted = 7, "rapid alternation executes only matching presses")
Global $iBeforeDelayed = $g_iExecuted
$g_iChild = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" delayed', "", @SW_HIDE)
MsgBox(0, "HotKeyz delayed callback test", "The test sender will close this dialog.", 5)
_WaitRuntime()
ConsoleWrite("DELAYED: action count=" & ($g_iExecuted - $iBeforeDelayed) & @CRLF)
_CheckRuntime($g_iExecuted = $iBeforeDelayed + 1, "delayed callback evaluates state when callback executes")
_HotkeyRegistry_ClearTable($aHotkeys)
If Not _iniToApply($sProfile) Then Exit 4
_SendScenario("on")
_CheckRuntime($g_iExecuted = $iBeforeDelayed + 2, "reload registers lock-only entry")
If $g_iFailures Then Exit 1
ConsoleWrite("PASSED: actual lock-only startup, execution, skip, disable/re-enable, rapid and delayed callbacks, reload; x64=" & @AutoItX64 & @CRLF)
Func _RuntimeSpy($sFile, $sArgs, $sDir, $sVerb, $iShow)
    #forceref $sFile, $sArgs, $sDir, $sVerb, $iShow
    $g_iExecuted += 1
    Return 123
EndFunc
Func _SendScenario($sMode)
    $g_iChild = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" ' & $sMode, "", @SW_HIDE)
    _WaitRuntime()
EndFunc
Func _WaitRuntime()
    Local $hTimer = TimerInit()
    While ProcessExists($g_iChild) And TimerDiff($hTimer) < 7000
        Sleep(10)
    WEnd
    If ProcessExists($g_iChild) Then
        ProcessClose($g_iChild)
        $g_iFailures += 1
    EndIf
    Sleep(100)
EndFunc
Func _CheckRuntime($bOk, $sMessage)
    If Not $bOk Then
        $g_iFailures += 1
        ConsoleWrite("FAIL: " & $sMessage & "; count=" & $g_iExecuted & @CRLF)
    EndIf
EndFunc
Func _CleanupRuntime()
    If Not $g_bOwner Then Return
    HotKeySet("^!{F9}")
    If ProcessExists($g_iChild) Then ProcessClose($g_iChild)
    Local $aNames[3] = ["CAPSLOCK", "NUMLOCK", "SCROLLLOCK"], $i, $sState
    For $i = 0 To 2
        $sState = "off"
        If $aOriginal[$INPUT_CAPS + $i] Then $sState = "on"
        Send("{" & $aNames[$i] & " " & $sState & "}")
    Next
    FileDelete($sProfile)
    FileDelete($sProfile & ".bak")
    FileDelete($sProfile & ".tmp")
EndFunc