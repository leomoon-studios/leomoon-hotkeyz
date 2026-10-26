#include-once

#include "..\core\HotkeyModel.au3"

Func _ProcessActions_ExecuteMedia($sTarget)
    If Not _ProcessActions_IsMediaTarget($sTarget) Then Return SetError(1, 0, False)
    Send("{" & StringUpper(StringReplace($sTarget, " ", "_")) & "}")
    Return True
EndFunc

Func _ProcessActions_ExecuteCommand($sCommand, $sVerb)
    Return ShellExecute(@ComSpec, _ProcessActions_BuildCommandArguments($sCommand), "", $sVerb, @SW_HIDE)
EndFunc

Func _ProcessActions_IsMediaTarget($sTarget)
    Switch $sTarget
        Case "Volume Up", "Volume Down", "Volume Mute", "Media Play Pause", "Media Next", "Media Prev", "Media Stop"
            Return True
    EndSwitch
    Return False
EndFunc

Func _ProcessActions_QuoteArgument($sArgument)
    Return '"' & StringReplace($sArgument, '"', '""') & '"'
EndFunc

Func _ProcessActions_BuildCommandArguments($sCommand)
    Return "/d /c " & $sCommand
EndFunc

Func _ProcessActions_ExecuteTarget($sTarget, $sParameters, $sVerb, $bSingleton)
    $sParameters = StringStripWS($sParameters, 7)
    If $bSingleton And ProcessExists(StringRegExpReplace($sTarget, "^.*\\", "")) Then Return True
    If $sParameters = "" Then Return ShellExecute($sTarget, "", "", $sVerb)
    If StringInStr($sParameters, "<GetActiveWindowsExplorerPath>") Then
        Local $sExplorerPath = _GetWindowsExplorerPath(WinGetHandle("[ACTIVE]"))
        If Not FileExists($sExplorerPath) Then Return ShellExecute($sTarget, "", "", $sVerb)
        $sParameters = StringReplace($sParameters, "<GetActiveWindowsExplorerPath>", _ProcessActions_QuoteArgument($sExplorerPath))
    EndIf
    Return ShellExecute($sTarget, $sParameters, "", $sVerb, @SW_HIDE)
EndFunc
