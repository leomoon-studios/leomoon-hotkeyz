#include-once

; Suppression is limited to the synchronous Send operation. Windows does not
; identify the injecting process, so concurrent external injected input during
; this short operation is suppressed too. Physical observer events still queue.
Global $g_bInputSending = False

Func _InputSend_Keys($sKeys)
    Local $bWasSending = $g_bInputSending
    $g_bInputSending = True
    Local $iResult = Send($sKeys), $iError = @error, $iExtended = @extended
    $g_bInputSending = $bWasSending
    Return SetError($iError, $iExtended, $iResult)
EndFunc
