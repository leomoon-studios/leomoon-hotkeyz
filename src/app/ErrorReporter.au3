#include-once

#include "..\resources\ExtMsgBox.au3"
#include "Notification.au3"
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <WindowsConstants.au3>

Global $g_sLastApplicationError = ""
Global $g_bStartupWarningsDeferred = False, $g_sStartupUnavailable = ""

Func _AppWarning_BeginStartup()
    $g_sStartupUnavailable = ""
    $g_bStartupWarningsDeferred = True
EndFunc

Func _AppWarning_AddUnavailable($sLines)
    If $sLines = "" Then Return
    $g_sStartupUnavailable &= $sLines
    If Not $g_bStartupWarningsDeferred Then _AppWarning_FinishStartup()
EndFunc

Func _AppWarning_FinishStartup($bShow = True)
    $g_bStartupWarningsDeferred = False
    If $g_sStartupUnavailable = "" Then Return
    Local $sFull = "These hotkeys could not be registered. Windows or another application may own them, or their input settings could not be initialized:" & @CRLF & $g_sStartupUnavailable
    ConsoleWrite("WARNING: " & $sFull & @CRLF)
    If $bShow Then
        Local $sList = StringStripWS($g_sStartupUnavailable, 3), $sNotice
        If StringLen($sList) > 155 Then $sList = StringLeft($sList, 152) & "..."
        $sNotice = "Unavailable shortcuts:" & @CRLF & $sList & @CRLF & "Open Settings to change them."
        _Notification_Show("LeoMoon HotKeyz", $sNotice, 7, 2)
    EndIf
    $g_sStartupUnavailable = ""
EndFunc

Func _AppError_Report($sContext, $iError = 1, $iExtended = 0, $bShowMessage = True)
    $g_sLastApplicationError = $sContext & " (error " & $iError & ", detail " & $iExtended & ")"
    ConsoleWrite("ERROR: " & $g_sLastApplicationError & @CRLF)
    If $bShowMessage Then _ExtMsgBox(48, "OK", "LeoMoon HotKeyz error", $g_sLastApplicationError, 0)
    Return SetError($iError, $iExtended, False)
EndFunc

Func _AppError_Notify($sContext, $iError = 1, $iExtended = 0, $bShowMessage = True, $sNotice = Default)
    $g_sLastApplicationError = $sContext & " (error " & $iError & ", detail " & $iExtended & ")"
    ConsoleWrite("ERROR: " & $g_sLastApplicationError & @CRLF)
    If $bShowMessage Then
        If IsKeyword($sNotice) Then $sNotice = $sContext
        _Notification_Show("LeoMoon HotKeyz", $sNotice, 5, 3)
    EndIf
    Return SetError($iError, $iExtended, False)
EndFunc

Func _AppWarning_Report($sMessage)
    ConsoleWrite("WARNING: " & $sMessage & @CRLF)
    _ExtMsgBox(48, "OK", "LeoMoon HotKeyz", $sMessage, 0)
    Return True
EndFunc

Global $g_hWarningWindow = 0, $g_iWarningText = 0

Func _AppWarning_ReportNonBlocking($sMessage)
    ConsoleWrite("WARNING: " & $sMessage & @CRLF)
    If $g_hWarningWindow <> 0 Then
        GUICtrlSetData($g_iWarningText, GUICtrlRead($g_iWarningText) & @CRLF & @CRLF & $sMessage)
        Return True
    EndIf
    $g_hWarningWindow = GUICreate("LeoMoon HotKeyz", 500, 280)
    $g_iWarningText = GUICtrlCreateEdit($sMessage, 15, 15, 470, 210, BitOR($ES_READONLY, $ES_MULTILINE, $ES_AUTOVSCROLL, $WS_VSCROLL))
    Local $iClose = GUICtrlCreateButton("OK", 210, 240, 80, 25)
    GUISetOnEvent($GUI_EVENT_CLOSE, "_AppWarning_Close", $g_hWarningWindow)
    GUICtrlSetOnEvent($iClose, "_AppWarning_Close")
    GUISetState(@SW_SHOW, $g_hWarningWindow)
    Return True
EndFunc

Func _AppWarning_Close()
    If $g_hWarningWindow <> 0 Then GUIDelete($g_hWarningWindow)
    $g_hWarningWindow = 0
    $g_iWarningText = 0
EndFunc
