#include "..\src\resources\ExtMsgBox.au3"
#include "..\src\core\AppConstants.au3"
#include "..\src\core\ActionCatalog.au3"
#include "..\src\core\HotkeyRepository.au3"
#include "..\src\gui\GuiState.au3"
#include "..\src\actions\TextActions.au3"
#include "..\src\actions\SystemActions.au3"
#include "..\src\actions\WindowActions.au3"
#include "..\src\actions\ProcessActions.au3"
#include "..\src\actions\ActionDispatcher.au3"
#include "..\src\app\HotkeyRegistry.au3"
#include "..\src\app\TrayController.au3"
#include "..\src\gui\HotkeyEditor.au3"
#include "..\src\gui\MainWindow.au3"
#include "..\src\app\Application.au3"

Opt("MustDeclareVars", 1)

Global $g_iSmokeRegistryCalls = 0
Global $g_iSmokeTrayCalls = 0
Global $g_sSmokeIniPath = ""

If Not _Application_Compose("smoke-test.ini", "_SmokeRegistryInitializer", "_SmokeTrayInitializer") Then
    ConsoleWrite("FAIL: application composition returned false" & @CRLF)
    Exit 1
EndIf
If $g_iSmokeRegistryCalls <> 1 Or $g_iSmokeTrayCalls <> 1 Then
    ConsoleWrite("FAIL: composition did not invoke both test doubles exactly once" & @CRLF)
    Exit 1
EndIf
If $g_sSmokeIniPath <> "smoke-test.ini" Then
    ConsoleWrite("FAIL: composition did not pass the configured INI path" & @CRLF)
    Exit 1
EndIf

If Not _strCompare("HotKeyz", "HotKeyz") Or Not _almostEqual(10, 12, 0, 5) Then
    ConsoleWrite("FAIL: loaded module helpers did not return expected values" & @CRLF)
    Exit 1
EndIf

Global $aIncompleteSpecial = _HotkeyEditor_ResolveSpecial("", "Empty Clipboard")
Global $iSpecialError = @error
If IsArray($aIncompleteSpecial) Or $iSpecialError = 0 Then
    ConsoleWrite("FAIL: incomplete special action must retain its decoding error" & @CRLF)
    Exit 1
EndIf
Global $i, $aSpecial
For $i = 0 To UBound($sPaths, 1) - 1
    $aSpecial = _HotkeyEditor_ResolveSpecial("^!a", $sPaths[$i][0])
    If @error Or Not IsArray($aSpecial) Then
        ConsoleWrite("FAIL: special action could not be decoded: " & $sPaths[$i][0] & @CRLF)
        Exit 1
    EndIf
Next

ConsoleWrite("PASSED: noninteractive module composition and special-action smoke test" & @CRLF)
Exit 0

Func _SmokeRegistryInitializer($sIniFile)
    $g_iSmokeRegistryCalls += 1
    $g_sSmokeIniPath = $sIniFile
    Return True
EndFunc

Func _SmokeTrayInitializer($sIniFile)
    $g_iSmokeTrayCalls += 1
    $g_sSmokeIniPath = $sIniFile
    Return True
EndFunc
