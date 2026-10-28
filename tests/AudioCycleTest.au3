#include "..\src\actions\AudioDeviceActions.au3"

Opt("MustDeclareVars", 1)

Global $g_iMode = 0
Global $g_sCurrent = "first"
Global $g_sSelected = ""
Global $g_iNotifications = 0
Global $g_iSetCalls = 0
Global $g_iFlowSeen = -1
Global $g_bFailDefault = False
Global $g_bFailSet = False

Global $sResult = _AudioDeviceActions_Cycle($AUDIO_FLOW_RENDER, "_MockEnumerate", "_MockDefault", "_MockSet", "_MockNotify")
Global $iError = @error
_Assert($sResult = "" And $iError = $AUDIO_DEVICE_ERROR_NO_ENDPOINTS, "zero endpoints return an error")
_Assert($g_iSetCalls = 0 And $g_iNotifications = 0, "zero endpoints have no side effects")

$g_iMode = 1
_Assert(_AudioDeviceActions_Cycle($AUDIO_FLOW_CAPTURE, "_MockEnumerate", "_MockDefault", "_MockSet", "_MockNotify") = "First", "one endpoint returns its name")
_Assert($g_iSetCalls = 0 And $g_iNotifications = 0, "one endpoint is not changed or announced")

$g_iMode = 2
_Assert(_AudioDeviceActions_Cycle($AUDIO_FLOW_RENDER, "_MockEnumerate", "_MockDefault", "_MockSet", "_MockNotify") = "Second", "next endpoint is chosen")
_Assert($g_sSelected = "second" And $g_iNotifications = 1 And $g_iFlowSeen = $AUDIO_FLOW_RENDER, "playback switch and notification use the right flow")

$g_sCurrent = "second"
_Assert(_AudioDeviceActions_Cycle($AUDIO_FLOW_CAPTURE, "_MockEnumerate", "_MockDefault", "_MockSet", "_MockNotify") = "First", "last endpoint wraps to first")
_Assert($g_sSelected = "first" And $g_iNotifications = 2 And $g_iFlowSeen = $AUDIO_FLOW_CAPTURE, "recording switch and notification use the right flow")

$g_sCurrent = "disconnected"
_Assert(_AudioDeviceActions_Cycle($AUDIO_FLOW_RENDER, "_MockEnumerate", "_MockDefault", "_MockSet", "_MockNotify") = "First", "unknown default selects first active endpoint")

$g_bFailDefault = True
$sResult = _AudioDeviceActions_Cycle($AUDIO_FLOW_RENDER, "_MockEnumerate", "_MockDefault", "_MockSet", "_MockNotify")
$iError = @error
_Assert($sResult = "" And $iError = $AUDIO_DEVICE_ERROR_DEFAULT, "default lookup failure propagates")
$g_bFailDefault = False

$g_bFailSet = True
Global $iBeforeNotifications = $g_iNotifications
$sResult = _AudioDeviceActions_Cycle($AUDIO_FLOW_RENDER, "_MockEnumerate", "_MockDefault", "_MockSet", "_MockNotify")
$iError = @error
_Assert($sResult = "" And $iError = $AUDIO_DEVICE_ERROR_POLICY, "switch failure propagates")
_Assert($g_iNotifications = $iBeforeNotifications, "failed switch does not notify")

ConsoleWrite("PASSED: audio cycling selection and failure cases" & @CRLF)
Exit 0

Func _MockEnumerate($iFlow)
    $g_iFlowSeen = $iFlow
    If $g_iMode = 0 Then Return 0
    If $g_iMode = 1 Then
        Local $aOne[1][2] = [["first", "First"]]
        Return $aOne
    EndIf
    Local $aTwo[2][2] = [["first", "First"], ["second", "Second"]]
    Return $aTwo
EndFunc

Func _MockDefault($iFlow)
    $g_iFlowSeen = $iFlow
    If $g_bFailDefault Then Return SetError($AUDIO_DEVICE_ERROR_DEFAULT, 0, "")
    Return $g_sCurrent
EndFunc

Func _MockSet($sId)
    $g_iSetCalls += 1
    If $g_bFailSet Then Return SetError($AUDIO_DEVICE_ERROR_POLICY, 0, False)
    $g_sSelected = $sId
    Return True
EndFunc

Func _MockNotify($iFlow, $sName)
    #forceref $sName
    $g_iFlowSeen = $iFlow
    $g_iNotifications += 1
EndFunc

Func _Assert($bCondition, $sMessage)
    If $bCondition Then Return
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
    Exit 1
EndFunc
