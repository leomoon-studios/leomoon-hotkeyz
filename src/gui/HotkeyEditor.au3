#include-once

#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiComboBox.au3>
#include <GuiListView.au3>
#include <WindowsConstants.au3>
#include "HotkeyEditorModel.au3"

Global $g_bHotkeyEditorUpdating = False
Global $g_aEditorRestrictions[7] = [0, 0, 0, 0, 0, 0, 0]
Global $g_aRestrictionRows[1][8]
Global $g_aRestrictionDialogControls[7], $g_hRestrictionDialog = 0

Func _HotkeyEditor_ResetRestrictions()
    Local $i
    For $i = 0 To 6
        $g_aEditorRestrictions[$i] = 0
    Next
EndFunc

Func _HotkeyEditor_ShowRestrictions()
    If IsHWnd($g_hRestrictionDialog) Then Return
    Local $aLabels[7] = ["Ctrl side", "Alt side", "Shift side", "Win side", "Caps Lock", "Num Lock", "Scroll Lock"]
    Local $aModifierControls[4] = [$GUI_STATE_EDITOR_CTRL_CHECKBOX, $GUI_STATE_EDITOR_ALT_CHECKBOX, $GUI_STATE_EDITOR_SHIFT_CHECKBOX, $GUI_STATE_EDITOR_WIN_CHECKBOX]
    ; An owned popup stays above the editor without being clipped to its client area.
    $g_hRestrictionDialog = GUICreate("Modifiers and conditions", 360, 345, -1, -1, BitOR($WS_POPUP, $WS_CAPTION, $WS_SYSMENU), $WS_EX_DLGMODALFRAME, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    GUISetFont(9, 400, 0, "Tahoma")
    Local $i, $sChoices
    For $i = 0 To 6
        GUICtrlCreateLabel($aLabels[$i], 18, 20 + ($i * 37), 145, 22)
        $g_aRestrictionDialogControls[$i] = GUICtrlCreateCombo("", 170, 16 + ($i * 37), 165, 25, $CBS_DROPDOWNLIST)
        $sChoices = "Any|On|Off"
        If $i < 4 Then $sChoices = "Either|Left|Right"
        GUICtrlSetData(-1, $sChoices)
        _GUICtrlComboBox_SetCurSel($g_aRestrictionDialogControls[$i], $g_aEditorRestrictions[$i])
        If $i < 4 Then
            If Not BitAND(GUICtrlRead($g_aGuiState[$aModifierControls[$i]]), $GUI_CHECKED) Then GUICtrlSetState($g_aRestrictionDialogControls[$i], $GUI_DISABLE)
        EndIf
    Next
    GUICtrlCreateLabel("Restrictions are not active until the input backend is implemented.", 18, 278, 325, 28)
    GUICtrlCreateButton("OK", 18, 308, 150, 28)
    GUICtrlSetOnEvent(-1, "_HotkeyEditor_RestrictionsAccept")
    GUICtrlCreateButton("Cancel", 185, 308, 150, 28)
    GUICtrlSetOnEvent(-1, "_HotkeyEditor_RestrictionsCancel")
    GUISetOnEvent($GUI_EVENT_CLOSE, "_HotkeyEditor_RestrictionsCancel", $g_hRestrictionDialog)
    GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    GUISetState(@SW_SHOW, $g_hRestrictionDialog)
EndFunc

Func _HotkeyEditor_RestrictionsAccept()
    Local $i
    For $i = 0 To 6
        $g_aEditorRestrictions[$i] = _GUICtrlComboBox_GetCurSel($g_aRestrictionDialogControls[$i])
    Next
    _HotkeyEditor_RestrictionsClose()
EndFunc

Func _HotkeyEditor_RestrictionsClose()
    GUIDelete($g_hRestrictionDialog)
    $g_hRestrictionDialog = 0
    GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    _HotkeyEditor_UpdateOkState()
EndFunc

Func _HotkeyEditor_RestrictionsCancel()
    _HotkeyEditor_RestrictionsClose()
EndFunc

Func _HotkeyEditor_FindRestrictions($sHotkey)
    Local $sNormalized = _HotkeyCodec_NormalizeHotkey($sHotkey), $i
    For $i = 1 To UBound($g_aRestrictionRows) - 1
        If $g_aRestrictionRows[$i][0] = $sNormalized Then Return $i
    Next
    Return 0
EndFunc

Func _HotkeyEditor_SetRestrictions($sHotkey, ByRef $aRecord)
    Local $iRow = _HotkeyEditor_FindRestrictions($sHotkey), $i
    If Not $iRow Then
        $iRow = UBound($g_aRestrictionRows)
        ReDim $g_aRestrictionRows[$iRow + 1][8]
    EndIf
    $g_aRestrictionRows[$iRow][0] = _HotkeyCodec_NormalizeHotkey($sHotkey)
    For $i = 0 To 6
        $g_aRestrictionRows[$iRow][$i + 1] = $aRecord[$HOTKEY_FIELD_CTRL_SIDE + $i]
    Next
EndFunc

Func _HotkeyEditor_ApplyRestrictions($sHotkey, ByRef $aRecord)
    Local $iRow = _HotkeyEditor_FindRestrictions($sHotkey), $i
    If Not $iRow Then Return
    For $i = 0 To 6
        $aRecord[$HOTKEY_FIELD_CTRL_SIDE + $i] = $g_aRestrictionRows[$iRow][$i + 1]
    Next
EndFunc

Func _HotkeyEditor_RemoveRestrictions($sHotkey)
    Local $iRow = _HotkeyEditor_FindRestrictions($sHotkey)
    If $iRow Then $g_aRestrictionRows[$iRow][0] = ""
EndFunc

Func _HotkeyEditor_RestrictionSummary(ByRef $aRecord)
    Local $aLabels[7] = ["Ctrl", "Alt", "Shift", "Win", "Caps", "Num", "Scroll"]
    Local $sSummary = "", $i, $sValue
    For $i = 0 To 6
        Switch $aRecord[$HOTKEY_FIELD_CTRL_SIDE + $i]
            Case 1
                $sValue = "Left"
                If $i >= 4 Then $sValue = "On"
            Case 2
                $sValue = "Right"
                If $i >= 4 Then $sValue = "Off"
            Case Else
                ContinueLoop
        EndSwitch
        If $sSummary <> "" Then $sSummary &= ", "
        $sSummary &= $aLabels[$i] & ": " & $sValue
    Next
    If $sSummary <> "" Then Return "Inactive (conditions unavailable): " & $sSummary
    Return ""
EndFunc

Func _editGui($name)
    ;edit gui
    $g_aGuiState[$GUI_STATE_EDITOR_WINDOW] = GUICreate($name, 418, 706, -1, -1, $WS_EX_TOOLWINDOW, $WS_EX_MDICHILD, $g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    GUISetFont(9, 400, 0, "Tahoma")
    GUICtrlCreateGroup("Action", 8, 8, 395, 554)
    $g_aGuiState[$GUI_STATE_FILE_RADIO] = GUICtrlCreateRadio("Run a program or open a file", 17, 32, 185, 17)
    $g_aGuiState[$GUI_STATE_FILE_INPUT] = GUICtrlCreateInput("", 17, 58, 279, 22)
    $g_aGuiState[$GUI_STATE_FILE_BROWSE_BUTTON] = GUICtrlCreateButton("Browse File", 304, 56, 89, 25)
    $g_aGuiState[$GUI_STATE_FILE_PARAMETER_LABEL] = GUICtrlCreateLabel("Parameters (Optional)", 16, 92, 124, 18)
    $g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT] = GUICtrlCreateInput("", 145, 88, 247, 22)
    $g_aGuiState[$GUI_STATE_ADMIN_CHECKBOX] = GUICtrlCreateCheckbox("Run as admin", 17, 121, 113, 17)
    $g_aGuiState[$GUI_STATE_SINGLETON_CHECKBOX] = GUICtrlCreateCheckbox("Singleton", 152, 121, 113, 17)
    $g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX] = GUICtrlCreateCheckbox("Advanced command", 265, 120, 129, 17)
    $g_aGuiState[$GUI_STATE_FOLDER_RADIO] = GUICtrlCreateRadio("Open a folder", 17, 152, 369, 17)
    $g_aGuiState[$GUI_STATE_FOLDER_INPUT] = GUICtrlCreateInput("", 17, 178, 271, 22)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_FOLDER_BROWSE_BUTTON] = GUICtrlCreateButton("Browse Folder", 296, 176, 89, 25)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_SPECIAL_RADIO] = GUICtrlCreateRadio("Run a system action", 17, 216, 369, 17)
    $g_aGuiState[$GUI_STATE_SPECIAL_COMBO] = GUICtrlCreateCombo("", 17, 242, 367, 25, BitOR($CBS_DROPDOWNLIST,$WS_VSCROLL))
    GUICtrlSetData(-1, _ActionCatalog_SpecialLabels())
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_WINDOW_RADIO] = GUICtrlCreateRadio("Run actions on active window", 16, 280, 369, 17)
    $g_aGuiState[$GUI_STATE_WINDOW_COMBO] = GUICtrlCreateCombo("", 17, 306, 367, 25, BitOR($CBS_DROPDOWNLIST,$WS_VSCROLL))
    GUICtrlSetData(-1, _ActionCatalog_WindowLabels())
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_MOVE_CHECKBOX] = GUICtrlCreateCheckbox("Move active window", 17, 336, 177, 17)
    GUICtrlSetState(-1, $GUI_CHECKED)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_X_LABEL] = GUICtrlCreateLabel("X:", 18, 362, 15, 18)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_MOVE_X_INPUT] = GUICtrlCreateInput("0", 41, 360, 55, 22)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_Y_LABEL] = GUICtrlCreateLabel("Y:", 106, 362, 16, 18)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_MOVE_Y_INPUT] = GUICtrlCreateInput("0", 129, 360, 55, 22)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX] = GUICtrlCreateCheckbox("Resize active window", 217, 336, 169, 17)
    GUICtrlSetState(-1, $GUI_CHECKED)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_WIDTH_LABEL] = GUICtrlCreateLabel("W:", 218, 362, 20, 18)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_RESIZE_WIDTH_INPUT] = GUICtrlCreateInput("800", 241, 360, 55, 22, $ES_NUMBER)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_HEIGHT_LABEL] = GUICtrlCreateLabel("H:", 306, 362, 16, 18)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_RESIZE_HEIGHT_INPUT] = GUICtrlCreateInput("600", 329, 360, 55, 22, $ES_NUMBER)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_URL_RADIO] = GUICtrlCreateRadio("Open a URL (URL will open with the default browser)", 17, 400, 369, 17)
    $g_aGuiState[$GUI_STATE_URL_COMBO] = GUICtrlCreateCombo("", 17, 426, 79, 25, BitOR($CBS_DROPDOWNLIST,$CBS_AUTOHSCROLL))
    GUICtrlSetData(-1, "https://|http://|ftp://", "https://")
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_URL_INPUT] = GUICtrlCreateInput("leomoon.com", 105, 426, 279, 22)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_TEXT_RADIO] = GUICtrlCreateRadio("Paste text into active window", 17, 464, 353, 17)
    $g_aGuiState[$GUI_STATE_TEXT_EDIT] = GUICtrlCreateEdit("", 17, 489, 367, 63, BitOR($ES_AUTOVSCROLL,$ES_WANTRETURN,$WS_VSCROLL))
    GUICtrlSetState(-1, $GUI_DISABLE)
    GUICtrlCreateGroup("", -99, -99, 1, 1)
    GUICtrlCreateGroup("Assign a hotkey", 8, 568, 395, 58)
    $g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX] = GUICtrlCreateCheckbox("Ctrl", 17, 592, 57, 17)
    $g_aGuiState[$GUI_STATE_EDITOR_ALT_CHECKBOX] = GUICtrlCreateCheckbox("Alt", 80, 592, 57, 17)
    $g_aGuiState[$GUI_STATE_EDITOR_SHIFT_CHECKBOX] = GUICtrlCreateCheckbox("Shift", 144, 592, 57, 17)
    $g_aGuiState[$GUI_STATE_EDITOR_WIN_CHECKBOX] = GUICtrlCreateCheckbox("Win", 208, 592, 57, 17)
    $g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO] = GUICtrlCreateCombo("", 273, 590, 119, 25, BitOR($GUI_SS_DEFAULT_COMBO,$CBS_SIMPLE))
    GUICtrlSetData(-1, $HOTKEY_CODEC_KEY_NAMES)
    GUICtrlCreateGroup("", -99, -99, 1, 1)
    $g_aGuiState[$GUI_STATE_EDITOR_OK_BUTTON] = GUICtrlCreateButton("OK", 8, 632, 125, 33)
    $g_aGuiState[$GUI_STATE_RESTRICTIONS_BUTTON] = GUICtrlCreateButton("Conditions...", 139, 632, 132, 33)
    GUICtrlSetOnEvent(-1, "_HotkeyEditor_ShowRestrictions")
    $g_aGuiState[$GUI_STATE_EDITOR_CANCEL_BUTTON] = GUICtrlCreateButton("Cancel", 277, 632, 125, 33)
    ;other settings
    GUISetIcon(@ScriptFullPath, 201)
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_FOLDER_RADIO], "_folderRdo")
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX], "_cmdCbox")
    GUICtrlSetTip($g_aGuiState[$GUI_STATE_ADMIN_CHECKBOX], 'Runs program as administrator.', 'Run as admin', 1)
    GUICtrlSetTip($g_aGuiState[$GUI_STATE_SINGLETON_CHECKBOX], 'Runs program only if there are no'&@CR& _
                            'process running with that name.', 'Singleton', 1)
    GUICtrlSetTip($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX], 'Runs an advanced command in a hidden command prompt.'&@CR& _
                            ''&@CR& _
                            'Examples:'&@CR& _
                            'net stop "ServiceName" && net start "ServiceName"'&@CR& _
                            'RunDll32.exe shell32.dll,Control_RunDLL mmsys.cpl,,0'&@CR& _
                            'start "" "C:\Windows\System32\notepad.exe" & start "" "C:\Windows\system32\cmd.exe"', 'For Advanced Users', 1)
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_FOLDER_BROWSE_BUTTON], "_folderBrowse")
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_FILE_RADIO], "_fileRdo")
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_FILE_BROWSE_BUTTON], "_fileBrowse")
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_SPECIAL_RADIO], "_specialRdo")
    _GUICtrlComboBox_SetCurSel($g_aGuiState[$GUI_STATE_SPECIAL_COMBO], 0)
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_WINDOW_RADIO], "_windowRdo")
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_WINDOW_COMBO], "_windowDown")
    _GUICtrlComboBox_SetCurSel($g_aGuiState[$GUI_STATE_WINDOW_COMBO], 0)
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX], "_moveCbox")
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX], "_resizeCbox")
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_URL_RADIO], "_urlRdo")
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_TEXT_RADIO], "_txtRdo")
    GUICtrlSetTip($g_aGuiState[$GUI_STATE_TEXT_EDIT], "<HOUR> will paste the current hour."&@LF& _
                "<MINUTE> will paste the current minute."&@LF& _
                "<SECOND> will paste the current second."&@LF& _
                "<YEAR> will paste the current 4 digit year."&@LF& _
                "<MONTHNAME> will paste the name of the current month."&@LF& _
                "<MONTHNUMBER> will paste the number of the current month."&@LF& _
                "<DAYNAME> will paste the name of the current day."&@LF& _
                "<DAYNUMBER> will paste the current day of the month."&@LF& _
                "<YYYYMMDD> will paste the current date in YYYYMMDD format."&@LF& _
                "<YYYY-MM-DD> will paste the current date in YYYY-MM-DD format."&@LF& _
                "<COMPUTERNAME> will paste the name of the computer."&@LF& _
                "<USERNAME> will paste the name of the current logged in user.", "Predefined Tags", 1)
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_EDITOR_CANCEL_BUTTON], "_hideChild")
    ;center child window
    Local $mpos = WinGetPos($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    If @error Or Not IsArray($mpos) Then Return SetError(1, @error, False)
    Local $cpos = WinGetPos($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    If @error Or Not IsArray($cpos) Then Return SetError(2, @error, False)
    If Not WinMove($g_aGuiState[$GUI_STATE_EDITOR_WINDOW], '', $mpos[0]+($mpos[2]/2)-($cpos[2]/2), $mpos[1]+($mpos[3]/2)-($cpos[3]/2)) Then Return SetError(3, @error, False)
    Local $aAccelKeys[1][2] = [["{ESC}", $g_aGuiState[$GUI_STATE_EDITOR_CANCEL_BUTTON]]]
    GUISetAccelerators($aAccelKeys)
    WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    _HotkeyEditor_UpdateOkState()
EndFunc

Func _fileRdo()
    If GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_RADIO]) == 1 Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_INPUT], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_BROWSE_BUTTON], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_PARAMETER_LABEL], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_ADMIN_CHECKBOX], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SINGLETON_CHECKBOX], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX], $GUI_ENABLE)
        _cmdCbox()
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FOLDER_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FOLDER_BROWSE_BUTTON], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SPECIAL_COMBO], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_WINDOW_COMBO], $GUI_DISABLE)
        _windowDown()
        GUICtrlSetState($g_aGuiState[$GUI_STATE_URL_COMBO], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_URL_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_TEXT_EDIT], $GUI_DISABLE)
    EndIf
EndFunc

Func _cmdCbox()
    If GUICtrlRead($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX]) == $GUI_CHECKED Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_BROWSE_BUTTON], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SINGLETON_CHECKBOX], $GUI_UNCHECKED)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SINGLETON_CHECKBOX], $GUI_DISABLE)
        GUICtrlSetData($g_aGuiState[$GUI_STATE_FILE_RADIO], 'Run an advanced command')
    Else
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_BROWSE_BUTTON], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SINGLETON_CHECKBOX], $GUI_ENABLE)
        GUICtrlSetData($g_aGuiState[$GUI_STATE_FILE_RADIO], 'Run a program or open a file')
    EndIf
EndFunc

Func _folderRdo()
    If GUICtrlRead($g_aGuiState[$GUI_STATE_FOLDER_RADIO]) == 1 Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_BROWSE_BUTTON], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_PARAMETER_LABEL], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_ADMIN_CHECKBOX], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SINGLETON_CHECKBOX], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FOLDER_INPUT], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FOLDER_BROWSE_BUTTON], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SPECIAL_COMBO], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_WINDOW_COMBO], $GUI_DISABLE)
        _windowDown()
        GUICtrlSetState($g_aGuiState[$GUI_STATE_URL_COMBO], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_URL_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_TEXT_EDIT], $GUI_DISABLE)
    EndIf
EndFunc

Func _specialRdo()
    If GUICtrlRead($g_aGuiState[$GUI_STATE_SPECIAL_RADIO]) == 1 Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_BROWSE_BUTTON], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_PARAMETER_LABEL], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_ADMIN_CHECKBOX], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SINGLETON_CHECKBOX], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FOLDER_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FOLDER_BROWSE_BUTTON], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SPECIAL_COMBO], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_WINDOW_COMBO], $GUI_DISABLE)
        _windowDown()
        GUICtrlSetState($g_aGuiState[$GUI_STATE_URL_COMBO], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_URL_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_TEXT_EDIT], $GUI_DISABLE)
    EndIf
EndFunc

Func _windowRdo()
    If GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_RADIO]) == 1 Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_BROWSE_BUTTON], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_PARAMETER_LABEL], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_ADMIN_CHECKBOX], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SINGLETON_CHECKBOX], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FOLDER_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FOLDER_BROWSE_BUTTON], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SPECIAL_COMBO], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_WINDOW_COMBO], $GUI_ENABLE)
        _windowDown()
        GUICtrlSetState($g_aGuiState[$GUI_STATE_URL_COMBO], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_URL_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_TEXT_EDIT], $GUI_DISABLE)
    EndIf
EndFunc

Func _windowDown()
    If GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_COMBO]) == $ACTION_CATALOG_CUSTOM_WINDOW And BitAND(GUICtrlGetState($g_aGuiState[$GUI_STATE_WINDOW_COMBO]), $GUI_ENABLE) Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX], $GUI_ENABLE)
        _moveCbox()
        GUICtrlSetState($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX], $GUI_ENABLE)
        _resizeCbox()
    Else
        GUICtrlSetState($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX], $GUI_DISABLE)
        _moveCbox()
        GUICtrlSetState($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX], $GUI_DISABLE)
        _resizeCbox()
    EndIf
EndFunc

Func _moveCbox()
    If GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX]) == $GUI_CHECKED And BitAND(GUICtrlGetState($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX]), $GUI_ENABLE) And GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_COMBO]) == $ACTION_CATALOG_CUSTOM_WINDOW Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_X_LABEL], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_MOVE_X_INPUT], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_Y_LABEL], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_MOVE_Y_INPUT], $GUI_ENABLE)
    Else
        GUICtrlSetState($g_aGuiState[$GUI_STATE_X_LABEL], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_MOVE_X_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_Y_LABEL], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_MOVE_Y_INPUT], $GUI_DISABLE)
    EndIf
EndFunc

Func _resizeCbox()
    If GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX]) == $GUI_CHECKED And BitAND(GUICtrlGetState($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX]), $GUI_ENABLE) And GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_COMBO]) == $ACTION_CATALOG_CUSTOM_WINDOW Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_WIDTH_LABEL], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_RESIZE_WIDTH_INPUT], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_HEIGHT_LABEL], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_RESIZE_HEIGHT_INPUT], $GUI_ENABLE)
    Else
        GUICtrlSetState($g_aGuiState[$GUI_STATE_WIDTH_LABEL], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_RESIZE_WIDTH_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_HEIGHT_LABEL], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_RESIZE_HEIGHT_INPUT], $GUI_DISABLE)
    EndIf
EndFunc

Func _urlRdo()
    If GUICtrlRead($g_aGuiState[$GUI_STATE_URL_RADIO]) == 1 Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_BROWSE_BUTTON], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_PARAMETER_LABEL], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FOLDER_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FOLDER_BROWSE_BUTTON], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SPECIAL_COMBO], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_WINDOW_COMBO], $GUI_DISABLE)
        _windowDown()
        GUICtrlSetState($g_aGuiState[$GUI_STATE_URL_COMBO], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_URL_INPUT], $GUI_ENABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_TEXT_EDIT], $GUI_DISABLE)
    EndIf
EndFunc

Func _txtRdo()
    If GUICtrlRead($g_aGuiState[$GUI_STATE_TEXT_RADIO]) == 1 Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_BROWSE_BUTTON], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_PARAMETER_LABEL], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FOLDER_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FOLDER_BROWSE_BUTTON], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SPECIAL_COMBO], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_WINDOW_COMBO], $GUI_DISABLE)
        _windowDown()
        GUICtrlSetState($g_aGuiState[$GUI_STATE_URL_COMBO], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_URL_INPUT], $GUI_DISABLE)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_TEXT_EDIT], $GUI_ENABLE)
    EndIf
EndFunc

Func _delBtn()
    Local $iSelected = _HotkeyEditor_SelectedIndex()
    If @error Then Return False
    If MsgBox(48+4, 'Confirmation', 'Delete the selected hotkey?', 0, $g_aGuiState[$GUI_STATE_MAIN_WINDOW]) == 6 Then
        Local $sDeletedHotkey = _HotkeyCodec_EncodeHotkey(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $iSelected, 1))
        If Not _GUICtrlListView_DeleteItem($g_aGuiState[$GUI_STATE_LIST_VIEW], $iSelected) Then Return False
        _HotkeyEditor_RemoveRestrictions($sDeletedHotkey)
        Local $iCount = _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW])
        If $iCount Then
            If $iSelected >= $iCount Then $iSelected = $iCount - 1
            _GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], $iSelected)
            _GUICtrlListView_SetItemFocused($g_aGuiState[$GUI_STATE_LIST_VIEW], $iSelected)
        EndIf
        _MainWindow_UpdateSaveState()
    EndIf
    Return True
EndFunc

Func _addBtn()
    _HotkeyEditor_ResetRestrictions()
    _editGui('Add Hotkey')
    GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_RADIO], $GUI_CHECKED)
    _fileRdo()
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_EDITOR_OK_BUTTON], "_add")
    GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    GUISetState(@SW_SHOW, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    _HotkeyEditor_UpdateOkState()
EndFunc

Func _editBtn()
    Local $iSelected = _HotkeyEditor_SelectedIndex()
    If @error Then Return False
    Local $hotkey = _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $iSelected, 1)
    _HotkeyEditor_ResetRestrictions()
    Local $iRestrictionRow = _HotkeyEditor_FindRestrictions(_HotkeyCodec_EncodeHotkey($hotkey)), $iRestriction
    If $iRestrictionRow Then
        For $iRestriction = 0 To 6
            $g_aEditorRestrictions[$iRestriction] = $g_aRestrictionRows[$iRestrictionRow][$iRestriction + 1]
        Next
    EndIf
    ;~ ConsoleWrite($hotkey)
    Local $path = _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $iSelected, 2)
    If $path = $ACTION_CATALOG_LEGACY_HIGH Then $path = "Set Process Priority to High"
    Local $match = False
    Local $special = False
    Local $c, $s, $moveresize, $move, $resize, $hkzsplit
    Local $k = _HotkeyCodec_DecodeKey(StringReplace(StringReplace(StringReplace(StringReplace($hotkey,'Ctrl + ',''),'Alt + ',''),'Shift + ',''),'Win + ',''))
    ;~ ConsoleWrite($k)
    ;define clsid list
    For $c = 0 To UBound($clsid, 1)-1
        If _strCompare($path, $clsid[$c][0]) Then
            $match = True
            ExitLoop
        EndIf
    Next
    For $s = 0 To UBound($sPaths, 1)-1
        ;~ ConsoleWrite($path&' - '&$sPaths[$s][0]&@LF)
        If _strCompare($path, $sPaths[$s][0]) Then
            $special = True
            ExitLoop
        EndIf
    Next
    _editGui('Edit Hotkey')
    If StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 3), 'Admin') Then GUICtrlSetState($g_aGuiState[$GUI_STATE_ADMIN_CHECKBOX], $GUI_CHECKED)
    If StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 3), 'Singleton') Then GUICtrlSetState($g_aGuiState[$GUI_STATE_SINGLETON_CHECKBOX], $GUI_CHECKED)
    If $special Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SPECIAL_RADIO], $GUI_CHECKED)
        _GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_SPECIAL_COMBO], $sPaths[$s][0])
        _specialRdo()
    ElseIf $match Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FOLDER_RADIO], $GUI_CHECKED)
        GUICtrlSetData($g_aGuiState[$GUI_STATE_FOLDER_INPUT], $path)
        _folderRdo()
    ElseIf StringInStr(FileGetAttrib(StringReplace($path, '<USERNAME>', @UserName)), 'D') Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FOLDER_RADIO], $GUI_CHECKED)
        GUICtrlSetData($g_aGuiState[$GUI_STATE_FOLDER_INPUT], $path)
        _folderRdo()
    ElseIf _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 0) == 'Window' Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_WINDOW_RADIO], $GUI_CHECKED)
        If StringInStr($path, 'Move to ') Or StringInStr($path, 'Resize to ') Then
            _GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_WINDOW_COMBO], $ACTION_CATALOG_CUSTOM_WINDOW)
            If StringInStr($path, 'Move to ') Then
                GUICtrlSetState($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX], $GUI_CHECKED)
            Else
                GUICtrlSetState($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX], $GUI_UNCHECKED)
            EndIf
            _moveCbox()
            If StringInStr($path, 'Resize to ') Then
                GUICtrlSetState($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX], $GUI_CHECKED)
            Else
                GUICtrlSetState($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX], $GUI_UNCHECKED)
            EndIf
            _resizeCbox()
            If StringInStr($path, ' & ') Then
                $moveresize = StringSplit(StringReplace(StringReplace($path, 'Move to ', ''), 'Resize to ', ''), ' & ', 1)
                $move = StringSplit($moveresize[1], ',')
                $resize = StringSplit($moveresize[2], 'x')
                If IsArray($move) And $move[0] == 2 And IsArray($resize) And $resize[0] == 2 Then
                    GUICtrlSetData($g_aGuiState[$GUI_STATE_MOVE_X_INPUT], $move[1])
                    GUICtrlSetData($g_aGuiState[$GUI_STATE_MOVE_Y_INPUT], $move[2])
                    GUICtrlSetData($g_aGuiState[$GUI_STATE_RESIZE_WIDTH_INPUT], $resize[1])
                    GUICtrlSetData($g_aGuiState[$GUI_STATE_RESIZE_HEIGHT_INPUT], $resize[2])
                EndIf
            ElseIf StringInStr($path, ',') Then
                $move = StringSplit(StringReplace($path, 'Move to ', ''), ',')
                If IsArray($move) And $move[0] == 2 Then
                    GUICtrlSetData($g_aGuiState[$GUI_STATE_MOVE_X_INPUT], $move[1])
                    GUICtrlSetData($g_aGuiState[$GUI_STATE_MOVE_Y_INPUT], $move[2])
                EndIf
            ElseIf StringInStr($path, 'x') Then
                $resize = StringSplit(StringReplace($path, 'Resize to ', ''), 'x')
                If IsArray($resize) And $resize[0] == 2 Then
                    GUICtrlSetData($g_aGuiState[$GUI_STATE_RESIZE_WIDTH_INPUT], $resize[1])
                    GUICtrlSetData($g_aGuiState[$GUI_STATE_RESIZE_HEIGHT_INPUT], $resize[2])
                EndIf
            EndIf
        Else
            _GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_WINDOW_COMBO], $path)
        EndIf
        _windowRdo()
        _windowDown()
    ElseIf (StringInStr($path, 'https://') Or StringInStr($path, 'http://') Or StringInStr($path, 'ftp://')) And Not StringInStr($path, '[Parameters]') Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_URL_RADIO], $GUI_CHECKED)
        If StringInStr($path, 'https://') Then
            _GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_URL_COMBO], 'https://')
        ElseIf StringInStr($path, 'http://') Then
            _GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_URL_COMBO], 'http://')
        ElseIf StringInStr($path, 'ftp://') Then
            _GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_URL_COMBO], 'ftp://')
        EndIf
        GUICtrlSetData($g_aGuiState[$GUI_STATE_URL_INPUT], StringReplace(StringReplace(StringReplace($path, 'https://', ''), 'http://', ''), 'ftp://', ''))
        _urlRdo()
    ElseIf _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 0) == 'Text' Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_TEXT_RADIO], $GUI_CHECKED)
        GUICtrlSetData($g_aGuiState[$GUI_STATE_TEXT_EDIT], StringReplace($path, '[New Line]', @CRLF))
        _txtRdo()
    ElseIf StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 0), 'Command') Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_RADIO], $GUI_CHECKED)
        GUICtrlSetState($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX], $GUI_CHECKED)
        GUICtrlSetData($g_aGuiState[$GUI_STATE_FILE_INPUT], StringReplace($path, '[HkzCmd]', ''))
        _cmdCbox()
    Else
        ;split $path with [Parameters]
        If StringInStr($path, ' [Parameters] ') Then
            $hkzsplit = StringSplit($path, ' [Parameters] ', 1)
            $path = $hkzsplit[1]
            If $hkzsplit[0] == 2 Then GUICtrlSetData($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT],$hkzsplit[2])
        EndIf
        GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_RADIO], $GUI_CHECKED)
        GUICtrlSetData($g_aGuiState[$GUI_STATE_FILE_INPUT], $path)
        _fileRdo()
    EndIf
    If StringInStr($hotkey,'Ctrl') Then GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX], $GUI_CHECKED)
    If StringInStr($hotkey,'Alt') Then GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_ALT_CHECKBOX], $GUI_CHECKED)
    If StringInStr($hotkey,'Shift') Then GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_SHIFT_CHECKBOX], $GUI_CHECKED)
    If StringInStr($hotkey,'Win') Then GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_WIN_CHECKBOX], $GUI_CHECKED)
    _GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO], $k)
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_EDITOR_OK_BUTTON], "_edit")
    GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    GUISetState(@SW_SHOW, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    _HotkeyEditor_UpdateOkState()
EndFunc

Func _add()
    Return _HotkeyEditor_Commit(-1)
EndFunc

Func _edit()
    Local $iSelected = _HotkeyEditor_SelectedIndex()
    If @error Then Return _HotkeyEditor_ShowError("Select a hotkey before editing it")
    Return _HotkeyEditor_Commit($iSelected)
EndFunc

Func _HotkeyEditor_Commit($iListIndex)
    Local $aRecord = _HotkeyEditor_ReadRecord()
    If @error Or Not IsArray($aRecord) Then Return _HotkeyEditor_ShowError(_HotkeyEditor_ErrorMessage(@error, @extended))
    If _HotkeyEditor_HasDuplicate($aRecord[$HOTKEY_FIELD_HOTKEY], $iListIndex) Then Return _HotkeyEditor_ShowError("That hotkey is already assigned")
    Local $sRow = _HotkeyEditor_RecordRow($aRecord)
    If @error Then Return _HotkeyEditor_ShowError("The selected action could not be displayed")
    Local $sOldHotkey = ""
    If $iListIndex >= 0 Then $sOldHotkey = _HotkeyCodec_EncodeHotkey(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $iListIndex, 1))
    If $iListIndex < 0 Then
        If GUICtrlCreateListViewItem($sRow, $g_aGuiState[$GUI_STATE_LIST_VIEW]) = 0 Then Return _HotkeyEditor_ShowError("The hotkey could not be added")
    Else
        Local $aColumns = StringSplit($sRow, "|", 1)
        If Not IsArray($aColumns) Or $aColumns[0] <> 4 Then Return _HotkeyEditor_ShowError("The hotkey row is malformed")
        Local $i
        For $i = 1 To 4
            If Not _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $iListIndex, $aColumns[$i], $i - 1) Then Return _HotkeyEditor_ShowError("The hotkey could not be updated")
        Next
    EndIf
    If $sOldHotkey <> "" Then _HotkeyEditor_RemoveRestrictions($sOldHotkey)
    _HotkeyEditor_SetRestrictions($aRecord[$HOTKEY_FIELD_HOTKEY], $aRecord)
    _MainWindow_UpdateSaveState()
    _hideChild()
    Return True
EndFunc

Func _HotkeyEditor_ReadRecord()
    Local $sHotkey = ""
    If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX]), $GUI_CHECKED) Then $sHotkey &= "Ctrl + "
    If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_ALT_CHECKBOX]), $GUI_CHECKED) Then $sHotkey &= "Alt + "
    If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_SHIFT_CHECKBOX]), $GUI_CHECKED) Then $sHotkey &= "Shift + "
    If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_WIN_CHECKBOX]), $GUI_CHECKED) Then $sHotkey &= "Win + "
    $sHotkey &= GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO])
    Local $sAction = "", $sTarget = "", $sParameters = ""
    Local $iOptions = $HOTKEY_OPTION_NONE
    If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_ADMIN_CHECKBOX]), $GUI_CHECKED) Then $iOptions = BitOR($iOptions, $HOTKEY_OPTION_ADMIN)
    If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_SINGLETON_CHECKBOX]), $GUI_CHECKED) Then $iOptions = BitOR($iOptions, $HOTKEY_OPTION_SINGLETON)
    If GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_RADIO]) = $GUI_CHECKED Then
        $sTarget = GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_INPUT])
        If GUICtrlRead($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX]) = $GUI_CHECKED Then
            $sAction = $HOTKEY_ACTION_COMMAND
        Else
            $sAction = $HOTKEY_ACTION_FILE
            $sParameters = GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT])
        EndIf
    ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_FOLDER_RADIO]) = $GUI_CHECKED Then
        $sAction = $HOTKEY_ACTION_FOLDER
        $sTarget = _HotkeyEditor_ResolveFolder(GUICtrlRead($g_aGuiState[$GUI_STATE_FOLDER_INPUT]))
    ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_SPECIAL_RADIO]) = $GUI_CHECKED Then
        Local $aSpecial = _HotkeyEditor_ResolveSpecial(_HotkeyCodec_EncodeHotkey($sHotkey), GUICtrlRead($g_aGuiState[$GUI_STATE_SPECIAL_COMBO]))
        If @error Or Not IsArray($aSpecial) Then Return SetError($EDITOR_MODEL_ERROR_RECORD, @error, 0)
        Local $aSpecialValues = _HotkeyEditorModel_CreateValues($aSpecial[$HOTKEY_FIELD_HOTKEY], $aSpecial[$HOTKEY_FIELD_ACTION], $aSpecial[$HOTKEY_FIELD_TARGET], $aSpecial[$HOTKEY_FIELD_PARAMETERS], $iOptions)
        Local $aSpecialRecord = _HotkeyEditorModel_ToRecord($aSpecialValues, True)
        If @error Or Not IsArray($aSpecialRecord) Then Return SetError($EDITOR_MODEL_ERROR_RECORD, @error, 0)
        _HotkeyEditor_CopyCurrentRestrictions($aSpecialRecord)
        If Not _HotkeyModel_IsValid($aSpecialRecord) Then Return SetError($EDITOR_MODEL_ERROR_RECORD, @error, 0)
        Return $aSpecialRecord
    ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_RADIO]) = $GUI_CHECKED Then
        $sAction = $HOTKEY_ACTION_WINDOW
        $sTarget = GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_COMBO])
    ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_URL_RADIO]) = $GUI_CHECKED Then
        $sAction = $HOTKEY_ACTION_URL
        $sTarget = GUICtrlRead($g_aGuiState[$GUI_STATE_URL_COMBO]) & StringRegExpReplace(GUICtrlRead($g_aGuiState[$GUI_STATE_URL_INPUT]), "(?i)^(?:https?|ftp)://", "")
    ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_TEXT_RADIO]) = $GUI_CHECKED Then
        $sAction = $HOTKEY_ACTION_TEXT
        $sTarget = StringReplace(GUICtrlRead($g_aGuiState[$GUI_STATE_TEXT_EDIT]), @CRLF, @LF)
    Else
        Return SetError($EDITOR_MODEL_ERROR_INPUT, 0, 0)
    EndIf
    Local $aValues = _HotkeyEditorModel_CreateValues(_HotkeyCodec_EncodeHotkey($sHotkey), $sAction, $sTarget, $sParameters, $iOptions, GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX]) = $GUI_CHECKED, GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_X_INPUT]), GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_Y_INPUT]), GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX]) = $GUI_CHECKED, GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_WIDTH_INPUT]), GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_HEIGHT_INPUT]))
    Local $aRecord = _HotkeyEditorModel_ToRecord($aValues, True)
    If @error Or Not IsArray($aRecord) Then Return SetError($EDITOR_MODEL_ERROR_RECORD, @error, 0)
    _HotkeyEditor_CopyCurrentRestrictions($aRecord)
    If Not _HotkeyModel_IsValid($aRecord) Then Return SetError($EDITOR_MODEL_ERROR_RECORD, @error, 0)
    Return $aRecord
EndFunc

Func _HotkeyEditor_CopyCurrentRestrictions(ByRef $aRecord)
    Local $i
    For $i = 0 To 6
        $aRecord[$HOTKEY_FIELD_CTRL_SIDE + $i] = $g_aEditorRestrictions[$i]
    Next
    ; Unchecking a modifier removes its side restriction.
    Local $aModifierControls[4] = [$GUI_STATE_EDITOR_CTRL_CHECKBOX, $GUI_STATE_EDITOR_ALT_CHECKBOX, $GUI_STATE_EDITOR_SHIFT_CHECKBOX, $GUI_STATE_EDITOR_WIN_CHECKBOX]
    For $i = 0 To 3
        If Not BitAND(GUICtrlRead($g_aGuiState[$aModifierControls[$i]]), $GUI_CHECKED) Then $aRecord[$HOTKEY_FIELD_CTRL_SIDE + $i] = 0
    Next
EndFunc

Func _HotkeyEditor_ResolveFolder($sDisplay)
    Local $i
    For $i = 0 To UBound($clsid, 1) - 1
        If $sDisplay = $clsid[$i][0] Then Return $clsid[$i][1]
    Next
    Return $sDisplay
EndFunc

Func _HotkeyEditor_ResolveSpecial($sHotkey, $sLabel)
    Local $i
    For $i = 0 To UBound($sPaths, 1) - 1
        If $sLabel = $sPaths[$i][0] Then
            Local $aRecord = _HotkeyCodec_DecodeLegacy($sHotkey, StringReplace($sPaths[$i][1], " [Parameters] ", $HOTKEY_CODEC_PARAMETER), _HotkeyRepository_ClassifyPlainValue($sPaths[$i][1]))
            Return SetError(@error, @extended, $aRecord)
        EndIf
    Next
    Return SetError(1, 0, 0)
EndFunc

Func _HotkeyEditor_HasDuplicate($sHotkey, $iExcludeIndex)
    Local $sNormalized = _HotkeyCodec_NormalizeHotkey($sHotkey)
    Local $i
    For $i = 0 To _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) - 1
        If $i <> $iExcludeIndex And $sNormalized = _HotkeyCodec_NormalizeHotkey(_HotkeyCodec_EncodeHotkey(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $i, 1))) Then Return True
    Next
    Return $sNormalized = _HotkeyCodec_NormalizeHotkey(_HotkeyCodec_EncodeHotkey(_returnToggleHotkey()))
EndFunc

Func _HotkeyEditor_RecordRow(ByRef $aRecord)
    Local $sType = _HotkeyModel_ActionLabel($aRecord[$HOTKEY_FIELD_ACTION])
    Local $sItem = $aRecord[$HOTKEY_FIELD_TARGET]
    Local $i
    For $i = 0 To UBound($clsid, 1) - 1
        If $sItem = $clsid[$i][1] Then
            $sItem = $clsid[$i][0]
            ExitLoop
        EndIf
    Next
    For $i = 0 To UBound($sPaths, 1) - 1
        Local $aSpecial = _HotkeyEditor_ResolveSpecial($aRecord[$HOTKEY_FIELD_HOTKEY], $sPaths[$i][0])
        If IsArray($aSpecial) And $aRecord[$HOTKEY_FIELD_ACTION] = $aSpecial[$HOTKEY_FIELD_ACTION] And $aRecord[$HOTKEY_FIELD_TARGET] = $aSpecial[$HOTKEY_FIELD_TARGET] And $aRecord[$HOTKEY_FIELD_PARAMETERS] = $aSpecial[$HOTKEY_FIELD_PARAMETERS] Then
            $sType = "System"
            $sItem = $sPaths[$i][0]
            ExitLoop
        EndIf
    Next
    If $aRecord[$HOTKEY_FIELD_ACTION] = $HOTKEY_ACTION_FILE And $aRecord[$HOTKEY_FIELD_PARAMETERS] <> "" Then $sItem &= " [Parameters] " & $aRecord[$HOTKEY_FIELD_PARAMETERS]
    If $aRecord[$HOTKEY_FIELD_ACTION] = $HOTKEY_ACTION_TEXT Then $sItem = StringReplace($sItem, @LF, "[New Line]")
    Local $sOptions = ""
    If _HotkeyModel_HasOption($aRecord, $HOTKEY_OPTION_ADMIN) Then $sOptions = "Admin"
    If _HotkeyModel_HasOption($aRecord, $HOTKEY_OPTION_SINGLETON) Then
        If $sOptions <> "" Then $sOptions &= ", "
        $sOptions &= "Singleton"
    EndIf
    Local $sRestrictions = _HotkeyEditor_RestrictionSummary($aRecord)
    If $sRestrictions <> "" Then
        If $sOptions <> "" Then $sOptions &= ", "
        $sOptions &= $sRestrictions
    EndIf
    Return $sType & "|" & _HotkeyCodec_DecodeHotkey($aRecord[$HOTKEY_FIELD_HOTKEY]) & "|" & $sItem & "|" & $sOptions
EndFunc

Func _HotkeyEditor_SelectedIndex()
    Local $sSelected = _GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])
    If $sSelected = "" Then Return SetError(1, 0, -1)
    Local $aSelected = StringSplit($sSelected, "|")
    Local $iSelected = Number($aSelected[1])
    If $iSelected < 0 Or $iSelected >= _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) Then Return SetError(2, 0, -1)
    Return $iSelected
EndFunc

Func _HotkeyEditor_ErrorMessage($iError, $iExtended)
    #forceref $iExtended
    Switch $iError
        Case $EDITOR_MODEL_ERROR_HOTKEY
            Return "Assign a hotkey with at least one modifier"
        Case $EDITOR_MODEL_ERROR_NUMBER
            Return "Custom window coordinates must be integers and sizes must be positive integers"
        Case $EDITOR_MODEL_ERROR_DUPLICATE
            Return "That hotkey is already assigned"
    EndSwitch
    Return "Complete the selected action with valid values"
EndFunc

Func _HotkeyEditor_ShowError($sMessage)
    MsgBox(48, "Invalid hotkey", $sMessage, 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    Return False
EndFunc

Func _HotkeyEditor_UpdateOkState()
    If $g_bHotkeyEditorUpdating Or Not IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Or Not $g_aGuiState[$GUI_STATE_EDITOR_OK_BUTTON] Then Return False
    $g_bHotkeyEditorUpdating = True
    Local $aRecord = _HotkeyEditor_ReadRecord()
    Local $bValid = IsArray($aRecord)
    If $bValid Then
        Local $iExclude = -1
        If WinGetTitle($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) = "Edit Hotkey" Then $iExclude = _HotkeyEditor_SelectedIndex()
        If _HotkeyEditor_HasDuplicate($aRecord[$HOTKEY_FIELD_HOTKEY], $iExclude) Then $bValid = False
    EndIf
    If $bValid Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_OK_BUTTON], $GUI_ENABLE)
    Else
        GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_OK_BUTTON], $GUI_DISABLE)
    EndIf
    $g_bHotkeyEditorUpdating = False
    Return $bValid
EndFunc

Func _HotkeyEditor_WM_COMMAND($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $iMsg, $iwParam, $ilParam
    If $hWnd = $g_aGuiState[$GUI_STATE_EDITOR_WINDOW] Then
        _HotkeyEditor_UpdateOkState()
    ElseIf $hWnd = $g_aGuiState[$GUI_STATE_MAIN_WINDOW] Then
        _MainWindow_UpdateSaveState()
    EndIf
    Return $GUI_RUNDEFMSG
EndFunc

Func _hideChild()
    GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    GUIDelete($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    WinActivate($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
EndFunc

Func _fileBrowse()
    Local $sFile = FileOpenDialog('Select a file...', '', "All (*.*)", $FD_FILEMUSTEXIST, '', $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    If @error Then
        ;do nothing
    Else
        GUICtrlSetData($g_aGuiState[$GUI_STATE_FILE_INPUT], $sFile)
    EndIf
EndFunc

Func _folderBrowse()
    Local $sFolder = FileSelectFolder('Select a folder...', "", Default, '', $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    Local $c
    If @error Then
        ;do nothing
    Else
        ;define clsid list
        For $c = 0 To UBound($clsid, 1)-1
            If _strCompare($sFolder, $clsid[$c][1]) Then
                $sFolder = $clsid[$c][0]
                ExitLoop
            EndIf
        Next
        GUICtrlSetData($g_aGuiState[$GUI_STATE_FOLDER_INPUT], $sFolder)
    EndIf
EndFunc
