#include-once

#include "..\resources\ExtMsgBox.au3"

Global $g_sLastApplicationError = ""

Func _AppError_Report($sContext, $iError = 1, $iExtended = 0, $bShowMessage = True)
    $g_sLastApplicationError = $sContext & " (error " & $iError & ", detail " & $iExtended & ")"
    ConsoleWrite("ERROR: " & $g_sLastApplicationError & @CRLF)
    If $bShowMessage Then _ExtMsgBox(48, "OK", "LeoMoon HotKeyz error", $g_sLastApplicationError, 0)
    Return SetError($iError, $iExtended, False)
EndFunc
