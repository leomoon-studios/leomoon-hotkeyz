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
If $CmdLine[0] And $CmdLine[1] = "gdi" Then
    If Not _Application_EnableGdiScaling() Then Exit 3
EndIf
If FileExists($APP_INI_PATH) Or FileExists($APP_INI_PATH & ".bak") Or FileExists($APP_INI_PATH & ".tmp") Then Exit 2
OnAutoItExitRegister("_RoundTripCleanup")
IniWrite($APP_INI_PATH, "Options", "Main", "^!+{F11}")
_HotkeyRegistry_ConfigureHotkeyBackend("_RoundTripBinding")
_mainGui()
Global $aExpected = _HotkeyRepository_CreateTable(7), $aRecord, $i, $j
For $i = 0 To 6
    _addBtn()
    If $i > 0 And $i < 6 Then
        _GUICtrlComboBox_SetCurSel($g_iEditorActionSelector, $i)
        _HotkeyEditor_ActionChanged()
    EndIf
    GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX], $GUI_CHECKED)
    _GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO], "F" & ($i + 1))
    Switch $i
        Case 0
            GUICtrlSetData($g_aGuiState[$GUI_STATE_FILE_INPUT], @AutoItExe)
            GUICtrlSetData($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT], "--example <USERNAME>")
            GUICtrlSetState($g_aGuiState[$GUI_STATE_ADMIN_CHECKBOX], $GUI_CHECKED)
            GUICtrlSetState($g_aGuiState[$GUI_STATE_SINGLETON_CHECKBOX], $GUI_CHECKED)
            $g_aEditorRestrictions[4] = $HOTKEY_LOCK_ON
        Case 1
            GUICtrlSetData($g_aGuiState[$GUI_STATE_FOLDER_INPUT], @TempDir)
        Case 2
            _GUICtrlComboBox_SetCurSel($g_aGuiState[$GUI_STATE_SPECIAL_COMBO], 0)
        Case 3
            _GUICtrlComboBox_SetCurSel($g_aGuiState[$GUI_STATE_WINDOW_COMBO], 0)
        Case 4
            GUICtrlSetData($g_aGuiState[$GUI_STATE_URL_INPUT], "example.com/path")
        Case 5
            GUICtrlSetData($g_aGuiState[$GUI_STATE_TEXT_EDIT], "first <USERNAME>" & @CRLF & "second")
        Case 6
            GUICtrlSetState($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX], $GUI_CHECKED)
            _cmdCbox()
            GUICtrlSetState($g_aGuiState[$GUI_STATE_ADMIN_CHECKBOX], $GUI_CHECKED)
            GUICtrlSetData($g_aGuiState[$GUI_STATE_FILE_INPUT], "echo example")
    EndSwitch
    $aRecord = _HotkeyEditor_ReadRecord()
    If Not IsArray($aRecord) Then _RoundTripFail("editor did not accept action " & $i)
    _HotkeyRepository_SetRecord($aExpected, $i + 1, $aRecord)
    If Not _add() Then _RoundTripFail("could not add action " & $i)
Next
If Not _guiToIni($APP_INI_PATH) Then _RoundTripFail("save failed")
Global $aSaved = _HotkeyRepository_Load($APP_INI_PATH)
If Not IsArray($aSaved) Or Not _HotkeyRepository_TablesEqual($aExpected, $aSaved) Then _RoundTripFail("saved profile changed a record")
_guiDel()
_mainGui()
For $i = 0 To 6
    _GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], -1, False)
    _GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], $i)
    _editBtn()
    $aRecord = _HotkeyEditor_ReadRecord()
    If Not IsArray($aRecord) Then _RoundTripFail("reopened action invalid " & $i)
    For $j = 0 To $HOTKEY_FIELD_COUNT - 1
        If $aRecord[$j] <> $aExpected[$i + 1][$j] Then _RoundTripFail("reopened action changed field " & $i & "/" & $j)
    Next
    _hideChild()
Next
ConsoleWrite("PASSED: seven editor actions, options, condition, tags and multiline text saved and reopened" & @CRLF)
Func _RoundTripBinding($sHotkey, $sHandler)
    #forceref $sHotkey, $sHandler
    Return True
EndFunc
Func _RoundTripFail($sMessage)
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
    Exit 1
EndFunc
Func _RoundTripCleanup()
    If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    _HotkeyRegistry_ResetHotkeyBackend()
    FileDelete($APP_INI_PATH)
    FileDelete($APP_INI_PATH & ".bak")
    FileDelete($APP_INI_PATH & ".tmp")
EndFunc
