#NoTrayIcon
; Captures test windows only. Refuses to overwrite an existing test INI.
#include <ScreenCapture.au3>
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
Global $g_sCaptureDir = @ScriptDir & "\..\build\visual-ui-baseline", $g_bOwnProfile = False
If $CmdLine[0] Then $g_sCaptureDir = $CmdLine[1]
If FileExists($APP_INI_PATH) Or FileExists($APP_INI_PATH & ".bak") Or FileExists($APP_INI_PATH & ".tmp") Then Exit 2
If Not DirCreate($g_sCaptureDir) Then Exit 3
OnAutoItExitRegister("_BaselineCleanup")
$g_bOwnProfile = True
IniWrite($APP_INI_PATH, "Options", "Main", "^!+{F11}")
Global $hTime = TimerInit()
_mainGui()
ConsoleWrite("Settings empty open ms=" & Round(TimerDiff($hTime)) & @CRLF)
If BitAND(GUICtrlGetState($g_iMainEditButton), $GUI_ENABLE) Or BitAND(GUICtrlGetState($g_iMainDeleteButton), $GUI_ENABLE) Then Exit 6
If Not StringInStr(GUICtrlRead($g_iMainListHint), "No hotkeys") Then Exit 7
_BaselineCapture("settings-empty", $g_aGuiState[$GUI_STATE_MAIN_WINDOW])
Global $aRows[6] = ["File|Ctrl + Alt + F1|C:\Example\A long folder name\A long application name.exe|Admin, Ctrl: Left, Caps: On", "Folder|Ctrl + Alt + F2|C:\Example\Documents|", "System|Ctrl + Alt + F3|" & $sPaths[0][0] & "|", "Window|Ctrl + Alt + F4|Close|", "URL|Ctrl + Alt + F5|https://example.com|", "Text|Ctrl + Alt + F6|Example text|"]
Global $i
For $i = 0 To 5
    GUICtrlCreateListViewItem($aRows[$i], $g_aGuiState[$GUI_STATE_LIST_VIEW])
Next
_GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], 0)
If Not BitAND(GUICtrlGetState($g_iMainEditButton), $GUI_ENABLE) Or Not BitAND(GUICtrlGetState($g_iMainDeleteButton), $GUI_ENABLE) Then Exit 8
_GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, False)
If BitAND(GUICtrlGetState($g_iMainEditButton), $GUI_ENABLE) Or BitAND(GUICtrlGetState($g_iMainDeleteButton), $GUI_ENABLE) Then Exit 9
_GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], 0)
_BaselineCapture("settings-populated", $g_aGuiState[$GUI_STATE_MAIN_WINDOW])
; Exercise the real list window with synthetic mouse and keyboard input.
WinActivate($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
ControlFocus($g_aGuiState[$GUI_STATE_MAIN_WINDOW], "", $g_aGuiState[$GUI_STATE_STARTUP_CHECKBOX])
Send("{TAB}")
Sleep(100)
If ControlGetHandle($g_aGuiState[$GUI_STATE_MAIN_WINDOW], "", ControlGetFocus($g_aGuiState[$GUI_STATE_MAIN_WINDOW])) <> GUICtrlGetHandle($g_aGuiState[$GUI_STATE_CTRL_CHECKBOX]) Then Exit 10
ControlFocus($g_aGuiState[$GUI_STATE_MAIN_WINDOW], "", $g_aGuiState[$GUI_STATE_LIST_VIEW])
_GUICtrlListView_SetItemFocused($g_aGuiState[$GUI_STATE_LIST_VIEW], 0)
Send("{DOWN}")
Sleep(100)
If _HotkeyEditor_SelectedIndex() <> 1 Then Exit 11
If Not ControlClick($g_aGuiState[$GUI_STATE_MAIN_WINDOW], "", $g_aGuiState[$GUI_STATE_LIST_VIEW], "left", 2, 35, 30) Then Exit 12
Sleep(300)
If Not IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then Exit 13
_hideChild()
Global $sOriginal = _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 2)
Global $aHeaderPos = WinGetPos(_GUICtrlListView_GetHeader($g_aGuiState[$GUI_STATE_LIST_VIEW]))
Global $iDivider = $aHeaderPos[0] + _GUICtrlListView_GetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 0) + _GUICtrlListView_GetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 1) + _GUICtrlListView_GetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 2)
MouseClickDrag("left", $iDivider, $aHeaderPos[1] + 10, $iDivider + 150, $aHeaderPos[1] + 10, 5)
If _GUICtrlListView_GetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 2) < 350 Then Exit 16
Global $aBefore = _GUICtrlListView_GetSubItemRect($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 2)
_GUICtrlListView_Scroll($g_aGuiState[$GUI_STATE_LIST_VIEW], 450, 0)
Global $aAfter = _GUICtrlListView_GetSubItemRect($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 2)
If $aAfter[0] >= $aBefore[0] Or _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 2) <> $sOriginal Then Exit 14
_GUICtrlListView_Scroll($g_aGuiState[$GUI_STATE_LIST_VIEW], -1000, 0)
_GUICtrlListView_SetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 2, 255)
ConsoleWrite("Settings input: tab, list keyboard selection, double-click, column drag and horizontal scroll passed" & @CRLF)
_addBtn()
WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
GUICtrlSetData($g_aGuiState[$GUI_STATE_FILE_INPUT], "C:\Example\test.exe")
GUICtrlSetState($g_aGuiState[$GUI_STATE_ADMIN_CHECKBOX], $GUI_CHECKED)
ControlFocus($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], "", $g_iEditorActionSelector)
Send("{END}")
Sleep(150)
If GUICtrlRead($g_aGuiState[$GUI_STATE_TEXT_RADIO]) <> $GUI_CHECKED Or Not BitAND(GUICtrlGetState($g_aGuiState[$GUI_STATE_TEXT_EDIT]), $GUI_SHOW) Then Exit 17
Send("{HOME}")
Sleep(150)
If GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_RADIO]) <> $GUI_CHECKED Or Not BitAND(GUICtrlGetState($g_aGuiState[$GUI_STATE_FILE_INPUT]), $GUI_SHOW) Then Exit 18
If GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_INPUT]) <> "C:\Example\test.exe" Or BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_ADMIN_CHECKBOX]), $GUI_CHECKED) Then Exit 19
_hideChild()
ConsoleWrite("Editor input: action selector keyboard switching passed" & @CRLF)
Global $aNames[6] = ["file", "folder", "system", "window", "url", "text"]
Global $aRadios[6] = [$GUI_STATE_FILE_RADIO, $GUI_STATE_FOLDER_RADIO, $GUI_STATE_SPECIAL_RADIO, $GUI_STATE_WINDOW_RADIO, $GUI_STATE_URL_RADIO, $GUI_STATE_TEXT_RADIO]
Global $aHandlers[6] = ["_fileRdo", "_folderRdo", "_specialRdo", "_windowRdo", "_urlRdo", "_txtRdo"]
Global $aInputs[6] = [$GUI_STATE_FILE_INPUT, $GUI_STATE_FOLDER_INPUT, $GUI_STATE_SPECIAL_COMBO, $GUI_STATE_WINDOW_COMBO, $GUI_STATE_URL_INPUT, $GUI_STATE_TEXT_EDIT]
Global $aExpected[6] = ["C:\Example\A long folder name\A long application name.exe", "C:\Example\Documents", $sPaths[0][0], "Close", "example.com", "Example text"]
For $i = 0 To 5
    $hTime = TimerInit()
    _addBtn()
    If $i = 0 Then ConsoleWrite("Add open ms=" & Round(TimerDiff($hTime)) & @CRLF)
    If $i <> 0 Then GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_RADIO], $GUI_UNCHECKED)
    GUICtrlSetState($g_aGuiState[$aRadios[$i]], $GUI_CHECKED)
    Call($aHandlers[$i])
    _BaselineCapture("add-" & $aNames[$i], $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    If $i = 0 Then
        _HotkeyEditor_ShowRestrictions()
        _BaselineCapture("conditions", $g_hRestrictionDialog)
        _HotkeyEditor_RestrictionsCancel()
    EndIf
    _hideChild()
    _GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], -1, False)
    _GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], $i)
    $hTime = TimerInit()
    _editBtn()
    If $i = 0 Then ConsoleWrite("Edit open ms=" & Round(TimerDiff($hTime)) & @CRLF)
    If GUICtrlRead($g_aGuiState[$aRadios[$i]]) <> $GUI_CHECKED Or _GUICtrlComboBox_GetCurSel($g_iEditorActionSelector) <> $i Then Exit 21
    If GUICtrlRead($g_aGuiState[$aInputs[$i]]) <> $aExpected[$i] Then Exit 22
    _BaselineCapture("edit-" & $aNames[$i], $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    _hideChild()
Next
_AppWarning_ReportNonBlocking("These hotkeys could not be registered. Windows or another application may own them:" & @CRLF & "- Ctrl + Alt + F1" & @CRLF & "- Ctrl + Alt + F2")
_BaselineCapture("warning", $g_hWarningWindow)
_AppWarning_Close()
_guiDel()
$g_sMainWorkAreaHandler = "_BaselineSmallArea"
_mainGui()
Global $aSmallClient = WinGetClientSize($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
Global $aSmallSave = ControlGetPos($g_aGuiState[$GUI_STATE_MAIN_WINDOW], "", $g_aGuiState[$GUI_STATE_SAVE_BUTTON])
Global $aSmallList = ControlGetPos($g_aGuiState[$GUI_STATE_MAIN_WINDOW], "", $g_aGuiState[$GUI_STATE_LIST_VIEW])
If $aSmallSave[0] + $aSmallSave[2] > $aSmallClient[0] Or $aSmallSave[1] + $aSmallSave[3] > $aSmallClient[1] Or $aSmallList[1] + $aSmallList[3] > $aSmallSave[1] Then Exit 15
_BaselineCapture("settings-small-workarea", $g_aGuiState[$GUI_STATE_MAIN_WINDOW])
ConsoleWrite("Simulated work area: 520x420; list and footer fit" & @CRLF)
_guiDel()
$g_sMainWorkAreaHandler = "_BaselineMinimumArea"
_mainGui()
_addBtn()
Global $aSmallEditor = WinGetClientSize($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
Global $aSmallOk = ControlGetPos($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], "", $g_aGuiState[$GUI_STATE_EDITOR_OK_BUTTON])
If $aSmallOk[0] + $aSmallOk[2] > $aSmallEditor[0] Or $aSmallOk[1] + $aSmallOk[3] > $aSmallEditor[1] Then Exit 20
_BaselineCapture("editor-small-workarea", $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
_hideChild()
ConsoleWrite("Simulated work area: 500x380; editor footer fits" & @CRLF)
ConsoleWrite("Desktop=" & @DesktopWidth & "x" & @DesktopHeight & @CRLF)
Func _BaselineSmallArea()
    Return _MainWindow_SizeForWorkArea(520, 420)
EndFunc
Func _BaselineMinimumArea()
    Return _MainWindow_SizeForWorkArea(500, 380)
EndFunc
Func _BaselineCapture($sName, $hWindow)
    If Not IsHWnd($hWindow) Then Exit 4
    WinActivate($hWindow)
    Sleep(200)
    Local $aPos = WinGetPos($hWindow), $aClient = WinGetClientSize($hWindow)
    ConsoleWrite($sName & ": outer=" & $aPos[2] & "x" & $aPos[3] & ", client=" & $aClient[0] & "x" & $aClient[1] & @CRLF)
    If Not _ScreenCapture_CaptureWnd($g_sCaptureDir & "\" & $sName & ".png", $hWindow) Then Exit 5
EndFunc
Func _BaselineCleanup()
    If $g_bOwnProfile Then FileDelete($APP_INI_PATH)
    If IsHWnd($g_hRestrictionDialog) Then GUIDelete($g_hRestrictionDialog)
    If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    _AppWarning_Close()
EndFunc
