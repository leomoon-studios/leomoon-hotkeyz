#NoTrayIcon
#include "..\src\core\InputHook.au3"
Opt("MustDeclareVars", 1)
If $CmdLine[0] Then
    Sleep(700)
    Send("{LCTRL down}{F9 down}{F9 up}{LCTRL up}")
    Send("{RCTRL down}{F9 down}{F9 up}{RCTRL up}")
    Send("{LCTRL down}{RCTRL down}{F9 down}{F9 up}{RCTRL up}{LCTRL up}")
    Exit 0
EndIf
OnAutoItExitRegister("_Cleanup")
If Not _InputHook_Start() Then _Fail("hook install")
If Not _InputHook_Start() Then _Fail("repeated install")
Global $iSender = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" send', "", @SW_HIDE)
If @error Or Not $iSender Then _Fail("sender start")
Global $hTimer = TimerInit(), $aEvent, $iF9 = 0, $aMasks[3] = [1, 2, 3], $iMask
While (ProcessExists($iSender) Or $g_iInputQueueRead <> $g_iInputQueueWrite) And TimerDiff($hTimer) < 7000
    $aEvent = _InputHook_Read()
    If IsArray($aEvent) And $aEvent[0] = 0x78 Then
        If $iF9 >= 3 Then _Fail("extra F9 event")
        $iMask = Number($aEvent[$INPUT_CTRL_LEFT + 2]) + 2 * Number($aEvent[$INPUT_CTRL_RIGHT + 2])
        If $iMask <> $aMasks[$iF9] Or Not $aEvent[1] Then _Fail("wrong event-time modifier snapshot")
        $iF9 += 1
    EndIf
    Sleep(5)
WEnd
If ProcessExists($iSender) Then
    ProcessClose($iSender)
    _Fail("sender timeout")
EndIf
If $iF9 <> 3 Or $g_iInputQueueDropped <> 0 Then _Fail("missing events or queue overflow")
If Not _InputHook_Stop() Or $g_hInputCallback <> 0 Then _Fail("hook cleanup")
If Not _InputHook_Stop() Then _Fail("repeated cleanup")
If Not _InputHook_Start() Or Not _InputHook_Stop() Then _Fail("hook restart")
ConsoleWrite("PASSED: forwarding hook captured event-time modifier sides and cleaned up; x64=" & @AutoItX64 & @CRLF)
Exit 0
Func _Cleanup()
    _InputHook_Stop()
EndFunc
Func _Fail($sReason)
    ConsoleWrite("FAIL: " & $sReason & @CRLF)
    Exit 1
EndFunc
