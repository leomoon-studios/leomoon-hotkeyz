#include-once
#include "..\core\InputSend.au3"

#include "..\core\HotkeyModel.au3"

Global $g_sShellExecuteHandler = "_ProcessActions_ShellExecuteNative"

Func _ProcessActions_ConfigureShellBackend($sHandler)
    $g_sShellExecuteHandler = $sHandler
EndFunc

Func _ProcessActions_ResetShellBackend()
    $g_sShellExecuteHandler = "_ProcessActions_ShellExecuteNative"
EndFunc

Func _ProcessActions_ExecuteMedia($sTarget)
    If Not _ProcessActions_IsMediaTarget($sTarget) Then Return SetError(1, 0, False)
    _InputSend_Keys("{" & StringUpper(StringReplace($sTarget, " ", "_")) & "}")
    Return True
EndFunc

Func _ProcessActions_ExecuteCommand($sCommand, $sVerb)
    Return _ProcessActions_ShellExecute(@ComSpec, _ProcessActions_BuildCommandArguments($sCommand), "", $sVerb, @SW_HIDE)
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

Func _ProcessActions_FileWorkingDirectory($sTarget)
    ; Bare commands, URLs, and shell names are resolved by Windows as before.
    If Not StringRegExp($sTarget, "(?i)^(?:[a-z]:[\\/]|\\\\)") Then Return ""
    Local $sPath = StringReplace($sTarget, "/", "\")
    Local $iLastSeparator = StringInStr($sPath, "\", 0, -1)
    If $iLastSeparator = 3 And StringMid($sPath, 2, 1) = ":" Then Return StringLeft($sPath, 3)
    If $iLastSeparator > 0 Then Return StringLeft($sPath, $iLastSeparator - 1)
    Return ""
EndFunc

Func _ProcessActions_ExecuteTarget($sTarget, $sParameters, $sVerb, $bSingleton, $bFileTarget = False)
    $sParameters = StringStripWS($sParameters, 7)
    Local $sWorkingDirectory = ""
    If $bFileTarget Then $sWorkingDirectory = _ProcessActions_FileWorkingDirectory($sTarget)
    If $bSingleton And ProcessExists(StringRegExpReplace($sTarget, "^.*\\", "")) Then Return True
    If $sParameters = "" Then Return _ProcessActions_ShellExecute($sTarget, "", $sWorkingDirectory, $sVerb)
    If StringInStr($sParameters, "<GetActiveWindowsExplorerPath>") Then
        Local $sExplorerPath = _GetWindowsExplorerPath(WinGetHandle("[ACTIVE]"))
        Local $iExplorerError = @error
        If $iExplorerError Or Not FileExists($sExplorerPath) Then Return SetError(2, $iExplorerError, False)
        $sParameters = StringReplace($sParameters, "<GetActiveWindowsExplorerPath>", _ProcessActions_QuoteArgument($sExplorerPath))
    EndIf
    Return _ProcessActions_ShellExecute($sTarget, $sParameters, $sWorkingDirectory, $sVerb, @SW_HIDE)
EndFunc

Func _ProcessActions_ShellExecute($sTarget, $sParameters = "", $sWorkingDirectory = "", $sVerb = "", $iShowFlag = @SW_SHOWNORMAL)
    Local $vResult = Call($g_sShellExecuteHandler, $sTarget, $sParameters, $sWorkingDirectory, $sVerb, $iShowFlag)
    If @error Or Not $vResult Then Return SetError(1, @error, False)
    Return True
EndFunc

Func _ProcessActions_ShellExecuteNative($sTarget, $sParameters, $sWorkingDirectory, $sVerb, $iShowFlag)
    Local $iPid = ShellExecute($sTarget, $sParameters, $sWorkingDirectory, $sVerb, $iShowFlag)
    If @error Or $iPid = 0 Then Return SetError(1, @error, False)
    Return True
EndFunc
