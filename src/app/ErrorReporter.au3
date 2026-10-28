#include-once

#include "..\resources\ExtMsgBox.au3"
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <WindowsConstants.au3>

Global $g_sLastApplicationError = ""

Func _AppError_Report($sContext, $iError = 1, $iExtended = 0, $bShowMessage = True)
    $g_sLastApplicationError = $sContext & " (error " & $iError & ", detail " & $iExtended & ")"
    ConsoleWrite("ERROR: " & $g_sLastApplicationError & @CRLF)
    If $bShowMessage Then _ExtMsgBox(48, "OK", "LeoMoon HotKeyz error", $g_sLastApplicationError, 0)
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
