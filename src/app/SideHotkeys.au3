#include-once
#include "..\core\InputKey.au3"
#include "..\core\InputState.au3"
#include "..\core\InputSend.au3"
#include <GUIConstantsEx.au3>

; Side-specific shortcuts remain registered Windows hotkeys. The hook only observes.
Global $g_hSideWindow = 0, $g_hSideHook = 0, $g_hSideCallback = 0

Global $g_iSideNext = 1, $g_iSideCount = 0
Global $g_aSideRecords[1][$HOTKEY_FIELD_COUNT], $g_aSideKeys[1][3]
Global $g_aSideMap[256][16], $g_aSideVkCount[256]
Global $g_iSideGeneration = 1
Global $g_aSideQueue[128][$HOTKEY_FIELD_COUNT + $INPUT_STATE_COUNT + 1]
Global $g_iSideRead = 0, $g_iSideQueueWrite = 0, $g_bSideDispatching = False
Global $g_iSideMisses = 0
Global $g_hSideLastPoll = TimerInit(), $g_iSideReportedMisses = 0
Global $g_sSideInstallHandler = "_SideHotkeys_NativeInstall", $g_sSideUnhookHandler = "_SideHotkeys_NativeUnhook"
Global $g_sSideUnregisterHandler = "_SideHotkeys_NativeUnregister"
Global $g_bSideHookStopFailed = False, $g_bSideStopWarningShown = False, $g_bSideRefreshWarningShown = False

Func _SideHotkeys_NativeInstall($pCallback)
    Local $aHook = DllCall("user32.dll", "handle", "SetWindowsHookExW", "int", 13, "ptr", $pCallback, "handle", 0, "dword", 0)
    If @error Or Not IsArray($aHook) Or Not $aHook[0] Then Return SetError(1, 0, 0)
    Return $aHook[0]
EndFunc

Func _SideHotkeys_NativeUnhook($hHook)
    Local $aResult = DllCall("user32.dll", "bool", "UnhookWindowsHookEx", "handle", $hHook)
    If @error Or Not IsArray($aResult) Then Return SetError(1, 0, False)
    If Not $aResult[0] Then
        Local $aError = DllCall("kernel32.dll", "dword", "GetLastError")
        ; ERROR_INVALID_HOOK_HANDLE means Windows already removed the hook.
        If Not IsArray($aError) Or $aError[0] <> 1404 Then Return SetError(1, 0, False)
    EndIf
    Return True
EndFunc

Func _SideHotkeys_NativeUnregister($hWindow, $iId)
    Local $aResult = DllCall("user32.dll", "bool", "UnregisterHotKey", "hwnd", $hWindow, "int", $iId)
    If @error Or Not IsArray($aResult) Or Not $aResult[0] Then Return False
    Return True
EndFunc

Func _SideHotkeys_NativeMask($iMask)
    Return BitOR(BitAND($iMask, 12), BitShift(BitAND($iMask, 1), -1), BitShift(BitAND($iMask, 2), 1))
EndFunc

Func _SideHotkeys_Start()
    If $g_bSideHookStopFailed Then Return SetError(3, 0, False)
    If $g_hSideHook Then Return True
    If Not $g_hSideWindow Then
        Local $aWindow = DllCall("user32.dll", "hwnd", "CreateWindowExW", "dword", 0, "wstr", "STATIC", "wstr", "HotKeyz registered input receiver", "dword", 0, "int", 0, "int", 0, "int", 0, "int", 0, "hwnd", 0, "handle", 0, "handle", 0, "ptr", 0)
        If @error Or Not IsArray($aWindow) Or Not $aWindow[0] Then Return SetError(1, 0, False)
        $g_hSideWindow = $aWindow[0]
    EndIf
    $g_hSideCallback = DllCallbackRegister("_SideHotkeys_Observe", "lresult", "int;wparam;lparam")
    If @error Or Not $g_hSideCallback Then Return SetError(1, 0, False)
    Local $hHook = Call($g_sSideInstallHandler, DllCallbackGetPtr($g_hSideCallback))
    If @error Or Not $hHook Then
        DllCallbackFree($g_hSideCallback)
        $g_hSideCallback = 0
        Return SetError(2, 0, False)
    EndIf
    $g_hSideHook = $hHook
    Return True
EndFunc

Func _SideHotkeys_Register(ByRef $aRecord)
    Local $aKey = _InputKey_Compile($aRecord[$HOTKEY_FIELD_HOTKEY])
    If @error Or Not IsArray($aKey) Then Return SetError(1, 0, False)
    If $g_iSideNext >= 0x6000 Then Return SetError(2, 0, False)
    If $g_aSideMap[$aKey[0]][$aKey[1]] Then Return SetError(3, 0, False)
    If Not _SideHotkeys_Start() Then Return SetError(4, @error, False)
    Local $iSlot = $g_iSideNext, $i
    ; IDs are not reused, so queued messages from deleted records cannot hit new actions.
    $g_iSideNext += 1
    ReDim $g_aSideRecords[$g_iSideNext][$HOTKEY_FIELD_COUNT]
    ReDim $g_aSideKeys[$g_iSideNext][3]
    Local $aResult = DllCall("user32.dll", "bool", "RegisterHotKey", "hwnd", $g_hSideWindow, "int", 0x5000 + $iSlot, "uint", _SideHotkeys_NativeMask($aKey[1]), "uint", $aKey[0])
    If @error Or Not IsArray($aResult) Or Not $aResult[0] Then Return SetError(5, 0, False)
    For $i = 0 To $HOTKEY_FIELD_COUNT - 1
        $g_aSideRecords[$iSlot][$i] = $aRecord[$i]
    Next
    $g_aSideKeys[$iSlot][0] = True
    $g_aSideKeys[$iSlot][1] = $aKey[0]
    $g_aSideKeys[$iSlot][2] = $aKey[1]
    $g_aSideMap[$aKey[0]][$aKey[1]] = $iSlot
    $g_aSideVkCount[$aKey[0]] += 1
    $g_iSideCount += 1
    Return True
EndFunc

Func _SideHotkeys_Unregister(ByRef $aRecord)
    Local $i
    For $i = 1 To $g_iSideNext - 1
        If Not $g_aSideKeys[$i][0] Then ContinueLoop
        If _HotkeyCodec_NormalizeHotkey($aRecord[$HOTKEY_FIELD_HOTKEY]) <> _HotkeyCodec_NormalizeHotkey($g_aSideRecords[$i][$HOTKEY_FIELD_HOTKEY]) Then ContinueLoop
        If Not Call($g_sSideUnregisterHandler, $g_hSideWindow, 0x5000 + $i) Then Return SetError(1, 0, False)
        $g_aSideMap[$g_aSideKeys[$i][1]][$g_aSideKeys[$i][2]] = 0
        $g_aSideKeys[$i][0] = False
        $g_aSideVkCount[$g_aSideKeys[$i][1]] -= 1
        $g_iSideCount -= 1
        Return True
    Next
    Return True
EndFunc

Func _SideHotkeys_Observe($iCode, $wParam, $lParam)
    If Not $g_bSideHookStopFailed And $iCode >= 0 And ($wParam = 0x0100 Or $wParam = 0x0104) Then
        Local $tEvent = DllStructCreate("dword vk;dword scan;dword flags;dword time;ulong_ptr extra", $lParam)
        Local $iVk = DllStructGetData($tEvent, "vk")
        ; Base-key events precede their own async update, but earlier modifier events
        ; have already updated async state. Sample modifier sides, never the base key.
        If $iVk < 256 And $g_aSideVkCount[$iVk] > 0 And $iVk <> 0x10 And $iVk <> 0x11 And $iVk <> 0x12 And $iVk <> 0x5B And $iVk <> 0x5C And ($iVk < 0xA0 Or $iVk > 0xA5) Then
            Local $aVks[8] = [0xA2, 0xA3, 0xA4, 0xA5, 0xA0, 0xA1, 0x5B, 0x5C], $aSides[8], $i, $aState, $iMask = 0, $bRead = True
            For $i = 0 To 7
                $aState = DllCall("user32.dll", "short", "GetAsyncKeyState", "int", $aVks[$i])
                If @error Or Not IsArray($aState) Then $bRead = False
                If IsArray($aState) Then $aSides[$i] = BitAND($aState[0], 0x8000) <> 0
                If $aSides[$i] Then $iMask = BitOR($iMask, 2 ^ Int($i / 2))
            Next
            Local $iSlot = $g_aSideMap[$iVk][$iMask]
            If Not $bRead Then
                $iSlot = 0
                $g_iSideMisses += 1
            EndIf
            If $g_bInputSending And BitAND(DllStructGetData($tEvent, "flags"), 0x10) Then $iSlot = 0
            If $iSlot Then
                Local $iNext = Mod($g_iSideQueueWrite + 1, 128)
                If $iNext <> $g_iSideRead Then
                    $g_aSideQueue[$g_iSideQueueWrite][0] = $iSlot
                    For $i = 0 To $HOTKEY_FIELD_COUNT - 1
                        $g_aSideQueue[$g_iSideQueueWrite][$i + 1] = $g_aSideRecords[$iSlot][$i]
                    Next
                    For $i = 0 To 7
                        $g_aSideQueue[$g_iSideQueueWrite][$HOTKEY_FIELD_COUNT + 1 + $i] = $aSides[$i]
                    Next
                    $g_iSideQueueWrite = $iNext
                Else
                    $g_iSideMisses += 1
                EndIf
            EndIf
        EndIf
    EndIf
    Local $aNext = DllCall("user32.dll", "lresult", "CallNextHookEx", "handle", $g_hSideHook, "int", $iCode, "wparam", $wParam, "lparam", $lParam)
    If @error Or Not IsArray($aNext) Then Return 0
    Return $aNext[0]
EndFunc

Func _SideHotkeys_Poll()
    If $g_bSideDispatching Then Return
    ; Windows can silently remove a hook after a blocked callback. A handle is
    ; not a health check: renew after a long main-loop gap, retaining queued input.
    If $g_iSideCount And TimerDiff($g_hSideLastPoll) > 500 Then _SideHotkeys_RefreshObserver()
    $g_hSideLastPoll = TimerInit()
    If $g_iSideRead <> $g_iSideQueueWrite Then
        Local $iSlot = $g_aSideQueue[$g_iSideRead][0], $aRecord[$HOTKEY_FIELD_COUNT], $aSnapshot[$INPUT_STATE_COUNT], $i
        For $i = 0 To $HOTKEY_FIELD_COUNT - 1
            $aRecord[$i] = $g_aSideQueue[$g_iSideRead][$i + 1]
        Next
        Local $iStateError = 0, $iLastField = $INPUT_STATE_COUNT - 1, $bActive = False
        If $iSlot > 0 Then
            $bActive = $g_aSideKeys[$iSlot][0] And Not $g_bSideHookStopFailed
            $aSnapshot = _ActionDispatcher_CaptureState($aRecord)
            $iStateError = @error
            If $iStateError Then $aSnapshot = _InputState_Create()
            $iLastField = 7
        Else
            $bActive = (-$iSlot = $g_iSideGeneration)
        EndIf
        For $i = 0 To $iLastField
            $aSnapshot[$i] = $g_aSideQueue[$g_iSideRead][$HOTKEY_FIELD_COUNT + 1 + $i]
        Next
        $g_iSideRead = Mod($g_iSideRead + 1, 128)
        If $iStateError Then $g_iSideMisses += 1
        If $bActive And Not $iStateError Then
            $g_bSideDispatching = True
            _HotkeyRegistry_ExecuteRecord($aRecord, True, $aSnapshot)
            $g_bSideDispatching = False
        EndIf
    EndIf
    If $g_iSideCount = 0 Then
        If _SideHotkeys_StopObserver() Then
            $g_bSideRefreshWarningShown = False
        ElseIf Not $g_bSideStopWarningShown Then
            $g_bSideStopWarningShown = True
            _AppWarning_ReportNonBlocking("The modifier-side keyboard observer could not be stopped. HotKeyz will retry. If side-specific shortcuts cannot be re-enabled, restart HotKeyz.")
        EndIf
    EndIf
    If $g_iSideMisses <> $g_iSideReportedMisses Then
        ConsoleWrite("HotKeyz: skipped " & ($g_iSideMisses - $g_iSideReportedMisses) & " hotkey events because the input queue was full or input state could not be read." & @CRLF)
        $g_iSideReportedMisses = $g_iSideMisses
    EndIf
EndFunc

Func _SideHotkeys_RefreshObserver()
    If _SideHotkeys_StopObserver() And _SideHotkeys_Start() Then
        $g_bSideRefreshWarningShown = False
        Return True
    EndIf
    ; Do not leave side shortcuts captured indefinitely without an observer.
    Local $i, $aRecord, $bReleased = True
    For $i = 1 To $g_iSideNext - 1
        If Not $g_aSideKeys[$i][0] Then ContinueLoop
        $aRecord = _HotkeyModel_Create($g_aSideRecords[$i][$HOTKEY_FIELD_HOTKEY], $HOTKEY_ACTION_COMMAND, "")
        If Not _SideHotkeys_Unregister($aRecord) Then $bReleased = False
    Next
    Local $sWarning = "Modifier-side hotkeys could not resume after a pause. Disable and re-enable HotKeyz to retry; if that fails, restart HotKeyz. Other hotkeys remain available."
    If Not $bReleased Then $sWarning &= @CRLF & @CRLF & "Some affected shortcuts could not be released and may remain captured until HotKeyz exits."
    If Not $g_bSideRefreshWarningShown Then
        $g_bSideRefreshWarningShown = True
        $g_bSideStopWarningShown = True
        _AppWarning_ReportNonBlocking($sWarning)
    EndIf
    Return False
EndFunc

Func _SideHotkeys_StopObserver()
    If $g_hSideHook Then
        If Not Call($g_sSideUnhookHandler, $g_hSideHook) Then
            $g_bSideHookStopFailed = True
            Return False
        EndIf
        $g_hSideHook = 0
    EndIf
    If $g_hSideCallback Then DllCallbackFree($g_hSideCallback)
    $g_hSideCallback = 0
    $g_bSideHookStopFailed = False
    $g_bSideStopWarningShown = False
    Return True
EndFunc

Func _SideHotkeys_Shutdown()
    _SideHotkeys_StopObserver()
    If $g_hSideWindow Then DllCall("user32.dll", "bool", "DestroyWindow", "hwnd", $g_hSideWindow)
    $g_hSideWindow = 0
EndFunc
Func _SideHotkeys_QueueOrdinary(ByRef $aRecord)
    Local $aSnapshot = _ActionDispatcher_CaptureState($aRecord)
    If @error Then
        $g_iSideMisses += 1
        Return False
    EndIf
    Local $iNext = Mod($g_iSideQueueWrite + 1, 128), $i
    If $iNext = $g_iSideRead Then
        $g_iSideMisses += 1
        Return False
    EndIf
    $g_aSideQueue[$g_iSideQueueWrite][0] = -$g_iSideGeneration
    For $i = 0 To $HOTKEY_FIELD_COUNT - 1
        $g_aSideQueue[$g_iSideQueueWrite][$i + 1] = $aRecord[$i]
    Next
    For $i = 0 To $INPUT_STATE_COUNT - 1
        $g_aSideQueue[$g_iSideQueueWrite][$HOTKEY_FIELD_COUNT + 1 + $i] = $aSnapshot[$i]
    Next
    $g_iSideQueueWrite = $iNext
    Return True
EndFunc
