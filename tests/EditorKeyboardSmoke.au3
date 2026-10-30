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
Opt("MustDeclareVars", 1)
Opt("GUIOnEventMode", 1)
If FileExists($APP_INI_PATH) Or FileExists($APP_INI_PATH & ".bak") Or FileExists($APP_INI_PATH & ".tmp") Then Exit 2
OnAutoItExitRegister("_KeyboardCleanup")
IniWrite($APP_INI_PATH, "Options", "Main", "^!+{F11}")
_mainGui()
_addBtn()
If $CmdLine[0] And $CmdLine[1] = "inspect" Then
    Sleep(12000)
    Exit 0
EndIf
WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
ControlFocus($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], "", $g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX])
Global $i, $aFocus, $hFocus, $sClass, $sText
Global $aExpected[14] = [$GUI_STATE_EDITOR_CTRL_CHECKBOX, $GUI_STATE_EDITOR_ALT_CHECKBOX, $GUI_STATE_EDITOR_SHIFT_CHECKBOX, $GUI_STATE_EDITOR_WIN_CHECKBOX, $GUI_STATE_EDITOR_KEY_COMBO, $GUI_STATE_RESTRICTIONS_BUTTON, -1, $GUI_STATE_FILE_INPUT, $GUI_STATE_FILE_BROWSE_BUTTON, $GUI_STATE_FILE_PARAMETER_INPUT, $GUI_STATE_ADMIN_CHECKBOX, $GUI_STATE_SINGLETON_CHECKBOX, $GUI_STATE_COMMAND_CHECKBOX, $GUI_STATE_EDITOR_CANCEL_BUTTON]
For $i = 0 To 15
    $aFocus = DllCall("user32.dll", "hwnd", "GetFocus")
    $hFocus = $aFocus[0]
    If $i < UBound($aExpected) Then
        Global $hExpected
        If $aExpected[$i] = -1 Then
            $hExpected = GUICtrlGetHandle($g_iEditorActionSelector)
        Else
            $hExpected = GUICtrlGetHandle($g_aGuiState[$aExpected[$i]])
        EndIf
        If $hFocus <> $hExpected Then Exit 5
    EndIf
    $sClass = _WinAPI_GetClassName($hFocus)
    $sText = ControlGetText($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], "", $hFocus)
    ConsoleWrite("Tab " & $i & ": " & $sClass & " " & $sText & @CRLF)
    Send("{TAB}")
    Sleep(80)
Next
Send("{ESC}")
Sleep(150)
If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then Exit 3
If Not IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then Exit 4
_HotkeyRegistry_ConfigureHotkeyBackend("_KeyboardBinding")
_addBtn()
GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX], $GUI_CHECKED)
_GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO], "F9")
GUICtrlSetData($g_aGuiState[$GUI_STATE_FILE_INPUT], @AutoItExe)
_HotkeyEditor_UpdateOkState()
ControlFocus($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], "", $g_aGuiState[$GUI_STATE_FILE_INPUT])
Send("{ENTER}")
Sleep(150)
If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Or _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) <> 1 Then Exit 6
_addBtn()
GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_RADIO], $GUI_UNCHECKED)
GUICtrlSetState($g_aGuiState[$GUI_STATE_TEXT_RADIO], $GUI_CHECKED)
_txtRdo()
_HotkeyEditor_UpdateOkState()
ControlFocus($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], "", $g_aGuiState[$GUI_STATE_TEXT_EDIT])
Send("first{ENTER}second")
Sleep(150)
If Not IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Or GUICtrlRead($g_aGuiState[$GUI_STATE_TEXT_EDIT]) <> "first" & @CRLF & "second" Then Exit 7
Send("{ESC}")
Sleep(150)
If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then Exit 8
ConsoleWrite("PASSED: editor tab order, Escape, default Enter and multiline Enter" & @CRLF)
Func _KeyboardBinding($sHotkey, $sHandler)
    #forceref $sHotkey, $sHandler
    Return True
EndFunc
Func _KeyboardCleanup()
    If IsHWnd($g_hRestrictionDialog) Then GUIDelete($g_hRestrictionDialog)
    If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    FileDelete($APP_INI_PATH)
    FileDelete($APP_INI_PATH & ".bak")
    FileDelete($APP_INI_PATH & ".tmp")
EndFunc
