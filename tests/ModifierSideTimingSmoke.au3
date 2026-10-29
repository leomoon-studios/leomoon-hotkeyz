#NoTrayIcon
#include "..\src\core\InputHook.au3"
Opt("MustDeclareVars", 1)
Opt("SendKeyDelay", 0)
Opt("SendKeyDownDelay", 0)
Global $aNames[8] = ["LCTRL", "RCTRL", "LALT", "RALT", "LSHIFT", "RSHIFT", "LWIN", "RWIN"]
Global $aVks[8] = [0xA2, 0xA3, 0xA4, 0xA5, 0xA0, 0xA1, 0x5B, 0x5C]
Global $aCombos[4] = ["^{F9}", "!{F9}", "+{F9}", "#{F9}"]
Global $g_iCallbacks = 0, $g_iSnapshots = 0, $g_iLiveMismatches = 0, $g_iHookMismatches = 0
Global $g_sMode = "", $g_iSender = 0
If $CmdLine[0] Then
    Sleep(600)
    If StringLeft($CmdLine[1], 7) = "delayed" Then
        _SendSideKey(0xA2, False)
        _SendSideKey(0x78, False)
        _SendSideKey(0x78, True)
        _SendSideKey(0xA2, True)
        Sleep(300)
        ControlClick("HotKeyz side timing test", "", "Button1")
    Else
        Global $iGroup, $iSides
        For $iGroup = 0 To 3
            For $iSides = 1 To 3
                If BitAND($iSides, 1) Then _SendSideKey($aVks[$iGroup * 2], False)
                If BitAND($iSides, 2) Then _SendSideKey($aVks[$iGroup * 2 + 1], False)
                _SendSideKey(0x78, False)
                If $CmdLine[1] = "held" Then Sleep(80)
                _SendSideKey(0x78, True)
                If BitAND($iSides, 2) Then _SendSideKey($aVks[$iGroup * 2 + 1], True)
                If BitAND($iSides, 1) Then _SendSideKey($aVks[$iGroup * 2], True)
                Sleep(80)
            Next
        Next
    EndIf
    Sleep(200)
    Exit 0
EndIf
OnAutoItExitRegister("_CleanupSides")
Global $i
For $i = 0 To 3
    If Not HotKeySet($aCombos[$i], "_SampleSides") Then _FailSides("test shortcut unavailable: " & $aCombos[$i])
Next
If Not _InputHook_Start() Then _FailSides("observer hook installation failed")
_RunSides("held", 12)
_RunSides("rapid", 12)
_RunSides("delayed", 1)
_InputHook_Stop(True)
_RunSides("delayed-no-hook", 1)
ConsoleWrite("PASSED: observer snapshots survive release and delayed HotKeySet callbacks; x64=" & @AutoItX64 & @CRLF)
Exit 0
Func _ExpectedSides($iIndex)
    If StringLeft($g_sMode, 7) = "delayed" Then Return 1
    Return (Mod($iIndex, 3) + 1) * (4 ^ Int($iIndex / 3))
EndFunc
Func _RunSides($sMode, $iExpected)
    $g_sMode = $sMode
    $g_iCallbacks = 0
    $g_iSnapshots = 0
    $g_iLiveMismatches = 0
    $g_iHookMismatches = 0
    $g_iSender = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" ' & $sMode, "", @SW_HIDE)
    If Not $g_iSender Then _FailSides("sender failed")
    If StringLeft($sMode, 7) = "delayed" Then MsgBox(0, "HotKeyz side timing test", "The sender will close this dialog.", 5)
    Local $hTimer = TimerInit()
    While ProcessExists($g_iSender) And TimerDiff($hTimer) < 8000
        _DrainSides()
        Sleep(5)
    WEnd
    If ProcessExists($g_iSender) Then _FailSides("sender timed out")
    Sleep(100)
    _DrainSides()
    ConsoleWrite("RESULT: mode=" & $sMode & "; callbacks=" & $g_iCallbacks & "; snapshots=" & $g_iSnapshots & "; live mismatches=" & $g_iLiveMismatches & "; hook mismatches=" & $g_iHookMismatches & @CRLF)
    Local $iExpectedSnapshots = $iExpected
    If $sMode = "delayed-no-hook" Then $iExpectedSnapshots = 0
    If $g_iCallbacks <> $iExpected Or $g_iSnapshots <> $iExpectedSnapshots Or $g_iHookMismatches <> 0 Then _FailSides("event capture mismatch")
    If $sMode = "delayed-no-hook" And $g_iLiveMismatches <> 1 Then _FailSides("delayed callback did not expose state loss")
EndFunc
Func _SampleSides()
    Local $iMask = 0, $j, $aResult
    For $j = 0 To 7
        $aResult = DllCall("user32.dll", "short", "GetAsyncKeyState", "int", $aVks[$j])
        If IsArray($aResult) And BitAND($aResult[0], 0x8000) Then $iMask = BitOR($iMask, 2 ^ $j)
    Next
    If $iMask <> _ExpectedSides($g_iCallbacks) Then $g_iLiveMismatches += 1
    $g_iCallbacks += 1
EndFunc
Func _DrainSides()
    Local $aEvent, $j, $iMask
    While True
        $aEvent = _InputHook_Read()
        If @error Then ExitLoop
        If $aEvent[0] <> 0x78 Then ContinueLoop
        $iMask = 0
        For $j = 0 To 7
            If $aEvent[$j + 2] Then $iMask = BitOR($iMask, 2 ^ $j)
        Next
        If $iMask <> _ExpectedSides($g_iSnapshots) Then $g_iHookMismatches += 1
        $g_iSnapshots += 1
    WEnd
EndFunc
Func _CleanupSides()
    If $g_iSender And ProcessExists($g_iSender) Then ProcessClose($g_iSender)
    Local $j
    For $j = 0 To 3
        HotKeySet($aCombos[$j])
    Next
    _InputHook_Stop(True)
EndFunc
Func _FailSides($sReason)
    ConsoleWrite("FAIL: " & $sReason & @CRLF)
    Exit 1
EndFunc

Func _SendSideKey($iVk, $bUp)
    Local $aScan = DllCall("user32.dll", "uint", "MapVirtualKeyW", "uint", $iVk, "uint", 0)
    Local $iFlags = 0
    If $iVk = 0xA3 Or $iVk = 0xA5 Or $iVk = 0x5B Or $iVk = 0x5C Then $iFlags = 1
    If $bUp Then $iFlags = BitOR($iFlags, 2)
    DllCall("user32.dll", "none", "keybd_event", "byte", $iVk, "byte", $aScan[0], "dword", $iFlags, "ulong_ptr", 0)
EndFunc