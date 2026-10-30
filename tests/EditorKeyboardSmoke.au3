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
If $CmdLine[0] And ($CmdLine[1] = "gdi" Or $CmdLine[1] = "inspect-gdi") Then
    If Not _Application_EnableGdiScaling() Then Exit 15
EndIf
If FileExists($APP_INI_PATH) Or FileExists($APP_INI_PATH & ".bak") Or FileExists($APP_INI_PATH & ".tmp") Then Exit 2
OnAutoItExitRegister("_KeyboardCleanup")
IniWrite($APP_INI_PATH, "Options", "Main", "^!+{F11}")
_mainGui()
_addBtn()
If $CmdLine[0] And ($CmdLine[1] = "inspect" Or $CmdLine[1] = "inspect-gdi") Then
    _KeyboardReportHandle("Shortcut key", $g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO])
    _KeyboardReportHandle("Action type", $g_iEditorActionSelector)
    _KeyboardReportHandle("Program, file or command", $g_aGuiState[$GUI_STATE_FILE_INPUT])
    _KeyboardReportHandle("Parameters", $g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT])
    _KeyboardReportHandle("Folder", $g_aGuiState[$GUI_STATE_FOLDER_INPUT])
    _KeyboardReportHandle("System action", $g_aGuiState[$GUI_STATE_SPECIAL_COMBO])
    _KeyboardReportHandle("Optical drive", $g_aGuiState[$GUI_STATE_OPTICAL_DRIVE_COMBO])
    _KeyboardReportHandle("Active window action", $g_aGuiState[$GUI_STATE_WINDOW_COMBO])
    _KeyboardReportHandle("Move X", $g_aGuiState[$GUI_STATE_MOVE_X_INPUT])
    _KeyboardReportHandle("Move Y", $g_aGuiState[$GUI_STATE_MOVE_Y_INPUT])
    _KeyboardReportHandle("Width", $g_aGuiState[$GUI_STATE_RESIZE_WIDTH_INPUT])
    _KeyboardReportHandle("Height", $g_aGuiState[$GUI_STATE_RESIZE_HEIGHT_INPUT])
    _KeyboardReportHandle("URL protocol", $g_aGuiState[$GUI_STATE_URL_COMBO])
    _KeyboardReportHandle("Website address", $g_aGuiState[$GUI_STATE_URL_INPUT])
    _KeyboardReportHandle("Text to paste", $g_aGuiState[$GUI_STATE_TEXT_EDIT])
    _KeyboardReportHandle("Enable or disable shortcut key", $g_aGuiState[$GUI_STATE_KEY_COMBO])
    _KeyboardReportHandle("Hotkeys", $g_aGuiState[$GUI_STATE_LIST_VIEW])
    ConsoleWrite("WINDOW|Settings|" & $g_aGuiState[$GUI_STATE_MAIN_WINDOW] & @CRLF)
    ConsoleWrite("WINDOW|Editor|" & $g_aGuiState[$GUI_STATE_EDITOR_WINDOW] & @CRLF)
    _HotkeyEditor_ShowRestrictions()
    ConsoleWrite("WINDOW|Conditions|" & $g_hRestrictionDialog & @CRLF)
    Global $aNames[7] = ["Ctrl side", "Alt side", "Shift side", "Win side", "Caps Lock", "Num Lock", "Scroll Lock"], $iName
    For $iName = 0 To 6
        _KeyboardReportHandle($aNames[$iName], $g_aRestrictionDialogControls[$iName])
    Next
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
_addBtn()
Global $aFirstFields[5] = [$GUI_STATE_FOLDER_INPUT, $GUI_STATE_SPECIAL_COMBO, $GUI_STATE_WINDOW_COMBO, $GUI_STATE_URL_COMBO, $GUI_STATE_TEXT_EDIT], $iAction
For $iAction = 1 To 5
    _GUICtrlComboBox_SetCurSel($g_iEditorActionSelector, $iAction)
    _HotkeyEditor_ActionChanged()
    ControlFocus($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], "", $g_iEditorActionSelector)
    Send("{TAB}")
    Sleep(80)
    $aFocus = DllCall("user32.dll", "hwnd", "GetFocus")
    If $aFocus[0] <> GUICtrlGetHandle($g_aGuiState[$aFirstFields[$iAction - 1]]) Then Exit 9
Next
ControlFocus($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], "", $g_aGuiState[$GUI_STATE_RESTRICTIONS_BUTTON])
Send("{SPACE}")
Sleep(150)
If Not IsHWnd($g_hRestrictionDialog) Then Exit 10
Send("{ESC}")
Sleep(150)
If IsHWnd($g_hRestrictionDialog) Or Not IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then Exit 11
Send("{ESC}")
Sleep(150)
If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then Exit 12
ControlFocus($g_aGuiState[$GUI_STATE_MAIN_WINDOW], "", $g_aGuiState[$GUI_STATE_STARTUP_CHECKBOX])
Send("{TAB}")
Sleep(80)
$aFocus = DllCall("user32.dll", "hwnd", "GetFocus")
If $aFocus[0] <> GUICtrlGetHandle($g_aGuiState[$GUI_STATE_CTRL_CHECKBOX]) Then Exit 13
Send("{ESC}")
Sleep(150)
If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then Exit 14
ConsoleWrite("PASSED: keyboard traversal, action fields, Conditions, Escape, default Enter and multiline Enter" & @CRLF)
Func _KeyboardBinding($sHotkey, $sHandler)
    #forceref $sHotkey, $sHandler
    Return True
EndFunc
Func _KeyboardReportHandle($sName, $iControl)
    ConsoleWrite("ACCESS|" & $sName & "|" & GUICtrlGetHandle($iControl) & @CRLF)
EndFunc
Func _KeyboardCleanup()
    If IsHWnd($g_hRestrictionDialog) Then GUIDelete($g_hRestrictionDialog)
    If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    FileDelete($APP_INI_PATH)
    FileDelete($APP_INI_PATH & ".bak")
    FileDelete($APP_INI_PATH & ".tmp")
EndFunc
