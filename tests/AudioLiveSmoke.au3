#include "..\src\actions\AudioDeviceActions.au3"
#include <AutoItConstants.au3>

; Interactive Windows test: temporarily changes audio defaults and restores
; each original role, including when a test fails. Do not run concurrently with
; another application changing the default audio devices.
Opt("MustDeclareVars", 1)

Global $g_aLiveOriginal[2][3], $g_bLiveChanged = False, $g_iLiveNotifications = 0
Global $g_iLiveAppPid = 0, $g_sLiveAppDir = ""
Global $g_iLiveFlow, $g_iLiveRole, $g_sLiveId
For $g_iLiveFlow = $AUDIO_FLOW_RENDER To $AUDIO_FLOW_CAPTURE
    For $g_iLiveRole = $AUDIO_ROLE_CONSOLE To $AUDIO_ROLE_COMMUNICATIONS
        $g_sLiveId = _AudioLive_GetRole($g_iLiveFlow, $g_iLiveRole)
        If @error Or $g_sLiveId = "" Then _AudioLive_Fail("cannot snapshot audio defaults for flow " & $g_iLiveFlow & ", role " & $g_iLiveRole)
        $g_aLiveOriginal[$g_iLiveFlow][$g_iLiveRole] = $g_sLiveId
    Next
Next
OnAutoItExitRegister("_AudioLive_Restore")

Global $aLivePlayback = _AudioDeviceActions_Enumerate($AUDIO_FLOW_RENDER)
If @error Or Not IsArray($aLivePlayback) Then _AudioLive_Fail("cannot enumerate active playback endpoints")
Global $aLiveRecording = _AudioDeviceActions_Enumerate($AUDIO_FLOW_CAPTURE)
If @error Or Not IsArray($aLiveRecording) Then _AudioLive_Fail("cannot enumerate active recording endpoints")
ConsoleWrite("Active endpoints: playback=" & UBound($aLivePlayback, 1) & ", recording=" & UBound($aLiveRecording, 1) & @CRLF)
If UBound($aLivePlayback, 1) < 2 Then _AudioLive_Fail("at least two playback endpoints are required")

If UBound($aLiveRecording, 1) < 2 Then _AudioLive_Fail("at least two recording endpoints are required")
_AudioLive_TestFlow($AUDIO_FLOW_RENDER, $aLivePlayback, "Playback")
If Not _AudioLive_RestoreDefaults() Then _AudioLive_Fail("could not restore playback defaults before recording test")
_AudioLive_TestFlow($AUDIO_FLOW_CAPTURE, $aLiveRecording, "Recording")
If Not _AudioLive_RestoreDefaults() Then _AudioLive_Fail("could not restore audio defaults before executable test")
_AudioLive_TestExecutable()

If Not _AudioLive_RestoreDefaults() Then _AudioLive_Fail("could not restore original audio defaults")
$g_bLiveChanged = False
ConsoleWrite("PASSED: live playback and recording cycles, all three roles, flow isolation, notification requests, and original-default restoration" & @CRLF)
Exit 0

Func _AudioLive_TestFlow($iFlow, ByRef $aEndpoints, $sLabel)
    Local $iOtherFlow = $AUDIO_FLOW_CAPTURE
    If $iFlow = $AUDIO_FLOW_CAPTURE Then $iOtherFlow = $AUDIO_FLOW_RENDER
    Local $i, $iRole, $iExpected, $sCurrent, $sSelected, $iError, $iNotificationsBefore
    For $i = 1 To UBound($aEndpoints, 1)
        $sCurrent = _AudioLive_GetRole($iFlow, $AUDIO_ROLE_CONSOLE)
        If @error Then _AudioLive_Fail("cannot read current " & $sLabel & " default")
        $iExpected = _AudioDeviceActions_NextIndex($aEndpoints, $sCurrent)
        $iNotificationsBefore = $g_iLiveNotifications
        ; Mark before calling: a partial SetDefaultEndpoint failure can still change a role.
        $g_bLiveChanged = True
        $sSelected = _AudioDeviceActions_Cycle($iFlow, "_AudioDeviceActions_Enumerate", "_AudioDeviceActions_GetDefaultId", "_AudioDeviceActions_SetDefaultId", "_AudioLive_Notify")
        $iError = @error
        If $iError Or $sSelected <> $aEndpoints[$iExpected][$AUDIO_ENDPOINT_NAME] Then _AudioLive_Fail($sLabel & " cycle failed or returned the wrong device: error " & $iError)
        If $g_iLiveNotifications <> $iNotificationsBefore + 1 Then _AudioLive_Fail($sLabel & " switch did not request a notification")
        For $iRole = $AUDIO_ROLE_CONSOLE To $AUDIO_ROLE_COMMUNICATIONS
            $sCurrent = _AudioLive_GetRole($iFlow, $iRole)
            If @error Or $sCurrent <> $aEndpoints[$iExpected][$AUDIO_ENDPOINT_ID] Then _AudioLive_Fail($sLabel & " role " & $iRole & " did not switch to selected device")
            $sCurrent = _AudioLive_GetRole($iOtherFlow, $iRole)
            If @error Or $sCurrent <> $g_aLiveOriginal[$iOtherFlow][$iRole] Then _AudioLive_Fail($sLabel & " cycling changed the other flow's role " & $iRole)
        Next
        ConsoleWrite($sLabel & " switched to: " & $sSelected & @CRLF)
    Next
EndFunc

Func _AudioLive_TestExecutable()
    Local $sSource = @ScriptDir & "\..\build\audio-cycling-manual\LeoMoon HotKeyz.exe"
    If Not FileExists($sSource) Then _AudioLive_Fail("manual-test executable was not built")
    If ProcessExists("LeoMoon HotKeyz.exe") Then _AudioLive_Fail("another HotKeyz executable is running; cannot isolate the binary test")
    $g_sLiveAppDir = @TempDir & "\hotkeyz-audio-binary-" & @AutoItPID
    If FileExists($g_sLiveAppDir) Then _AudioLive_Fail("binary test directory already exists")
    If Not DirCreate($g_sLiveAppDir) Then _AudioLive_Fail("could not create binary test directory")
    Local $sExe = $g_sLiveAppDir & "\LeoMoon HotKeyz.exe", $sIni = $g_sLiveAppDir & "\LeoMoon HotKeyz.ini"
    If Not FileCopy($sSource, $sExe) Then _AudioLive_Fail("could not copy test executable")
    If Not IniWrite($sIni, "Options", "Main", "^!+{F11}") Then _AudioLive_Fail("could not create isolated binary profile")
    If Not IniWrite($sIni, "Hotkeys", "^!+{F9}", "[HkzExe]Cycle Playback Device") Then _AudioLive_Fail("could not write playback test hotkey")
    If Not IniWrite($sIni, "Hotkeys", "^!+{F10}", "[HkzExe]Cycle Recording Device") Then _AudioLive_Fail("could not write recording test hotkey")
    Local $iRun, $iFlow, $iRole, $iExpected, $sCurrent, $aEndpoints, $hWait, $sKey
    For $iRun = 1 To 2
        $g_iLiveAppPid = Run('"' & $sExe & '"', $g_sLiveAppDir, @SW_HIDE, BitOR($STDOUT_CHILD, $STDERR_CHILD))
        If @error Or Not $g_iLiveAppPid Then _AudioLive_Fail("could not start test executable")
        Sleep(1500)
        If Not ProcessExists($g_iLiveAppPid) Then _AudioLive_Fail("test executable exited during startup")
        For $iFlow = $AUDIO_FLOW_RENDER To $AUDIO_FLOW_CAPTURE
            $aEndpoints = _AudioDeviceActions_Enumerate($iFlow)
            $sCurrent = _AudioLive_GetRole($iFlow, $AUDIO_ROLE_CONSOLE)
            If @error Or Not IsArray($aEndpoints) Then _AudioLive_Fail("could not read audio defaults for executable test")
            $iExpected = _AudioDeviceActions_NextIndex($aEndpoints, $sCurrent)
            $sKey = "^!+{F9}"
            If $iFlow = $AUDIO_FLOW_CAPTURE Then $sKey = "^!+{F10}"
            $g_bLiveChanged = True
            Send($sKey)
            $hWait = TimerInit()
            Do
                Sleep(50)
                $sCurrent = _AudioLive_GetRole($iFlow, $AUDIO_ROLE_CONSOLE)
            Until $sCurrent = $aEndpoints[$iExpected][$AUDIO_ENDPOINT_ID] Or TimerDiff($hWait) > 5000
            If $sCurrent <> $aEndpoints[$iExpected][$AUDIO_ENDPOINT_ID] Then
                ConsoleWrite("Application output: " & StdoutRead($g_iLiveAppPid) & StderrRead($g_iLiveAppPid) & @CRLF)
                _AudioLive_Fail("compiled executable did not handle audio hotkey " & $sKey & " on run " & $iRun)
            EndIf
            For $iRole = $AUDIO_ROLE_CONSOLE To $AUDIO_ROLE_COMMUNICATIONS
                $sCurrent = _AudioLive_GetRole($iFlow, $iRole)
                If @error Or $sCurrent <> $aEndpoints[$iExpected][$AUDIO_ENDPOINT_ID] Then _AudioLive_Fail("compiled executable did not set all audio roles")
            Next
        Next
        ProcessClose($g_iLiveAppPid)
        ProcessWaitClose($g_iLiveAppPid, 5)
        If ProcessExists($g_iLiveAppPid) Then _AudioLive_Fail("test executable did not close")
        $g_iLiveAppPid = 0
        If Not _AudioLive_RestoreDefaults() Then _AudioLive_Fail("could not restore defaults after executable test")
        ConsoleWrite("Compiled executable run " & $iRun & ": playback and recording hotkeys passed" & @CRLF)
    Next
EndFunc

Func _AudioLive_GetRole($iFlow, $iRole)
    Local $oErrorHandler = ObjEvent("AutoIt.Error", "_AudioDeviceActions_ComError")
    If Not IsObj($oErrorHandler) Then Return SetError(1, 0, "")
    $g_iAudioDeviceComError = 0
    Local $oEnumerator = ObjCreateInterface($g_sAudioEnumeratorClsid, $g_sAudioEnumeratorIid, $g_sAudioEnumeratorTag)
    If @error Or Not IsObj($oEnumerator) Then Return SetError(2, 0, "")
    Local $pDevice = 0
    Local $iResult = $oEnumerator.GetDefaultAudioEndpoint($iFlow, $iRole, $pDevice)
    If $g_iAudioDeviceComError Or $iResult <> 0 Or Not $pDevice Then Return SetError(3, $iResult, "")
    Local $oDevice = ObjCreateInterface($pDevice, $g_sAudioDeviceIid, $g_sAudioDeviceTag)
    If @error Or Not IsObj($oDevice) Then Return SetError(4, 0, "")
    Local $sId = _AudioDeviceActions_DeviceId($oDevice)
    Return SetError(@error, @extended, $sId)
EndFunc

Func _AudioLive_Notify($iFlow, $sName)
    $g_iLiveNotifications += 1
    _AudioDeviceActions_Notify($iFlow, $sName)
EndFunc

Func _AudioLive_RestoreDefaults()
    Local $oErrorHandler = ObjEvent("AutoIt.Error", "_AudioDeviceActions_ComError")
    If Not IsObj($oErrorHandler) Then Return False
    $g_iAudioDeviceComError = 0
    Local $oPolicy = ObjCreateInterface($g_sAudioPolicyClsid, $g_sAudioPolicyIid, $g_sAudioPolicyTag)
    If @error Or Not IsObj($oPolicy) Then Return False
    Local $iFlow, $iRole, $iResult, $bSuccess = True
    For $iFlow = $AUDIO_FLOW_RENDER To $AUDIO_FLOW_CAPTURE
        For $iRole = $AUDIO_ROLE_CONSOLE To $AUDIO_ROLE_COMMUNICATIONS
            $iResult = $oPolicy.SetDefaultEndpoint($g_aLiveOriginal[$iFlow][$iRole], $iRole)
            If $g_iAudioDeviceComError Or $iResult <> 0 Then $bSuccess = False
        Next
    Next
    For $iFlow = $AUDIO_FLOW_RENDER To $AUDIO_FLOW_CAPTURE
        For $iRole = $AUDIO_ROLE_CONSOLE To $AUDIO_ROLE_COMMUNICATIONS
            If _AudioLive_GetRole($iFlow, $iRole) <> $g_aLiveOriginal[$iFlow][$iRole] Then $bSuccess = False
        Next
    Next
    Return $bSuccess
EndFunc

Func _AudioLive_Restore()
    If $g_iLiveAppPid And ProcessExists($g_iLiveAppPid) Then ProcessClose($g_iLiveAppPid)
    If $g_bLiveChanged And Not _AudioLive_RestoreDefaults() Then ConsoleWrite("FAIL: could not restore original audio defaults; check Windows sound settings" & @CRLF)
    If $g_sLiveAppDir <> "" Then
        FileDelete($g_sLiveAppDir & "\LeoMoon HotKeyz.ini")
        FileDelete($g_sLiveAppDir & "\LeoMoon HotKeyz.ini.bak")
        FileDelete($g_sLiveAppDir & "\LeoMoon HotKeyz.ini.tmp")
        FileDelete($g_sLiveAppDir & "\LeoMoon HotKeyz.exe")
        DirRemove($g_sLiveAppDir)
    EndIf
EndFunc

Func _AudioLive_Fail($sMessage)
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
    Exit 1
EndFunc
