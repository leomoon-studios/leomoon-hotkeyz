#NoTrayIcon
; Exploratory test only. The hook always forwards input and is removed on exit.
Opt("MustDeclareVars", 1)

Global $g_hHook = 0, $g_hCallback = 0, $g_iLeft = 0, $g_iRight = 0
Global $g_iLeftMatches = 0, $g_iRightMatches = 0, $g_iBothMatches = 0, $g_iInjected = 0
Global $g_iKeyUp = 0
Global $g_iDelivered = 0, $g_iIntercepted = 0

If $CmdLine[0] Then
    Sleep(700)
    If $CmdLine[1] = "send" Then
        Send("{LCTRL down}{F9 down}{F9 up}{LCTRL up}")
        Send("{RCTRL down}{F9 down}{F9 up}{RCTRL up}")
        Send("{LCTRL down}{RCTRL down}{F9 down}{F9 up}{RCTRL up}{LCTRL up}")
    Else
        Send("{RCTRL down}{F9 down}{F9 up}{RCTRL up}")
    EndIf
    Exit 0
EndIf

OnAutoItExitRegister("_PrototypeCleanup")
$g_hCallback = DllCallbackRegister("_PrototypeHook", "lresult", "int;wparam;lparam")
If @error Or Not $g_hCallback Then _PrototypeFail("callback registration failed")
Global $aHook = DllCall("user32.dll", "handle", "SetWindowsHookExW", "int", 13, "ptr", DllCallbackGetPtr($g_hCallback), "handle", 0, "dword", 0)
If @error Or Not IsArray($aHook) Or Not $aHook[0] Then _PrototypeFail("hook installation failed")
$g_hHook = $aHook[0]
Global $iSender = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" send', "", @SW_HIDE)
If @error Or Not $iSender Then _PrototypeFail("sender could not start")
Global $hTimer = TimerInit()
While ProcessExists($iSender) And TimerDiff($hTimer) < 5000
    Sleep(10)
WEnd
If ProcessExists($iSender) Then
    ProcessClose($iSender)
    _PrototypeFail("sender timed out")
EndIf
Sleep(200)
If $g_iLeftMatches <> 1 Or $g_iRightMatches <> 1 Or $g_iBothMatches <> 1 Or $g_iKeyUp < 3 Or $g_iInjected < 3 Then _PrototypeFail("unexpected events: left=" & $g_iLeftMatches & ", right=" & $g_iRightMatches & ", both=" & $g_iBothMatches & ", keyup=" & $g_iKeyUp & ", injected=" & $g_iInjected)
ConsoleWrite("PASSED: x64=" & @AutoItX64 & "; injected left/right/both Ctrl captured at base-key down and key-up forwarded" & @CRLF)
Global $hWindow = GUICreate("HotKeyz temporary modifier prototype", 260, 80)
GUIRegisterMsg(0x0100, "_PrototypeKeyDown")
GUISetState(@SW_SHOW, $hWindow)
WinActivate($hWindow)
If Not WinWaitActive($hWindow, "", 3) Then _PrototypeFail("test window could not be activated")
_PrototypeSendOnce()
If $g_iDelivered <> 1 Then _PrototypeFail("unregistered control shortcut was not delivered to test window")
If Not HotKeySet("^{F9}", "_PrototypeIntercepted") Then _PrototypeFail("test shortcut is already registered")
$g_iDelivered = 0
_PrototypeSendOnce()
HotKeySet("^{F9}")
GUIDelete($hWindow)
If $g_iIntercepted <> 1 Or $g_iDelivered <> 0 Then _PrototypeFail("unexpected registered shortcut delivery: callback=" & $g_iIntercepted & ", window=" & $g_iDelivered)
ConsoleWrite("PASSED: registered generic Ctrl+F9 consumes right-Ctrl input before a left-only post-filter could reject it" & @CRLF)
Exit 0

Func _PrototypeSendOnce()
    Local $iPid = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" single', "", @SW_HIDE)
    If @error Or Not $iPid Then _PrototypeFail("single-event sender could not start")
    Local $hWait = TimerInit()
    While ProcessExists($iPid) And TimerDiff($hWait) < 5000
        Sleep(10)
    WEnd
    If ProcessExists($iPid) Then
        ProcessClose($iPid)
        _PrototypeFail("single-event sender timed out")
    EndIf
    Sleep(200)
EndFunc

Func _PrototypeKeyDown($hWnd, $iMsg, $wParam, $lParam)
    #forceref $hWnd, $iMsg, $lParam
    If $wParam = 0x78 Then $g_iDelivered += 1
    Return "GUI_RUNDEFMSG"
EndFunc

Func _PrototypeIntercepted()
    $g_iIntercepted += 1
EndFunc

Func _PrototypeHook($iCode, $wParam, $lParam)
    If $iCode >= 0 Then
        Local $tEvent = DllStructCreate("dword vk;dword scan;dword flags;dword time;ulong_ptr extra", $lParam)
        Local $iVk = DllStructGetData($tEvent, "vk")
        Local $iFlags = DllStructGetData($tEvent, "flags")
        Local $bDown = ($wParam = 0x0100 Or $wParam = 0x0104)
        Local $bUp = ($wParam = 0x0101 Or $wParam = 0x0105)
        If $iVk = 0xA2 And ($bDown Or $bUp) Then $g_iLeft = $bDown
        If $iVk = 0xA3 And ($bDown Or $bUp) Then $g_iRight = $bDown
        If $iVk = 0x78 Then
            If BitAND($iFlags, 0x10) Then $g_iInjected += 1
            If $bDown Then
                If $g_iLeft And $g_iRight Then
                    $g_iBothMatches += 1
                ElseIf $g_iLeft Then
                    $g_iLeftMatches += 1
                ElseIf $g_iRight Then
                    $g_iRightMatches += 1
                EndIf
            ElseIf $bUp Then
                $g_iKeyUp += 1
            EndIf
        EndIf
    EndIf
    Local $aNext = DllCall("user32.dll", "lresult", "CallNextHookEx", "handle", $g_hHook, "int", $iCode, "wparam", $wParam, "lparam", $lParam)
    If @error Or Not IsArray($aNext) Then Return 0
    Return $aNext[0]
EndFunc

Func _PrototypeCleanup()
    If $g_hHook Then DllCall("user32.dll", "bool", "UnhookWindowsHookEx", "handle", $g_hHook)
    If $g_hCallback Then DllCallbackFree($g_hCallback)
EndFunc

Func _PrototypeFail($sMessage)
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
    Exit 1
EndFunc

