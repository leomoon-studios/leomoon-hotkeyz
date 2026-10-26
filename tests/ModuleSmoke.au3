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

ConsoleWrite("PASSED: noninteractive module composition smoke test" & @CRLF)
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
