#NoTrayIcon
#include "..\src\core\InputState.au3"
Opt("MustDeclareVars", 1)
Opt("SendCapslockMode", 0)
Global $aOriginal = _InputState_Create(), $g_iReceived = 0, $g_iFailures = 0
If $CmdLine[0] Then
    Global $hSenderWindow = GUICreate("HotKeyz foreground sender", 260, 90)
    GUISetState(@SW_SHOW, $hSenderWindow)
    WinActivate($hSenderWindow)
    Sleep(600)
    Send("{CAPSLOCK off}{NUMLOCK off}{SCROLLLOCK off}")
    Sleep(100)
    Send("^!{F9}")
    Sleep(150)
    Send("{CAPSLOCK on}{NUMLOCK on}{SCROLLLOCK on}")
    Sleep(100)
    Send("^!{F9}")
    Sleep(150)
    Exit 0
EndIf
If Not _InputState_ReadLocks($aOriginal) Then Exit 2
OnAutoItExitRegister("_Cleanup")
If Not HotKeySet("^!{F9}", "_Capture") Then Exit 3
Global $hGui = GUICreate("HotKeyz lock-state test", 260, 90)
GUISetState(@SW_SHOW, $hGui)
WinActivate($hGui)
If Not WinWaitActive($hGui, "", 3) Then Exit 4
Global $iSender = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" send', "", @SW_HIDE)
Global $hTimer = TimerInit()
While ProcessExists($iSender) And TimerDiff($hTimer) < 6000
    Sleep(10)
WEnd
If ProcessExists($iSender) Then
    ProcessClose($iSender)
    Exit 5
EndIf
Sleep(200)
If $g_iReceived <> 2 Or $g_iFailures Then Exit 1
ConsoleWrite("PASSED: actual HotKeySet callback observes all lock toggles off/on; x64=" & @AutoItX64 & @CRLF)
Func _Capture()
    Local $aState = _InputState_Create(), $i
    If Not _InputState_ReadLocks($aState) Then $g_iFailures += 1
    For $i = $INPUT_CAPS To $INPUT_SCROLL
        If Number($aState[$i]) <> $g_iReceived Then
            ConsoleWrite("FAIL: event=" & $g_iReceived & ", lock=" & $i & ", state=" & $aState[$i] & @CRLF)
            $g_iFailures += 1
        EndIf
    Next
    $g_iReceived += 1
EndFunc
Func _Cleanup()
    HotKeySet("^!{F9}")
    Local $aNames[3] = ["CAPSLOCK", "NUMLOCK", "SCROLLLOCK"], $i, $sState
    For $i = 0 To 2
        $sState = "off"
        If $aOriginal[$INPUT_CAPS + $i] Then $sState = "on"
        Send("{" & $aNames[$i] & " " & $sState & "}")
    Next
EndFunc
