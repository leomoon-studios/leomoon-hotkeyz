#NoTrayIcon
#include "..\src\core\InputHook.au3"
#include <GUIConstantsEx.au3>
Opt("MustDeclareVars", 1)
If $CmdLine[0] Then
    Sleep(700)
    Send("{RCTRL down}{F9 down}{F9 up}{RCTRL up}")
    Send("{LCTRL down}{F9 down}{F9 up}{LCTRL up}")
    Exit 0
EndIf
Global $iDelivered = 0
OnAutoItExitRegister("_Cleanup")
Global $hGui = GUICreate("Hotkeyz hook test", 260, 90)
GUIRegisterMsg(0x0100, "_KeyDown")
GUISetState(@SW_SHOW, $hGui)
WinActivate($hGui)
If Not WinWaitActive($hGui, "", 3) Then _Fail("activate test window")
Global $aRules = _HotkeyRepository_CreateTable(1), $aRule = _HotkeyModel_Create("^{F9}", $HOTKEY_ACTION_TEXT, "test")
$aRule[$HOTKEY_FIELD_CTRL_SIDE] = $HOTKEY_SIDE_LEFT
If Not _HotkeyRepository_SetRecord($aRules, 1, $aRule) Then _Fail("record")
If Not _InputHook_Configure($aRules, True) Then _Fail("configure")
If Not _InputHook_Start() Then _Fail("start")
Global $iSender = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" send', "", @SW_HIDE)
If Not $iSender Then _Fail("sender")
Global $hTimer = TimerInit(), $aEvent, $iMatched = 0
While (ProcessExists($iSender) Or $g_iInputQueueRead <> $g_iInputQueueWrite) And TimerDiff($hTimer) < 7000
    $aEvent = _InputHook_Read()
    If IsArray($aEvent) Then
        If $aEvent[0] <> 0x78 Or $aEvent[$INPUT_STATE_COUNT + 2] <> 1 Then _Fail("unexpected match")
        $iMatched += 1
    EndIf
    Sleep(5)
WEnd
If ProcessExists($iSender) Then
    ProcessClose($iSender)
    _Fail("sender timeout")
EndIf
Sleep(100)
If $iMatched <> 1 Or $iDelivered <> 1 Then _Fail("pass-through=" & $iDelivered & ", matches=" & $iMatched)
ConsoleWrite("PASSED: right Ctrl forwarded and left Ctrl consumed and queued; x64=" & @AutoItX64 & @CRLF)
Exit 0
Func _KeyDown($hWnd, $iMsg, $wParam, $lParam)
    #forceref $hWnd, $iMsg, $lParam
    If $wParam = 0x78 Then $iDelivered += 1
    Return $GUI_RUNDEFMSG
EndFunc
Func _Cleanup()
    _InputHook_Stop()
    GUIDelete($hGui)
EndFunc
Func _Fail($sReason)
    ConsoleWrite("FAIL: " & $sReason & @CRLF)
    Exit 1
EndFunc
