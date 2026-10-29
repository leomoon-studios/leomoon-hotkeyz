#NoTrayIcon
; Desktop integration; isolated profile, simulated drives, no physical tray calls.
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
Global $g_iDriveMode = 0, $g_bOwnProfile = False
If FileExists($APP_INI_PATH) Or FileExists($APP_INI_PATH & ".bak") Or FileExists($APP_INI_PATH & ".tmp") Then Exit 2
OnAutoItExitRegister("_OpticalEditorCleanup")
$g_bOwnProfile = True
IniWrite($APP_INI_PATH, "Options", "Main", "^!+{F11}")
Global $aNativeDrives = _OpticalDriveActions_List()
If Not IsArray($aNativeDrives) Then _OpticalEditorFail("native read-only enumeration failed")
ConsoleWrite("Native optical drives detected: " & $aNativeDrives[0] & @CRLF)
$g_sOpticalListHandler = "_OpticalEditorList"
$g_sOpticalTrayHandler = "_OpticalEditorNeverOperate"
_HotkeyRegistry_ConfigureHotkeyBackend("_OpticalEditorBinding")
_mainGui()
_OpticalEditorSelect($OPTICAL_ACTION_OPEN, "F9")
; Exercise the registered GUI callback, not just a direct function call. An
; optional argument on an AutoIt GUI callback is not initialized by event dispatch.
GUICtrlSetData($g_aGuiState[$GUI_STATE_OPTICAL_DRIVE_COMBO], "")
GUICtrlSetData($g_aGuiState[$GUI_STATE_OPTICAL_DRIVE_COMBO], "Pending", "Pending")
_OpticalEditorClickRefresh()
If GUICtrlRead($g_aGuiState[$GUI_STATE_OPTICAL_DRIVE_COMBO]) <> "None" Then _OpticalEditorFail("no-drive state missing")
Global $aRecord = _HotkeyEditor_ReadRecord(), $iReadError = @error
If $iReadError <> $EDITOR_MODEL_ERROR_OPTICAL Or IsArray($aRecord) Then _OpticalEditorFail("no-drive editor accepted action")
If _HotkeyEditor_UpdateOkState() Then _OpticalEditorFail("OK enabled without drive")
Global $aActionRect = ControlGetPos($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], "", $g_aGuiState[$GUI_STATE_SPECIAL_COMBO])
Global $aDriveRect = ControlGetPos($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], "", $g_aGuiState[$GUI_STATE_OPTICAL_DRIVE_COMBO])
Global $aRefreshRect = ControlGetPos($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], "", $g_aGuiState[$GUI_STATE_OPTICAL_REFRESH_BUTTON])
Global $aClient = WinGetClientSize($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
If Not IsArray($aActionRect) Or Not IsArray($aDriveRect) Or Not IsArray($aRefreshRect) Or Not IsArray($aClient) Then _OpticalEditorFail("cannot measure controls")
If $aActionRect[0] + $aActionRect[2] > $aDriveRect[0] Or $aDriveRect[0] + $aDriveRect[2] > $aRefreshRect[0] Or $aRefreshRect[0] + $aRefreshRect[2] > $aClient[0] Then _OpticalEditorFail("optical controls overlap or extend outside editor")
$g_iDriveMode = 1
_OpticalEditorClickRefresh()
If _GUICtrlComboBox_GetCount($g_aGuiState[$GUI_STATE_OPTICAL_DRIVE_COMBO]) <> 2 Then _OpticalEditorFail("refresh did not populate both drives")
_GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_OPTICAL_DRIVE_COMBO], "E:")
$g_aEditorRestrictions[0] = $HOTKEY_SIDE_LEFT
$g_aEditorRestrictions[4] = $HOTKEY_LOCK_ON
If Not _add() Then _OpticalEditorFail("could not add open action")
_OpticalEditorSelect($OPTICAL_ACTION_CLOSE, "F10")
_GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_OPTICAL_DRIVE_COMBO], "D:")
If Not _add() Then _OpticalEditorFail("could not add close action")
If Not _guiToIni($APP_INI_PATH) Then _OpticalEditorFail("save failed")
Global $aSaved = _HotkeyRepository_Load($APP_INI_PATH)
If Not IsArray($aSaved) Or _HotkeyRepository_Count($aSaved) <> 2 Then _OpticalEditorFail("profile count changed")
If $aSaved[1][$HOTKEY_FIELD_TARGET] <> "Open optical drive tray E:" Or $aSaved[2][$HOTKEY_FIELD_TARGET] <> "Close optical drive tray D:" Then _OpticalEditorFail("drive/action did not persist")
_guiDel()
_mainGui()
If _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 0) <> "System" Then _OpticalEditorFail("imported optical entry is not system action")
_GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], -1, False)
_GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], 0)
_editBtn()
If GUICtrlRead($g_aGuiState[$GUI_STATE_SPECIAL_COMBO]) <> $OPTICAL_ACTION_OPEN Or GUICtrlRead($g_aGuiState[$GUI_STATE_OPTICAL_DRIVE_COMBO]) <> "E:" Then _OpticalEditorFail("edit lost action or drive")
If $g_aEditorRestrictions[0] <> $HOTKEY_SIDE_LEFT Or $g_aEditorRestrictions[4] <> $HOTKEY_LOCK_ON Then _OpticalEditorFail("edit lost conditions")
$g_iDriveMode = 2
_OpticalEditorClickRefresh()
If GUICtrlRead($g_aGuiState[$GUI_STATE_OPTICAL_DRIVE_COMBO]) <> "E:" Then _OpticalEditorFail("refresh silently retargeted disconnected drive")
If _HotkeyEditor_UpdateOkState() Then _OpticalEditorFail("disconnected selection accepted in editor")
_hideChild()
If Not _guiToIni($APP_INI_PATH) Then _OpticalEditorFail("bulk save rejected disconnected drive")
_editBtn()
If GUICtrlRead($g_aGuiState[$GUI_STATE_OPTICAL_DRIVE_COMBO]) <> "E:" Then _OpticalEditorFail("imported missing selection lost")
_GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_OPTICAL_DRIVE_COMBO], "D:")
_GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_SPECIAL_COMBO], $OPTICAL_ACTION_CLOSE)
_HotkeyEditor_SpecialChanged()
If Not _edit() Then _OpticalEditorFail("could not change operation and drive")
_GUICtrlListView_SortItems($g_aGuiState[$GUI_STATE_LIST_VIEW], 1)
If Not _guiToIni($APP_INI_PATH) Then _OpticalEditorFail("save after reorder failed")
$aSaved = _HotkeyRepository_Load($APP_INI_PATH)
Global $i
For $i = 1 To 2
    If $aSaved[$i][$HOTKEY_FIELD_TARGET] <> "Close optical drive tray D:" Then _OpticalEditorFail("reordered rows lost selected operation or drive")
Next
ConsoleWrite("PASSED: optical editor no-drive state, layout, refresh, selection, save/import, edit, conditions, disconnection, sorting; x64=" & @AutoItX64 & @CRLF)

Func _OpticalEditorSelect($sAction, $sKey)
    _addBtn()
    GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_RADIO], $GUI_UNCHECKED)
    GUICtrlSetState($g_aGuiState[$GUI_STATE_SPECIAL_RADIO], $GUI_CHECKED)
    _specialRdo()
    If _GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_SPECIAL_COMBO], $sAction) = -1 Then _OpticalEditorFail("action absent from editor")
    _HotkeyEditor_SpecialChanged()
    GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX], $GUI_CHECKED)
    GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_ALT_CHECKBOX], $GUI_CHECKED)
    _GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO], $sKey)
    _HotkeyEditor_UpdateOkState()
EndFunc
Func _OpticalEditorClickRefresh()
    If Not ControlClick($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], "", $g_aGuiState[$GUI_STATE_OPTICAL_REFRESH_BUTTON]) Then _OpticalEditorFail("could not click Refresh")
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < 300
        Sleep(10)
    WEnd
EndFunc
Func _OpticalEditorList()
    Switch $g_iDriveMode
        Case 0
            Local $aEmpty[1] = [0]
            Return $aEmpty
        Case 1
            Local $aBoth[3] = [2, "D:", "E:"]
            Return $aBoth
        Case Else
            Local $aOne[2] = [1, "D:"]
            Return $aOne
    EndSwitch
EndFunc
Func _OpticalEditorNeverOperate($sDrive, $sOperation)
    #forceref $sDrive, $sOperation
    _OpticalEditorFail("editing must not operate a tray")
EndFunc
Func _OpticalEditorBinding($sHotkey, $sHandler)
    #forceref $sHotkey, $sHandler
    Return True
EndFunc
Func _OpticalEditorCleanup()
    If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    If $g_bOwnProfile Then
        FileDelete($APP_INI_PATH)
        FileDelete($APP_INI_PATH & ".bak")
        FileDelete($APP_INI_PATH & ".tmp")
    EndIf
EndFunc
Func _OpticalEditorFail($sMessage)
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
    Exit 1
EndFunc
