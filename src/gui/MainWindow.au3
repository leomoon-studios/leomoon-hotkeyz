#include-once

#include <GUIConstantsEx.au3>
#include <GuiComboBox.au3>
#include <GuiListView.au3>
#include <ListViewConstants.au3>
#include <WindowsConstants.au3>
#include "..\actions\ActionValidator.au3"
#include "..\app\ErrorReporter.au3"
#include "HotkeyEditorModel.au3"

Func _mainGui()
    _Debug_Log("Settings window requested; visible=" & $g_aGuiState[$GUI_STATE_WINDOW_VISIBLE])
    ;~ $g_aGuiState[$GUI_STATE_MAIN_WINDOW] = GUICreate("Hotkey Settings", 386, 242, -1, -1) ;close and minimize
    ;~ $g_aGuiState[$GUI_STATE_MAIN_WINDOW] = GUICreate("Hotkey Settings", 386, 242, -1, -1, BitOR($WS_SYSMENU,$WS_POPUP)) ;frame only
    If $g_aGuiState[$GUI_STATE_WINDOW_VISIBLE] == False Then
        $g_aGuiState[$GUI_STATE_MAIN_WINDOW] = GUICreate($APP_TITLE&" Settings", 682, 666, -1, -1, $WS_SYSMENU)
        _Debug_Log("Settings GUI created; handle=" & $g_aGuiState[$GUI_STATE_MAIN_WINDOW] & ", error=" & @error)
        GUISetFont(9, 400, 0, "Tahoma")
        GUICtrlCreateGroup("Startup", 8, 8, 658, 57)
        $g_aGuiState[$GUI_STATE_STARTUP_CHECKBOX] = GUICtrlCreateCheckbox("Start with Windows", 17, 32, 289, 17)
        GUICtrlCreateGroup("", -99, -99, 1, 1)
        GUICtrlCreateGroup("HotKeyz main hotkey", 8, 72, 658, 57)
        $g_aGuiState[$GUI_STATE_CTRL_CHECKBOX] = GUICtrlCreateCheckbox("Ctrl", 17, 96, 97, 17)
        GUICtrlSetOnEvent(-1, "_MainWindow_UpdateSaveState")
        $g_aGuiState[$GUI_STATE_ALT_CHECKBOX] = GUICtrlCreateCheckbox("Alt", 136, 96, 97, 17)
        GUICtrlSetOnEvent(-1, "_MainWindow_UpdateSaveState")
        $g_aGuiState[$GUI_STATE_SHIFT_CHECKBOX] = GUICtrlCreateCheckbox("Shift", 256, 96, 97, 17)
        GUICtrlSetOnEvent(-1, "_MainWindow_UpdateSaveState")
        $g_aGuiState[$GUI_STATE_WIN_CHECKBOX] = GUICtrlCreateCheckbox("Win", 376, 96, 97, 17)
        GUICtrlSetOnEvent(-1, "_MainWindow_UpdateSaveState")
        $g_aGuiState[$GUI_STATE_KEY_COMBO] = GUICtrlCreateCombo("", 497, 94, 159, 25, BitOR($GUI_SS_DEFAULT_COMBO,$CBS_SIMPLE))
        GUICtrlSetData(-1, $HOTKEY_CODEC_KEY_NAMES)
        GUICtrlSetOnEvent(-1, "_MainWindow_UpdateSaveState")
        GUICtrlCreateGroup("", -99, -99, 1, 1)
        GUICtrlCreateGroup("Edit hotkeys", 8, 136, 658, 450)
        Local $addBtn = GUICtrlCreateButton("Add New", 16, 160, 209, 33)
        Local $editBtn = GUICtrlCreateButton("Edit Selected", 232, 160, 209, 33)
        Local $delBtn = GUICtrlCreateButton("Delete Selected", 448, 160, 209, 33)
        $g_aGuiState[$GUI_STATE_LIST_VIEW] = GUICtrlCreateListView("", 17, 201, 639, 375, BitOR($GUI_SS_DEFAULT_LISTVIEW,$WS_HSCROLL,$WS_VSCROLL), BitOR($WS_EX_CLIENTEDGE,$LVS_EX_FULLROWSELECT))
        GUICtrlCreateGroup("", -99, -99, 1, 1)
        $g_aGuiState[$GUI_STATE_CANCEL_BUTTON] = GUICtrlCreateButton("Cancel", 449, 592, 209, 33)
        $g_aGuiState[$GUI_STATE_SAVE_BUTTON] = GUICtrlCreateButton("Save", 16, 592, 209, 33)
        ;edit ui
        GUISetIcon(@ScriptFullPath, 201)
        GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_LIST_VIEW], '_sort')
        GUICtrlSetOnEvent($addBtn, "_addBtn")
        GUICtrlSetOnEvent($editBtn, "_editBtn")
        GUICtrlSetOnEvent($delBtn, "_delBtn")
        GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_CANCEL_BUTTON], "_guiDel")
        GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_SAVE_BUTTON], '_saveBtn')
        GUISetOnEvent($GUI_EVENT_CLOSE, "_guiDel", $g_aGuiState[$GUI_STATE_MAIN_WINDOW])
        _GUICtrlListView_AddColumn($g_aGuiState[$GUI_STATE_LIST_VIEW], 'Type')
        _GUICtrlListView_AddColumn($g_aGuiState[$GUI_STATE_LIST_VIEW], 'Hotkey')
        _GUICtrlListView_AddColumn($g_aGuiState[$GUI_STATE_LIST_VIEW], 'Item')
        _GUICtrlListView_AddColumn($g_aGuiState[$GUI_STATE_LIST_VIEW], 'Options')
        _iniToGui($APP_INI_PATH) ;set gui from ini file
        _Debug_Log("Settings data loaded; error=" & @error)
        _MainWindow_UpdateSaveState()
        GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
        GUIRegisterMsg($WM_COMMAND, "_HotkeyEditor_WM_COMMAND")
        _GUICtrlListView_RegisterSortCallBack($g_aGuiState[$GUI_STATE_LIST_VIEW])
        GUISetState(@SW_SHOW)
        _Debug_Log("Settings GUI shown; error=" & @error)
        WinActivate($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
        $g_aGuiState[$GUI_STATE_WINDOW_VISIBLE] = True
        _Debug_Log("Settings GUI activation completed; error=" & @error)
    Else
        WinActivate($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
        _Debug_Log("Existing settings GUI activated; error=" & @error)
    EndIf
EndFunc

Func WM_NOTIFY($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg, $iwParam
    Local $hWndFrom, $iCode, $tNMHDR, $hWndListView
    $hWndListView = $g_aGuiState[$GUI_STATE_LIST_VIEW]
    If Not IsHWnd($g_aGuiState[$GUI_STATE_LIST_VIEW]) Then $hWndListView = GUICtrlGetHandle($g_aGuiState[$GUI_STATE_LIST_VIEW])
    $tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
    $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
    $iCode = DllStructGetData($tNMHDR, "Code")
    Switch $hWndFrom
    Case $hWndListView
        If $iCode = $NM_DBLCLK Then
            _editBtn()
            ;~ ConsoleWrite(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 1)&@LF)
            ;~ ConsoleWrite(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 2)&@LF)
        EndIf
    EndSwitch
    Return $GUI_RUNDEFMSG
EndFunc

Func _iniToGui($iniFile) ;just reads ini and sets the gui
    Local $i, $c, $s, $type, $item
    ;read main hotkey
    Local $appHotkey = IniRead($iniFile, 'Options', 'Main', '')
    Local $k = StringUpper(StringReplace(StringReplace(StringReplace(StringReplace($appHotkey,'^',''),'!',''),'+',''),'#',''))
    $k = _HotkeyCodec_DecodeKey($k)
    If StringInStr($appHotkey,'^') Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_CTRL_CHECKBOX], $GUI_CHECKED)
    Else
        GUICtrlSetState($g_aGuiState[$GUI_STATE_CTRL_CHECKBOX], $GUI_UNCHECKED)
    EndIf
    If StringInStr($appHotkey,'!') Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_ALT_CHECKBOX], $GUI_CHECKED)
    Else
        GUICtrlSetState($g_aGuiState[$GUI_STATE_ALT_CHECKBOX], $GUI_UNCHECKED)
    EndIf
    If StringInStr($appHotkey,'+') Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SHIFT_CHECKBOX], $GUI_CHECKED)
    Else
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SHIFT_CHECKBOX], $GUI_UNCHECKED)
    EndIf
    If StringInStr($appHotkey,'#') Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_WIN_CHECKBOX], $GUI_CHECKED)
    Else
        GUICtrlSetState($g_aGuiState[$GUI_STATE_WIN_CHECKBOX], $GUI_UNCHECKED)
    EndIf
    _GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_KEY_COMBO], $k)
    ;rest of settings
    If Not _HotkeyRegistry_IsStartupEnabled() Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_STARTUP_CHECKBOX], $GUI_UNCHECKED)
    Else
        GUICtrlSetState($g_aGuiState[$GUI_STATE_STARTUP_CHECKBOX], $GUI_CHECKED)
    EndIf
    Local $aArray = _HotkeyRepository_Load($iniFile)
    If IsArray($aArray) Then
        For $i = 1 To _HotkeyRepository_Count($aArray)
            Local $opts = ''
            Local $special = False
            $item = $aArray[$i][$HOTKEY_FIELD_TARGET]
            If $item = $ACTION_CATALOG_LEGACY_HIGH Then $item = "Set Process Priority to High"
            $type = _HotkeyModel_ActionLabel($aArray[$i][$HOTKEY_FIELD_ACTION])
            For $c = 0 To UBound($clsid, 1)-1
                If _strCompare($item, $clsid[$c][1]) Then
                    $item = $clsid[$c][0]
                    ExitLoop
                EndIf
            Next
            For $s = 0 To UBound($sPaths, 1)-1
                Local $aSpecialRecord = _HotkeyCodec_DecodeLegacy($aArray[$i][$HOTKEY_FIELD_HOTKEY], StringReplace($sPaths[$s][1], ' [Parameters] ', $HOTKEY_CODEC_PARAMETER), _HotkeyRepository_ClassifyPlainValue($sPaths[$s][1]))
                If IsArray($aSpecialRecord) And _strCompare($aArray[$i][$HOTKEY_FIELD_ACTION], $aSpecialRecord[$HOTKEY_FIELD_ACTION]) And _strCompare($aArray[$i][$HOTKEY_FIELD_TARGET], $aSpecialRecord[$HOTKEY_FIELD_TARGET]) And _strCompare($aArray[$i][$HOTKEY_FIELD_PARAMETERS], $aSpecialRecord[$HOTKEY_FIELD_PARAMETERS]) Then
                    $item = $sPaths[$s][0]
                    $special = True
                    ExitLoop
                EndIf
            Next
            If $special Then $type = 'System'
            If $aArray[$i][$HOTKEY_FIELD_ACTION] = $HOTKEY_ACTION_FILE And $aArray[$i][$HOTKEY_FIELD_PARAMETERS] <> '' Then $item &= ' [Parameters] ' & $aArray[$i][$HOTKEY_FIELD_PARAMETERS]
            If $aArray[$i][$HOTKEY_FIELD_ACTION] = $HOTKEY_ACTION_TEXT Then $item = StringReplace($item, @LF, '[New Line]')
            If BitAND($aArray[$i][$HOTKEY_FIELD_OPTIONS], $HOTKEY_OPTION_ADMIN) Then $opts &= 'Admin'
            If BitAND($aArray[$i][$HOTKEY_FIELD_OPTIONS], $HOTKEY_OPTION_SINGLETON) Then
                If $opts == 'Admin' Then $opts &= ', '
                $opts &= 'Singleton'
            EndIf
            GUICtrlCreateListViewItem($type&'|'&_HotkeyCodec_DecodeHotkey($aArray[$i][$HOTKEY_FIELD_HOTKEY])&'|'&$item&'|'&$opts, $g_aGuiState[$GUI_STATE_LIST_VIEW])
        Next
    EndIf
    ;~ GUICtrlSendMsg($g_aGuiState[$GUI_STATE_LIST_VIEW], $LVM_SETCOLUMNWIDTH, 1, -1)
    ;~ GUICtrlSendMsg($g_aGuiState[$GUI_STATE_LIST_VIEW], $LVM_SETCOLUMNWIDTH, 2, -1)
    ;resize columns
    _GUICtrlListView_SetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, $LVSCW_AUTOSIZE_USEHEADER)
    _GUICtrlListView_SetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 1, $LVSCW_AUTOSIZE_USEHEADER)
    If IsArray($aArray) Then
        _GUICtrlListView_SetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, _GUICtrlListView_GetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 0)+10)
        _GUICtrlListView_SetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 1, _GUICtrlListView_GetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 1)+10)
        _GUICtrlListView_SetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 3, _GUICtrlListView_GetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 3)+10)
    Else
        _GUICtrlListView_SetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 1, 160)
    EndIf
    _GUICtrlListView_SetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 2, ControlGetPos($g_aGuiState[$GUI_STATE_MAIN_WINDOW], '', $g_aGuiState[$GUI_STATE_LIST_VIEW])[2]-(_GUICtrlListView_GetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 0)+_GUICtrlListView_GetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 1)+_GUICtrlListView_GetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 3)+25))
    If _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) Then _GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], 0)
EndFunc

Func _guiToIni($iniFile) ;reads gui and saves to ini and sets global hotkey only
    Local $txt, $x, $c, $s, $type, $path, $parameters, $options, $aRecord
    ;main hotkey
    Local $oldHotkey = IniRead($iniFile, 'Options', 'Main', '') ;get old hotkey
    Local $appHotkey = ''
    If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_CTRL_CHECKBOX]), $GUI_CHECKED) == 1 Then $appHotkey &= '^'
    If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_ALT_CHECKBOX]), $GUI_CHECKED) == 1 Then $appHotkey &= '!'
    If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_SHIFT_CHECKBOX]), $GUI_CHECKED) == 1 Then $appHotkey &= '+'
    If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_WIN_CHECKBOX]), $GUI_CHECKED) == 1 Then $appHotkey &= '#'
    $appHotkey &= _HotkeyCodec_EncodeKey(GUICtrlRead($g_aGuiState[$GUI_STATE_KEY_COMBO]))
    Local $aNewHotkeys = _HotkeyRepository_CreateTable(_GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]))
    For $x = 0 To _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) - 1
        $type = _HotkeyModel_ActionFromLabel(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $x, 0))
        $path = _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $x, 2)
        $parameters = ''
        $options = $HOTKEY_OPTION_NONE
        If StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $x, 3), 'Admin') Then $options = BitOR($options, $HOTKEY_OPTION_ADMIN)
        If StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $x, 3), 'Singleton') Then $options = BitOR($options, $HOTKEY_OPTION_SINGLETON)
        For $c = 0 To UBound($clsid, 1)-1
            If _strCompare($path, $clsid[$c][0]) Then
                $path = $clsid[$c][1]
                $type = $HOTKEY_ACTION_FOLDER
                ExitLoop
            EndIf
        Next
        For $s = 0 To UBound($sPaths, 1)-1
            If _strCompare($path, $sPaths[$s][0]) Then
                $aRecord = _HotkeyCodec_DecodeLegacy(_HotkeyCodec_EncodeHotkey(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $x, 1)), StringReplace($sPaths[$s][1], ' [Parameters] ', $HOTKEY_CODEC_PARAMETER), _HotkeyRepository_ClassifyPlainValue($sPaths[$s][1]))
                $type = $aRecord[$HOTKEY_FIELD_ACTION]
                $path = $aRecord[$HOTKEY_FIELD_TARGET]
                $parameters = $aRecord[$HOTKEY_FIELD_PARAMETERS]
                ExitLoop
            EndIf
        Next
        If $type = $HOTKEY_ACTION_FILE And StringInStr($path, ' [Parameters] ') Then
            Local $aParameterParts = StringSplit($path, ' [Parameters] ', 1)
            If IsArray($aParameterParts) And $aParameterParts[0] = 2 Then
                $path = $aParameterParts[1]
                $parameters = $aParameterParts[2]
            EndIf
        EndIf
        If $type = $HOTKEY_ACTION_TEXT Then $path = StringReplace($path, '[New Line]', @LF)
        $aRecord = _HotkeyModel_Create(_HotkeyCodec_EncodeHotkey(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $x, 1)), $type, $path, $parameters, $options)
        If Not _ActionValidator_ValidateRecord($aRecord, True) Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $x + 1, False)
        If Not _HotkeyRepository_SetRecord($aNewHotkeys, $x + 1, $aRecord) Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $x + 1, False)
    Next
    If Not _HotkeyEditorModel_ValidateToggle($appHotkey, $aNewHotkeys) Then Return SetError($HOTKEY_REPOSITORY_ERROR_DUPLICATE, @error, False)
    If Not _HotkeyRegistry_ApplyBindings($oldHotkey, $aHotkeys, $appHotkey, $aNewHotkeys) Then Return SetError($HOTKEY_REPOSITORY_ERROR_HOTKEY_UNAVAILABLE, @extended, False)
    If Not _HotkeyRepository_Save($iniFile, $aNewHotkeys) Then
        Local $iSaveError = @error
        Local $iSaveExtended = @extended
        _HotkeyRegistry_ApplyBindings($appHotkey, $aNewHotkeys, $oldHotkey, $aHotkeys)
        Return SetError($iSaveError, $iSaveExtended, False)
    EndIf
    If Not IniWrite($iniFile, 'Options', 'Main', $appHotkey) Then
        _HotkeyRegistry_ApplyBindings($appHotkey, $aNewHotkeys, $oldHotkey, $aHotkeys)
        Return SetError($HOTKEY_REPOSITORY_ERROR_WRITE, 0, False)
    EndIf
    $aHotkeys = $aNewHotkeys
    $txt = _HotkeyCodec_DecodeHotkey($appHotkey) ;decode hotkey to text
    TrayItemSetText($enableTray, 'Enable '&$APP_TITLE&@TAB&$txt) ;change menu entry to new hotkey
    Return True
EndFunc

Func _saveBtn()
    If Not _MainWindow_IsHotkeyLayoutValid() Then
        _AppError_Report("The main hotkey is incomplete or conflicts with an action hotkey", $EDITOR_MODEL_ERROR_DUPLICATE, 0)
        Return False
    EndIf
    If Not _guiToIni($APP_INI_PATH) Then
        Local $iSaveError = @error
        Local $iSaveExtended = @extended
        If $iSaveError = $HOTKEY_REPOSITORY_ERROR_HOTKEY_UNAVAILABLE Then
            _AppError_Report("A hotkey is unavailable because Windows or another application already uses it", $iSaveError, $iSaveExtended)
        Else
            _AppError_Report("The hotkey settings could not be validated and saved; the previous file is still available as a backup", $iSaveError, $iSaveExtended)
        EndIf
        Return
    EndIf
    If _HotkeyEditorModel_StartupEnabled(GUICtrlRead($g_aGuiState[$GUI_STATE_STARTUP_CHECKBOX])) Then
        If Not _HotkeyRegistry_SetStartupEnabled(True) Then
            _AppError_Report("The Windows startup registry entry could not be written", @error, @extended)
            Return
        EndIf
    Else
        If Not _HotkeyRegistry_SetStartupEnabled(False) Then
            _AppError_Report("The Windows startup registry entry could not be removed", @error, @extended)
            Return
        EndIf
    EndIf
    If _HotkeyEditorModel_ShouldCloseSettings(True, True) Then
        GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
        $g_aGuiState[$GUI_STATE_WINDOW_VISIBLE] = False
    EndIf
    Return True
EndFunc

Func _guiDel()
    GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    $g_aGuiState[$GUI_STATE_WINDOW_VISIBLE] = False
EndFunc

Func _returnToggleHotkey()
    Local $appHotkey = ''
    If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_CTRL_CHECKBOX]), $GUI_CHECKED) == 1 Then $appHotkey &= 'Ctrl + '
    If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_ALT_CHECKBOX]), $GUI_CHECKED) == 1 Then $appHotkey &= 'Alt + '
    If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_SHIFT_CHECKBOX]), $GUI_CHECKED) == 1 Then $appHotkey &= 'Shift + '
    If BitAND(GUICtrlRead($g_aGuiState[$GUI_STATE_WIN_CHECKBOX]), $GUI_CHECKED) == 1 Then $appHotkey &= 'Win + '
    $appHotkey &= GUICtrlRead($g_aGuiState[$GUI_STATE_KEY_COMBO])
    Return($appHotkey)
EndFunc

Func _MainWindow_IsHotkeyLayoutValid()
    Local $sToggle = _HotkeyCodec_NormalizeHotkey(_HotkeyCodec_EncodeHotkey(_returnToggleHotkey()))
    If Not _HotkeyEditorModel_IsModifiedHotkey($sToggle) Then Return False
    Local $i, $j, $sHotkey
    For $i = 0 To _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) - 1
        $sHotkey = _HotkeyCodec_NormalizeHotkey(_HotkeyCodec_EncodeHotkey(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $i, 1)))
        If $sHotkey = $sToggle Then Return False
        For $j = 0 To $i - 1
            If $sHotkey = _HotkeyCodec_NormalizeHotkey(_HotkeyCodec_EncodeHotkey(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $j, 1))) Then Return False
        Next
    Next
    Return True
EndFunc

Func _MainWindow_UpdateSaveState()
    If Not $g_aGuiState[$GUI_STATE_SAVE_BUTTON] Then Return False
    If _MainWindow_IsHotkeyLayoutValid() Then
        GUICtrlSetState($g_aGuiState[$GUI_STATE_SAVE_BUTTON], $GUI_ENABLE)
        Return True
    EndIf
    GUICtrlSetState($g_aGuiState[$GUI_STATE_SAVE_BUTTON], $GUI_DISABLE)
    Return False
EndFunc

Func _strCompare($string1, $string2)
    If StringCompare($string1, $string2) == 0 Then
        Return True
    Else
        Return False
    EndIf
EndFunc

Func _sort()
    _GUICtrlListView_SortItems($g_aGuiState[$GUI_STATE_LIST_VIEW], GUICtrlGetState($g_aGuiState[$GUI_STATE_LIST_VIEW]))
EndFunc
