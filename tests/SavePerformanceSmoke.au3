#NoTrayIcon
; Desktop benchmark: isolated profile and simulated registrations. No timing
; threshold; verify all records round-trip and print comparable measurements.
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

Opt("MustDeclareVars", 1)
Opt("GUIOnEventMode", 1)
If FileExists($APP_INI_PATH) Or FileExists($APP_INI_PATH & ".bak") Or FileExists($APP_INI_PATH & ".tmp") Then Exit 2
OnAutoItExitRegister("_SavePerfCleanup")
_HotkeyRegistry_ConfigureHotkeyBackend("_SavePerfBinding")
Global $aTable = _HotkeyRepository_CreateTable(80), $aRecord, $i
Global $aMods[4] = ["^!", "^+", "!+", "^!+"]
For $i = 1 To 80
    $aRecord = _HotkeyModel_Create($aMods[Int(($i - 1) / 26)] & Chr(97 + Mod($i - 1, 26)), $HOTKEY_ACTION_TEXT, "example " & $i)
    If Mod($i, 2) = 0 Then $aRecord[$HOTKEY_FIELD_CAPS_LOCK] = $HOTKEY_LOCK_ON
    _HotkeyRepository_SetRecord($aTable, $i, $aRecord)
Next
IniWrite($APP_INI_PATH, "Options", "Main", "^!+{F11}")
Global $hTimer = TimerInit()
If Not _HotkeyRepository_Save($APP_INI_PATH, $aTable) Then Exit 3
ConsoleWrite("Repository save (80 mixed hotkeys): " & Round(TimerDiff($hTimer)) & " ms" & @CRLF)
$hTimer = TimerInit()
_mainGui()
ConsoleWrite("Open Settings (80 hotkeys): " & Round(TimerDiff($hTimer)) & " ms" & @CRLF)
$hTimer = TimerInit()
_addBtn()
ConsoleWrite("Open Add: " & Round(TimerDiff($hTimer)) & " ms" & @CRLF)
If Not WinActive($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then Exit 7
_hideChild()
$hTimer = TimerInit()
_editBtn()
ConsoleWrite("Open Edit: " & Round(TimerDiff($hTimer)) & " ms" & @CRLF)
If Not WinActive($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then Exit 8
Global $aEdited = _HotkeyEditor_ReadRecord()
If Not IsArray($aEdited) Then Exit 9
For $i = 0 To $HOTKEY_FIELD_COUNT - 1
    If $aEdited[$i] <> $aTable[1][$i] Then Exit 10
Next
_hideChild()
$hTimer = TimerInit()
If Not _MainWindow_IsHotkeyLayoutValid() Then Exit 4
ConsoleWrite("Main layout validation: " & Round(TimerDiff($hTimer)) & " ms" & @CRLF)
$hTimer = TimerInit()
If Not _guiToIni($APP_INI_PATH) Then Exit 5
ConsoleWrite("Main-window save: " & Round(TimerDiff($hTimer)) & " ms" & @CRLF)
Global $aReloaded = _HotkeyRepository_Load($APP_INI_PATH)
If Not _HotkeyRepository_TablesEqual($aTable, $aReloaded) Then Exit 6
ConsoleWrite("PASSED: 80 mixed hotkeys survive main-window save" & @CRLF)
Func _SavePerfBinding($sKey, $sHandler)
    #forceref $sKey, $sHandler
    Return True
EndFunc
Func _SavePerfCleanup()
    If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    FileDelete($APP_INI_PATH)
    FileDelete($APP_INI_PATH & ".bak")
    FileDelete($APP_INI_PATH & ".tmp")
EndFunc
