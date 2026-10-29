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
Global $g_bOwnProfile = False, $g_iTestDialog = 0
If FileExists($APP_INI_PATH) Or FileExists($APP_INI_PATH & ".bak") Or FileExists($APP_INI_PATH & ".tmp") Then Exit 2
OnAutoItExitRegister("_TestCleanup")
$g_bOwnProfile = True
IniWrite($APP_INI_PATH, "Options", "Main", "^!+{F11}")
_HotkeyRegistry_ConfigureHotkeyBackend("_TestBinding")
_mainGui()
_addBtn()
Global $aButtonRect = ControlGetPos($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], "", $g_aGuiState[$GUI_STATE_RESTRICTIONS_BUTTON])
Global $aEditorClient = WinGetClientSize($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
If Not IsArray($aButtonRect) Or Not IsArray($aEditorClient) Then _TestFail("cannot inspect conditions button layout")
If $aButtonRect[0] < 0 Or $aButtonRect[1] < 0 Or $aButtonRect[0] + $aButtonRect[2] > $aEditorClient[0] Or $aButtonRect[1] + $aButtonRect[3] > $aEditorClient[1] Then _TestFail("conditions button extends outside editor client area")
GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_RADIO], $GUI_UNCHECKED)
GUICtrlSetState($g_aGuiState[$GUI_STATE_TEXT_RADIO], $GUI_CHECKED)
GUICtrlSetData($g_aGuiState[$GUI_STATE_TEXT_EDIT], "example")
GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX], $GUI_CHECKED)
_GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO], "F9")
AdlibRegister("_TestDialog", 200)
ControlClick($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], "", $g_aGuiState[$GUI_STATE_RESTRICTIONS_BUTTON])
Global $hDialogWait = TimerInit()
While Not IsHWnd($g_hRestrictionDialog) And TimerDiff($hDialogWait) < 3000
    Sleep(10)
WEnd
If Not IsHWnd($g_hRestrictionDialog) Then _TestFail("button did not open the dialog")
Global $iDialogStyle = _WinAPI_GetWindowLong($g_hRestrictionDialog, $GWL_STYLE)
If Not BitAND($iDialogStyle, $WS_POPUP) Or BitAND($iDialogStyle, $WS_CHILD) Then _TestFail("conditions dialog is clipped as a child window")
While IsHWnd($g_hRestrictionDialog)
    Sleep(10)
WEnd
If $g_aEditorRestrictions[0] <> 1 Or $g_aEditorRestrictions[4] <> 1 Then _TestFail("dialog did not retain choices")
Global $aRecord = _HotkeyEditor_ReadRecord()
If Not IsArray($aRecord) Then _TestFail("editor did not produce record")
If $aRecord[$HOTKEY_FIELD_CTRL_SIDE] <> 1 Or $aRecord[$HOTKEY_FIELD_CAPS_LOCK] <> 1 Then _TestFail("record lost choices")
If Not _add() Then _TestFail("could not add restricted row")
If Not StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 3), "Ctrl: Left") Then _TestFail("side missing from list")
If Not StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 3), "Caps: On") Then _TestFail("condition missing from list")
If Not _guiToIni($APP_INI_PATH) Then _TestFail("could not save restricted hotkey")
If StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 3), "Inactive") Then _TestFail("side entry marked inactive")
If _HotkeyRepository_Count($aHotkeys) <> 1 Then _TestFail("side binding missing after save")
If $g_bSavedInactiveRestrictions Then _TestFail("side save warns inactive")
If IniRead($APP_INI_PATH, "Hotkeys", "^{F9}", "missing") <> $HOTKEY_CODEC_RESTRICTED Then _TestFail("restricted action did not save with placeholder")
If _HotkeyEditor_FindConflict("^{F9}", -1) = "" Then _TestFail("restricted shortcut was not recognized as a duplicate")
_addBtn()
GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_RADIO], $GUI_UNCHECKED)
GUICtrlSetState($g_aGuiState[$GUI_STATE_TEXT_RADIO], $GUI_CHECKED)
GUICtrlSetData($g_aGuiState[$GUI_STATE_TEXT_EDIT], "ordinary")
GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX], $GUI_CHECKED)
_GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO], "F10")
If Not _add() Then _TestFail("could not add ordinary row")
_GUICtrlListView_SortItems($g_aGuiState[$GUI_STATE_LIST_VIEW], 1)
Global $iRestrictedRow = -1, $iRow
For $iRow = 0 To _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) - 1
    If StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $iRow, 1), "F9") Then $iRestrictedRow = $iRow
Next
If $iRestrictedRow < 0 Then _TestFail("restricted row missing after sort")
_GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], -1, False)
_GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], $iRestrictedRow)
_editBtn()
If $g_aEditorRestrictions[0] <> 1 Or $g_aEditorRestrictions[4] <> 1 Then _TestFail("edit did not restore choices")
$g_iTestDialog = 1
AdlibRegister("_TestDialog", 200)
_HotkeyEditor_ShowRestrictions()
While IsHWnd($g_hRestrictionDialog)
    Sleep(10)
WEnd
If $g_aEditorRestrictions[0] <> 1 Or $g_aEditorRestrictions[4] <> 1 Then _TestFail("cancel changed restrictions")
_hideChild()
_guiDel()
Global $aTable = _HotkeyRepository_CreateTable(1)
If Not _HotkeyRepository_SetRecord($aTable, 1, $aRecord) Then _TestFail("could not prepare restricted fixture")
If Not _HotkeyRepository_Save($APP_INI_PATH, $aTable) Then _TestFail("could not write restricted fixture")
Global $hBefore = FileOpen($APP_INI_PATH, $FO_READ + $FO_BINARY), $bBefore = FileRead($hBefore)
FileClose($hBefore)
_mainGui()
If Not StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 3), "Ctrl: Left") Then _TestFail("imported restriction not displayed")
_GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], 0)
_editBtn()
If $g_aEditorRestrictions[0] <> 1 Or $g_aEditorRestrictions[4] <> 1 Then _TestFail("imported restriction not restored in editor")
_hideChild()
Global $hAfter = FileOpen($APP_INI_PATH, $FO_READ + $FO_BINARY), $bAfter = FileRead($hAfter)
FileClose($hAfter)
If $bBefore <> $bAfter Then _TestFail("opening or cancelling changed profile")
_guiDel()
$aRecord = _HotkeyModel_Create("^{F8}", $HOTKEY_ACTION_TEXT, "lock-only")
$aRecord[$HOTKEY_FIELD_CAPS_LOCK] = $HOTKEY_LOCK_ON
$aRecord[$HOTKEY_FIELD_NUM_LOCK] = $HOTKEY_LOCK_OFF
$aTable = _HotkeyRepository_CreateTable(1)
_HotkeyRepository_SetRecord($aTable, 1, $aRecord)
If Not _HotkeyRepository_Save($APP_INI_PATH, $aTable) Then _TestFail("write lock-only fixture")
_mainGui()
If StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 3), "Inactive") Then _TestFail("lock-only entry marked inactive")
If Not _guiToIni($APP_INI_PATH) Then _TestFail("save lock-only profile: error=" & @error & ", detail=" & @extended)
If _HotkeyRepository_Count($aHotkeys) <> 1 Then _TestFail("lock-only binding missing")
If $g_bSavedInactiveRestrictions Then _TestFail("lock-only save warns inactive")
_toggle()
If Not $enabled Then _TestFail("disable failed")
_toggle()
If $enabled Then _TestFail("re-enable failed")
If $aHotkeys[1][$HOTKEY_FIELD_CAPS_LOCK] <> 1 Or $aHotkeys[1][$HOTKEY_FIELD_NUM_LOCK] <> 2 Then _TestFail("toggle lost lock metadata")
_guiDel()
_mainGui()
_GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], 0)
_editBtn()
If $g_aEditorRestrictions[4] <> 1 Or $g_aEditorRestrictions[5] <> 2 Then _TestFail("reopened editor lost lock conditions")
GUICtrlSetState($g_aGuiState[$GUI_STATE_TEXT_RADIO], $GUI_UNCHECKED)
GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_RADIO], $GUI_CHECKED)
_fileRdo()
GUICtrlSetState($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX], $GUI_CHECKED)
_cmdCbox()
GUICtrlSetData($g_aGuiState[$GUI_STATE_FILE_INPUT], "echo harmless")
If Not _edit() Then _TestFail("change lock-only action type")
GUICtrlCreateListViewItem("Text|Ctrl + F7|ordinary|", $g_aGuiState[$GUI_STATE_LIST_VIEW])
_GUICtrlListView_SortItems($g_aGuiState[$GUI_STATE_LIST_VIEW], 1)
If Not _guiToIni($APP_INI_PATH) Then _TestFail("save sorted changed actions")
Global $aReopened = _HotkeyRepository_Load($APP_INI_PATH), $iLockRow = 0
For $iRow = 1 To _HotkeyRepository_Count($aReopened)
    If $aReopened[$iRow][$HOTKEY_FIELD_CAPS_LOCK] = 1 Then $iLockRow = $iRow
Next
If Not $iLockRow Then _TestFail("sorting lost lock record")
If $aReopened[$iLockRow][$HOTKEY_FIELD_ACTION] <> $HOTKEY_ACTION_COMMAND Or $aReopened[$iLockRow][$HOTKEY_FIELD_NUM_LOCK] <> 2 Then _TestFail("action change lost conditions")
For $iRow = 0 To _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) - 1
    If StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $iRow, 1), "F8") Then
        _GUICtrlListView_DeleteItem($g_aGuiState[$GUI_STATE_LIST_VIEW], $iRow)
        _HotkeyEditor_RemoveRestrictions("^{F8}")
        ExitLoop
    EndIf
Next
If Not _guiToIni($APP_INI_PATH) Then _TestFail("save after deleting conditional entry")
$aReopened = _HotkeyRepository_Load($APP_INI_PATH)
If _HotkeyRepository_Count($aReopened) <> 1 Or $aReopened[1][$HOTKEY_FIELD_CAPS_LOCK] <> 0 Then _TestFail("deletion retained orphan conditions")
ConsoleWrite("PASSED: restriction editor; lock-only save, reopen, toggle, action changes, sorting and deletion" & @CRLF)
Exit 0
Func _TestDialog()
    AdlibUnRegister("_TestDialog")
    If $g_iTestDialog = 0 Then
        _GUICtrlComboBox_SetCurSel($g_aRestrictionDialogControls[0], 1)
        _GUICtrlComboBox_SetCurSel($g_aRestrictionDialogControls[4], 1)
        _HotkeyEditor_RestrictionsAccept()
    Else
        _GUICtrlComboBox_SetCurSel($g_aRestrictionDialogControls[0], 2)
        _HotkeyEditor_RestrictionsCancel()
    EndIf
EndFunc
Func _TestFail($sMessage)
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
    Exit 1
EndFunc
Func _TestCleanup()
    _HotkeyRegistry_ClearTable($aHotkeys)
    _HotkeyRegistry_TrySet("^!+{F11}")
    If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    If $g_bOwnProfile Then
        FileDelete($APP_INI_PATH)
        FileDelete($APP_INI_PATH & ".bak")
        FileDelete($APP_INI_PATH & ".tmp")
    EndIf
EndFunc

Func _TestBinding($sHotkey, $sHandler)
    #forceref $sHotkey, $sHandler
    Return True
EndFunc
