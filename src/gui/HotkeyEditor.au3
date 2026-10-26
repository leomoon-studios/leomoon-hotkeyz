#include-once

#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiComboBox.au3>
#include <GuiListView.au3>
#include <WindowsConstants.au3>

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
    GUICtrlSetData(-1, "Control Panel (Category View)|Control Panel (Icon View)|Windows Settings|Fonts Folder|Network Places|Network Connections|Printers and Faxes|Recycle Bin|Empty Recycle Bin|Empty Clipboard|Volume Up|Volume Down|Volume Mute|Media Play/Pause|Media Next|Media Previous|Media Stop|Turn Off Monitors|Turn Off Monitors And Lock|Start Screensaver|Start Screensaver And Lock|Lock|Log Off|Restart|Shutdown")
    GUICtrlSetState(-1, $GUI_DISABLE)
    $g_aGuiState[$GUI_STATE_WINDOW_RADIO] = GUICtrlCreateRadio("Run actions on active window", 16, 280, 369, 17)
    $g_aGuiState[$GUI_STATE_WINDOW_COMBO] = GUICtrlCreateCombo("", 17, 306, 367, 25, BitOR($CBS_DROPDOWNLIST,$WS_VSCROLL))
    GUICtrlSetData(-1, "Close|Minimize|Terminate|Transparency +|Transparency -|Toggle On Top|Take Screenshot|Set Process Priority to Low|Set Process Priority to Below Normal|Set Process Priority to Normal|Set Process Priority to Above Normal|Set Process Priority to Hight|Set Process Priority to Realtime|Move Center|Move Top Left|Move Top Mid|Move Top Right|Move Bottom Left|Move Bottom Mid|Move Bottom Right|Move to Next Monitor|Move to Previous Monitor|Snap Fullscreen|Snap Top (1x2)|Snap Bottom (1x2)|Snap Left (2x1)|Snap Right (2x1)|Snap Left (3x1)|Snap Mid (3x1)|Snap Right (3x1)|Snap Top Left (2x2)|Snap Top Right (2x2)|Snap Bottom Left (2x2)|Snap Bottom Right (2x2)|Snap Top Left (3x2)|Snap Top Mid (3x2)|Snap Top Right (3x2)|Snap Bottom Left (3x2)|Snap Bottom Mid (3x2)|Snap Bottom Right (3x2)|Toggle Ghost (Advanced)|Custom Move and/or Resize|Generate Random Password (PPP)|Generate Random Password (Letters)|Generate Random Password (Numbers)|Generate Random Password (Letters and Numbers)|Generate Random UUID|Upper Case Selected Text|Lower Case Selected Text|Title Case Selected Text|Reverse Selected Text|MD5 Selected Text|SHA1 Selected Text|SHA-256 Selected Text|SHA-512 Selected Text|Base64 Encode Selected Text|Base64 Decode Selected Text")
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
    GUICtrlSetData(-1, "`|1|2|3|4|5|6|7|8|9|0|-|=|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|[|]|\|;|"&Chr(39)&"|,|.|/|Space|Backspace|Enter|Up|Down|Left|Right|Escape|F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|Print Screen key|Pause key|Insert|Delete|Home|End|Page Up|Page Down|Numpad 1|Numpad 2|Numpad 3|Numpad 4|Numpad 5|Numpad 6|Numpad 7|Numpad 8|Numpad 9|Numpad 0|Numpad Dot|Numpad Divide|Numpad Multiply|Numpad Subtract|Numpad Add")
    GUICtrlCreateGroup("", -99, -99, 1, 1)
    $g_aGuiState[$GUI_STATE_EDITOR_CANCEL_BUTTON] = GUICtrlCreateButton("Cancel", 209, 632, 193, 33)
    $g_aGuiState[$GUI_STATE_EDITOR_OK_BUTTON] = GUICtrlCreateButton("OK", 8, 632, 193, 33)
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
    If GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_COMBO]) == 'Custom Move and/or Resize' And BitAND(GUICtrlGetState($g_aGuiState[$GUI_STATE_WINDOW_COMBO]), $GUI_ENABLE) Then
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
    If GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX]) == $GUI_CHECKED And BitAND(GUICtrlGetState($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX]), $GUI_ENABLE) And GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_COMBO]) == 'Custom Move and/or Resize' Then
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
    If GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX]) == $GUI_CHECKED And BitAND(GUICtrlGetState($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX]), $GUI_ENABLE) And GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_COMBO]) == 'Custom Move and/or Resize' Then
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
    If MsgBox(48+4, 'Confirmation', 'Delete the selected hotkey?', 0, $g_aGuiState[$GUI_STATE_MAIN_WINDOW]) == 6 Then
        _GUICtrlListView_DeleteItemsSelected($g_aGuiState[$GUI_STATE_LIST_VIEW])
        _GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], 1)
        _GUICtrlListView_SetItemFocused($g_aGuiState[$GUI_STATE_LIST_VIEW], 1)
    EndIf
EndFunc

Func _addBtn()
    _editGui('Add Hotkey')
    GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_RADIO], $GUI_CHECKED)
    _fileRdo()
    GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_EDITOR_OK_BUTTON], "_add")
    GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    GUISetState(@SW_SHOW, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
EndFunc

Func _add()
    Local $x, $fileParam, $hkztxt
    If GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_RADIO]) == 1 And GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_INPUT]) == '' Then
        GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        If MsgBox(48, 'Oops!', 'Please select a file.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
            GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        EndIf
    ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_FOLDER_RADIO]) == 1 And GUICtrlRead($g_aGuiState[$GUI_STATE_FOLDER_INPUT]) == '' Then
        GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        If MsgBox(48, 'Oops!', 'Please select a folder.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
            GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        EndIf
    ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_SPECIAL_RADIO]) == 1 And GUICtrlRead($g_aGuiState[$GUI_STATE_SPECIAL_COMBO]) == '' Then
        GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        If MsgBox(48, 'Oops!', 'Please select an option.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
            GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        EndIf
    ElseIf (GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_RADIO]) == 1 And GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_COMBO]) == 'Custom Move and/or Resize') And ( _
        (GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX]) == $GUI_UNCHECKED And GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX]) == $GUI_UNCHECKED) Or _
        (GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX]) == $GUI_CHECKED And (GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_X_INPUT]) == '' Or GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_Y_INPUT]) == '')) Or _
        (GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX]) == $GUI_CHECKED And (GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_WIDTH_INPUT]) == '' Or GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_HEIGHT_INPUT]) == ''))) Then
        GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        If MsgBox(48, 'Oops!', 'Please select a predefined window action or enter a custom location and/or size.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
            GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        EndIf
    ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_URL_RADIO]) == 1 And GUICtrlRead($g_aGuiState[$GUI_STATE_URL_INPUT]) == '' Then
        GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        If MsgBox(48, 'Oops!', 'Please enter a URL.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
            GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        EndIf
    ElseIf (BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX]), $GUI_CHECKED) == 0 And _
        BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_ALT_CHECKBOX]), $GUI_CHECKED) == 0 And _
        BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_SHIFT_CHECKBOX]), $GUI_CHECKED) == 0 And _
        BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_WIN_CHECKBOX]), $GUI_CHECKED) == 0) Or _
        GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO]) == '' Then
            GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            If MsgBox(48, 'Oops!', 'Please assign a hotkey.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
                GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
                WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            EndIf
    Else
        Local $childRead = ''
        Local $error = False
        Local $opts = ''
        If GUICtrlRead($g_aGuiState[$GUI_STATE_ADMIN_CHECKBOX]) == 1 Then $opts &= 'Admin'
        If GUICtrlRead($g_aGuiState[$GUI_STATE_SINGLETON_CHECKBOX]) == 1 Then
            If $opts == 'Admin' Then $opts &= ', '
            $opts &= 'Singleton'
        EndIf
        If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX]), $GUI_CHECKED) == 1 Then $childRead &= 'Ctrl + '
        If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_ALT_CHECKBOX]), $GUI_CHECKED) == 1 Then $childRead &= 'Alt + '
        If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_SHIFT_CHECKBOX]), $GUI_CHECKED) == 1 Then $childRead &= 'Shift + '
        If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_WIN_CHECKBOX]), $GUI_CHECKED) == 1 Then $childRead &= 'Win + '
        $childRead &= _HotkeyCodec_DecodeKey(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO]))
        For $x = 0 To _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) - 1
            If $childRead == _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $x, 1) Then
                $error = True
                ExitLoop
            EndIf
        Next
        If $error Or $childRead == _returnToggleHotkey() Then
            GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            If MsgBox(48, 'Oops!', 'Hotkey alreay assigned. Please choose another hotkey.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
                $error = False
                GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
                WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            EndIf
        ElseIf Not StringRegExp(GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_X_INPUT]), '^[\d-]?\d*?$') Or Not StringRegExp(GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_Y_INPUT]), '^[\d-]?\d*?$') Then
            If MsgBox(48, 'Oops!', 'X and Y fields must be an integer.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
                GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
                WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            EndIf
        Else
            If GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_RADIO]) == 1 Then
                $fileParam = GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_INPUT])
                If GUICtrlRead($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX]) == $GUI_CHECKED Then
                    GUICtrlCreateListViewItem('Advanced Command'&'|'&$childRead&'|'&$fileParam&'|'&$opts, $g_aGuiState[$GUI_STATE_LIST_VIEW])
                Else
                    If GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT]) <> '' Then $fileParam = $fileParam&' [Parameters] '&GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT])
                    GUICtrlCreateListViewItem('File'&'|'&$childRead&'|'&$fileParam&'|'&$opts, $g_aGuiState[$GUI_STATE_LIST_VIEW])
                EndIf
            ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_FOLDER_RADIO]) == 1 Then
                GUICtrlCreateListViewItem('Folder|'&$childRead&'|'&GUICtrlRead($g_aGuiState[$GUI_STATE_FOLDER_INPUT]), $g_aGuiState[$GUI_STATE_LIST_VIEW])
            ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_SPECIAL_RADIO]) == 1 Then
                GUICtrlCreateListViewItem('System|'&$childRead&'|'&GUICtrlRead($g_aGuiState[$GUI_STATE_SPECIAL_COMBO]), $g_aGuiState[$GUI_STATE_LIST_VIEW])
            ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_RADIO]) == 1 Then
                If GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_COMBO]) == 'Custom Move and/or Resize' Then
                    Local $m = ''
                    Local $r = ''
                    If GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX]) == $GUI_CHECKED Then $m = 'Move to '&GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_X_INPUT])&','&GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_Y_INPUT])
                    If GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX]) == $GUI_CHECKED Then $r = 'Resize to '&GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_WIDTH_INPUT])&'x'&GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_HEIGHT_INPUT])
                    If $m <> '' and $r <> '' Then
                        $m = $m&' & '&$r
                    Else
                        $m = $m&$r
                    EndIf
                    GUICtrlCreateListViewItem('Window|'&$childRead&'|'&$m, $g_aGuiState[$GUI_STATE_LIST_VIEW])
                Else
                    GUICtrlCreateListViewItem('Window|'&$childRead&'|'&GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_COMBO]), $g_aGuiState[$GUI_STATE_LIST_VIEW])
                EndIf
            ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_URL_RADIO]) == 1 Then
                GUICtrlCreateListViewItem('URL|'&$childRead&'|'&GUICtrlRead($g_aGuiState[$GUI_STATE_URL_COMBO])&GUICtrlRead($g_aGuiState[$GUI_STATE_URL_INPUT]), $g_aGuiState[$GUI_STATE_LIST_VIEW])
            ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_TEXT_RADIO]) == 1 Then
                $hkztxt = StringReplace(GUICtrlRead($g_aGuiState[$GUI_STATE_TEXT_EDIT]), @CRLF, '[New Line]')
                GUICtrlCreateListViewItem('Text|'&$childRead&'|'&$hkztxt, $g_aGuiState[$GUI_STATE_LIST_VIEW])
            EndIf
            _hideChild()
        EndIf
    EndIf
EndFunc

Func _editBtn()
    Local $hotkey = _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 1)
    ;~ ConsoleWrite($hotkey)
    Local $path = _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 2)
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
            _GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_WINDOW_COMBO], 'Custom Move and/or Resize')
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
EndFunc

Func _edit()
    Local $x, $fileParam, $hkztxt
    If GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_RADIO]) == 1 And GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_INPUT]) == '' Then
        GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        If MsgBox(48, 'Oops!', 'Please select a file.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
            GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        EndIf
    ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_FOLDER_RADIO]) == 1 And GUICtrlRead($g_aGuiState[$GUI_STATE_FOLDER_INPUT]) == '' Then
        GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        If MsgBox(48, 'Oops!', 'Please select a folder.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
            GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        EndIf
    ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_SPECIAL_RADIO]) == 1 And GUICtrlRead($g_aGuiState[$GUI_STATE_SPECIAL_COMBO]) == '' Then
        GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        If MsgBox(48, 'Oops!', 'Please select an option.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
            GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        EndIf
    ElseIf (GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_RADIO]) == 1 And GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_COMBO]) == 'Custom Move and/or Resize') And ( _
            (GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX]) == $GUI_UNCHECKED And GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX]) == $GUI_UNCHECKED) Or _
            (GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX]) == $GUI_CHECKED And (GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_X_INPUT]) == '' Or GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_Y_INPUT]) == '')) Or _
            (GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX]) == $GUI_CHECKED And (GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_WIDTH_INPUT]) == '' Or GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_HEIGHT_INPUT]) == ''))) Then
            GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            If MsgBox(48, 'Oops!', 'Please select a predefined window action or enter a custom location and/or size.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
                GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
                WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            EndIf
    ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_URL_RADIO]) == 1 And GUICtrlRead($g_aGuiState[$GUI_STATE_URL_INPUT]) == '' Then
        GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        If MsgBox(48, 'Oops!', 'Please enter a URL.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
            GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
        EndIf
    ElseIf (BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX]), $GUI_CHECKED) == 0 And _
        BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_ALT_CHECKBOX]), $GUI_CHECKED) == 0 And _
        BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_SHIFT_CHECKBOX]), $GUI_CHECKED) == 0 And _
        BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_WIN_CHECKBOX]), $GUI_CHECKED) == 0) Or _
        GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO]) == '' Then
            GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            If MsgBox(48, 'Oops!', 'Please assign a hotkey.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
                GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
                WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            EndIf
    Else
        Local $childRead = ''
        Local $error = False
        Local $opts = ''
        If GUICtrlRead($g_aGuiState[$GUI_STATE_ADMIN_CHECKBOX]) == 1 Then $opts &= 'Admin'
        If GUICtrlRead($g_aGuiState[$GUI_STATE_SINGLETON_CHECKBOX]) == 1 Then
            If $opts == 'Admin' Then $opts &= ', '
            $opts &= 'Singleton'
        EndIf
        If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX]), $GUI_CHECKED) == 1 Then $childRead &= 'Ctrl + '
        If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_ALT_CHECKBOX]), $GUI_CHECKED) == 1 Then $childRead &= 'Alt + '
        If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_SHIFT_CHECKBOX]), $GUI_CHECKED) == 1 Then $childRead &= 'Shift + '
        If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_WIN_CHECKBOX]), $GUI_CHECKED) == 1 Then $childRead &= 'Win + '
        $childRead &= GUICtrlRead($g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO])
        For $x = 0 To _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) - 1
            If $x <> Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])) And $childRead == _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $x, 1) Then
                $error = True
                ExitLoop
            EndIf
        Next
        If $error Or $childRead == _returnToggleHotkey() Then
            GUISetState(@SW_DISABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            If MsgBox(48, 'Oops!', 'Hotkey alreay assigned. Please choose another hotkey.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
                $error = False
                GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
                WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            EndIf
        ElseIf Not StringRegExp(GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_X_INPUT]), '^[\d-]?\d*?$') Or Not StringRegExp(GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_Y_INPUT]), '^[\d-]?\d*?$') Then
            If MsgBox(48, 'Oops!', 'X and Y fields must be an integer.', 0, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) == 1 Then
                GUISetState(@SW_ENABLE, $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
                WinActivate($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
            EndIf
        Else
            _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), $childRead, 1)
            If GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_RADIO]) == 1 Then
                $fileParam = GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_INPUT])
                If GUICtrlRead($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX]) == $GUI_CHECKED Then
                    _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), $fileParam, 2)
                    _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 'Advanced Command', 0)
                Else
                    If GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT]) <> '' Then $fileParam = $fileParam&' [Parameters] '&GUICtrlRead($g_aGuiState[$GUI_STATE_FILE_PARAMETER_INPUT])
                    _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), $fileParam, 2)
                    _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 'File', 0)
                EndIf
            ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_FOLDER_RADIO]) == 1 Then
                _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), GUICtrlRead($g_aGuiState[$GUI_STATE_FOLDER_INPUT]), 2)
                _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 'Folder', 0)
            ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_SPECIAL_RADIO]) == 1 Then
                _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), GUICtrlRead($g_aGuiState[$GUI_STATE_SPECIAL_COMBO]), 2)
                _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 'System', 0)
            ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_RADIO]) == 1 Then
                _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 'Window', 0)
                If GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_COMBO]) == 'Custom Move and/or Resize' Then
                    Local $m = ''
                    Local $r = ''
                    If GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_CHECKBOX]) == $GUI_CHECKED Then $m = 'Move to '&GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_X_INPUT])&','&GUICtrlRead($g_aGuiState[$GUI_STATE_MOVE_Y_INPUT])
                    If GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_CHECKBOX]) == $GUI_CHECKED Then $r = 'Resize to '&GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_WIDTH_INPUT])&'x'&GUICtrlRead($g_aGuiState[$GUI_STATE_RESIZE_HEIGHT_INPUT])
                    If $m <> '' and $r <> '' Then
                        $m = $m&' & '&$r
                    Else
                        $m = $m&$r
                    EndIf
                    _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), $m, 2)
                Else
                    _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), GUICtrlRead($g_aGuiState[$GUI_STATE_WINDOW_COMBO]), 2)
                EndIf
            ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_URL_RADIO]) == 1 Then
                GUICtrlSetData($g_aGuiState[$GUI_STATE_URL_INPUT], StringReplace(StringReplace(StringReplace(GUICtrlRead($g_aGuiState[$GUI_STATE_URL_INPUT]), 'https://', ''), 'http://', ''), 'ftp://', ''))
                _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), GUICtrlRead($g_aGuiState[$GUI_STATE_URL_COMBO])&GUICtrlRead($g_aGuiState[$GUI_STATE_URL_INPUT]), 2)
                _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 'URL', 0)
            ElseIf GUICtrlRead($g_aGuiState[$GUI_STATE_TEXT_RADIO]) == 1 Then
                $hkztxt = StringReplace(GUICtrlRead($g_aGuiState[$GUI_STATE_TEXT_EDIT]), @CRLF, '[New Line]')
                _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), $hkztxt, 2)
                _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 'Text', 0)
            EndIf
            _GUICtrlListView_SetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), $opts, 3)
            _hideChild()
        EndIf
    EndIf
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
