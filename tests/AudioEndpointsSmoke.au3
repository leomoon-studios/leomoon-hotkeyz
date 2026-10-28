#include "..\src\actions\AudioDeviceActions.au3"

Opt("MustDeclareVars", 1)

_CheckFlow($AUDIO_FLOW_RENDER, "playback")
_CheckFlow($AUDIO_FLOW_CAPTURE, "recording")

_AudioDeviceActions_Enumerate(99)
If @error = 0 Then _Fail("invalid audio flow was accepted")

ConsoleWrite("PASSED: playback and recording endpoint discovery" & @CRLF)
Exit 0

Func _CheckFlow($iFlow, $sLabel)
    Local $aEndpoints = _AudioDeviceActions_Enumerate($iFlow)
    If @error Or Not IsArray($aEndpoints) Then _Fail("no active " & $sLabel & " endpoints found")
    Local $sDefault = _AudioDeviceActions_GetDefaultId($iFlow)
    If @error Or $sDefault = "" Then _Fail("cannot read default " & $sLabel & " endpoint")
    Local $bFound = False
    Local $i
    For $i = 0 To UBound($aEndpoints, 1) - 1
        If $aEndpoints[$i][$AUDIO_ENDPOINT_ID] = "" Or $aEndpoints[$i][$AUDIO_ENDPOINT_NAME] = "" Then _Fail("endpoint ID or name is empty")
        ConsoleWrite($sLabel & ": " & $aEndpoints[$i][$AUDIO_ENDPOINT_NAME] & @CRLF)
        If $aEndpoints[$i][$AUDIO_ENDPOINT_ID] = $sDefault Then $bFound = True
    Next
    If Not $bFound Then _Fail("default " & $sLabel & " endpoint is not active")
EndFunc

Func _Fail($sMessage)
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
    Exit 1
EndFunc
