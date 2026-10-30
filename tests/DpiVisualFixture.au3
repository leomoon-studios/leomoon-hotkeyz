#NoTrayIcon
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
Opt("GUIOnEventMode", 1)
If $CmdLine[0] < 1 Or Not FileExists($CmdLine[1]) Then Exit 2
If FileExists($APP_INI_PATH) Or FileExists($APP_INI_PATH & ".bak") Or FileExists($APP_INI_PATH & ".tmp") Then Exit 3
Global $g_sDpiSignalDir = $CmdLine[1], $g_bDpiOwnProfile = True
OnAutoItExitRegister("_DpiVisualCleanup")
If $CmdLine[0] >= 2 And $CmdLine[2] = "gdi" Then
    If Not _Application_EnableGdiScaling() Then Exit 6
EndIf
IniWrite($APP_INI_PATH, "Options", "Main", "^!+{F11}")
_mainGui()
_DpiVisualCapture("settings", $g_aGuiState[$GUI_STATE_MAIN_WINDOW])
GUICtrlCreateListViewItem("File|Ctrl + Alt + F1|C:\Example\A long folder name\A long application name.exe|Admin, Ctrl: Left, Caps: On", $g_aGuiState[$GUI_STATE_LIST_VIEW])
_GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], 0)
_DpiVisualCapture("settings-populated", $g_aGuiState[$GUI_STATE_MAIN_WINDOW])
_addBtn()
Global $aDpiNames[6] = ["program", "folder", "system", "window", "url", "text"], $i
For $i = 0 To 5
    _GUICtrlComboBox_SetCurSel($g_iEditorActionSelector, $i)
    _HotkeyEditor_ActionChanged()
    _DpiVisualCapture("editor-" & $aDpiNames[$i], $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
Next
_GUICtrlComboBox_SetCurSel($g_iEditorActionSelector, 0)
_HotkeyEditor_ActionChanged()
GUICtrlSetState($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX], $GUI_CHECKED)
_cmdCbox()
_DpiVisualCapture("editor-command", $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
_GUICtrlComboBox_SetCurSel($g_iEditorActionSelector, 3)
_HotkeyEditor_ActionChanged()
_GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_WINDOW_COMBO], $ACTION_CATALOG_CUSTOM_WINDOW)
_windowDown()
_DpiVisualCapture("editor-geometry", $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX], $GUI_CHECKED)
GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_ALT_CHECKBOX], $GUI_CHECKED)
GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_SHIFT_CHECKBOX], $GUI_CHECKED)
GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_WIN_CHECKBOX], $GUI_CHECKED)
For $i = 0 To 6
    $g_aEditorRestrictions[$i] = 1
Next
_HotkeyEditor_UpdateOkState()
_DpiVisualCapture("editor-conditions-summary", $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
_GUICtrlComboBox_SetCurSel($g_iEditorActionSelector, 2)
_HotkeyEditor_ActionChanged()
_GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_SPECIAL_COMBO], $OPTICAL_ACTION_OPEN)
_HotkeyEditor_SpecialChanged()
_DpiVisualCapture("editor-optical", $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
_HotkeyEditor_ShowRestrictions()
_DpiVisualCapture("conditions", $g_hRestrictionDialog)
_HotkeyEditor_RestrictionsCancel()
_hideChild()
_AppWarning_ReportNonBlocking("A shortcut could not be registered. Windows or another application may be using it." & @CRLF & "Open Settings to choose another shortcut.")
_DpiVisualCapture("warning", $g_hWarningWindow)
_AppWarning_Close()
ConsoleWrite("PASSED: DPI visual fixture" & @CRLF)
Func _DpiVisualCapture($sName, $hWindow)
    WinActivate($hWindow)
    Sleep(100)
    If Not FileWrite($g_sDpiSignalDir & "\" & $sName & ".ready", String($hWindow)) Then Exit 4
    Local $hTimer = TimerInit()
    While Not FileExists($g_sDpiSignalDir & "\" & $sName & ".done") And TimerDiff($hTimer) < 20000
        Sleep(20)
    WEnd
    If Not FileExists($g_sDpiSignalDir & "\" & $sName & ".done") Then Exit 5
EndFunc
Func _DpiVisualCleanup()
    If IsHWnd($g_hRestrictionDialog) Then GUIDelete($g_hRestrictionDialog)
    If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    _AppWarning_Close()
    If $g_bDpiOwnProfile Then FileDelete($APP_INI_PATH)
EndFunc
