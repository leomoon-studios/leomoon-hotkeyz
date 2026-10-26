#include-once

#include "..\core\HotkeyModel.au3"

Func _ProcessActions_ExecuteMedia($sTarget)
    If Not _isKnownSpecialAction($HOTKEY_ACTION_MEDIA, $sTarget) Then Return SetError(1, 0, False)
    Send("{" & StringUpper(StringReplace($sTarget, " ", "_")) & "}")
    Return True
EndFunc

Func _ProcessActions_ExecuteCommand($sCommand, $sVerb)
    Return ShellExecute(@ComSpec, " /k " & $sCommand, "", $sVerb, @SW_HIDE)
EndFunc

Func _ProcessActions_ExecuteTarget($sTarget, $sParameters, $sVerb, $bSingleton)
    $sParameters = StringStripWS($sParameters, 7)
    If $bSingleton And ProcessExists(StringRegExpReplace($sTarget, "^.*\\", "")) Then Return True
    If $sParameters = "" Then Return ShellExecute($sTarget, "", "", $sVerb)
    If StringInStr($sParameters, "<GetActiveWindowsExplorerPath>") Then
        Local $sExplorerPath = _GetWindowsExplorerPath(WinGetHandle("[ACTIVE]"))
        If Not FileExists($sExplorerPath) Then Return ShellExecute($sTarget, "", "", $sVerb)
        $sParameters = StringReplace($sParameters, "<GetActiveWindowsExplorerPath>", $sExplorerPath)
    EndIf
    Return ShellExecute($sTarget, $sParameters, "", $sVerb, @SW_HIDE)
EndFunc
