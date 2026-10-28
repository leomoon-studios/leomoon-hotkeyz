#NoTrayIcon
; Interactive test: creates a temporary INI beside this script and registers
; test hotkeys. It never changes the Windows startup registry value.
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
Opt("GUICloseOnESC", 0)

Global $g_bAudioEditorOwnsIni = False
If FileExists($APP_INI_PATH) Or FileExists($APP_INI_PATH & ".bak") Or FileExists($APP_INI_PATH & ".tmp") Then
    ConsoleWrite("FAIL: refusing to overwrite an existing test-folder profile" & @CRLF)
    Exit 1
EndIf
OnAutoItExitRegister("_AudioEditorCleanup")
$g_bAudioEditorOwnsIni = True
If Not IniWrite($APP_INI_PATH, "Options", "Main", "^!+{F11}") Then _AudioEditorFail("could not create temporary profile")
_mainGui()
_AudioEditorAdd("Cycle Playback Device", "F9")
_AudioEditorAdd("Cycle Recording Device", "F10")
If _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) <> 2 Then _AudioEditorFail("editor did not add both actions")
If Not _guiToIni($APP_INI_PATH) Then _AudioEditorFail("could not apply and save settings: " & @error & ", detail=" & @extended)
Global $aSaved = _HotkeyRepository_Load($APP_INI_PATH)
If Not IsArray($aSaved) Or _HotkeyRepository_Count($aSaved) <> 2 Then _AudioEditorFail("saved profile did not reload both actions")
If $aSaved[1][$HOTKEY_FIELD_TARGET] <> "Cycle Playback Device" Or $aSaved[2][$HOTKEY_FIELD_TARGET] <> "Cycle Recording Device" Then _AudioEditorFail("saved action names changed")
_guiDel()
_mainGui()
If _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) <> 2 Then _AudioEditorFail("reopened Settings did not show both actions")
If _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 0) <> "System" Or _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 1, 0) <> "System" Then _AudioEditorFail("reopened entries are not system actions")
If _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 2) <> "Cycle Playback Device" Or _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 1, 2) <> "Cycle Recording Device" Then _AudioEditorFail("reopened Settings changed action labels")
ConsoleWrite("PASSED: audio action selection, hotkey assignment, save, and Settings reload" & @CRLF)
Exit 0

Func _AudioEditorAdd($sAction, $sKey)
    _addBtn()
    GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_RADIO], $GUI_UNCHECKED)
    GUICtrlSetState($g_aGuiState[$GUI_STATE_SPECIAL_RADIO], $GUI_CHECKED)
    _specialRdo()
    If _GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_SPECIAL_COMBO], $sAction) = -1 Then _AudioEditorFail("editor does not list " & $sAction)
    GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX], $GUI_CHECKED)
    GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_ALT_CHECKBOX], $GUI_CHECKED)
    GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_SHIFT_CHECKBOX], $GUI_CHECKED)
    If _GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO], $sKey) = -1 Then _AudioEditorFail("editor does not list test key " & $sKey)
    If Not _add() Then _AudioEditorFail("could not add " & $sAction)
EndFunc

Func _AudioEditorCleanup()
    _HotkeyRegistry_TrySet("^!+{F9}")
    _HotkeyRegistry_TrySet("^!+{F10}")
    _HotkeyRegistry_TrySet("^!+{F11}")
    If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    If $g_bAudioEditorOwnsIni Then
        FileDelete($APP_INI_PATH)
        FileDelete($APP_INI_PATH & ".bak")
        FileDelete($APP_INI_PATH & ".tmp")
    EndIf
EndFunc

Func _AudioEditorFail($sMessage)
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
    Exit 1
EndFunc
