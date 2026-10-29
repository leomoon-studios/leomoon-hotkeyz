#include-once

#include <GUIConstantsEx.au3>
#include <GuiComboBox.au3>
#include <GuiListView.au3>
#include <ListViewConstants.au3>
#include <WindowsConstants.au3>
#include "..\actions\ActionValidator.au3"
#include "..\app\ErrorReporter.au3"
#include "HotkeyEditorModel.au3"

Global $g_iMainEditButton = 0, $g_iMainDeleteButton = 0, $g_iMainListHint = 0
Global $g_sMainWorkAreaHandler = "_MainWindow_WorkAreaSize"

Func _MainWindow_SizeForWorkArea($iWidth, $iHeight)
    ; Leave room for the taskbar and reduce the list rather than hiding buttons.
    Local $aSize[2] = [682, 590]
    If $iWidth > 0 And $iWidth < $aSize[0] Then $aSize[0] = $iWidth
    If $iHeight > 0 And $iHeight < $aSize[1] Then $aSize[1] = $iHeight
    Return $aSize
EndFunc

Func _MainWindow_WorkAreaSize()
    Local $tRect = DllStructCreate("long left;long top;long right;long bottom")
    Local $aResult = DllCall("user32.dll", "bool", "SystemParametersInfoW", "uint", 0x30, "uint", 0, "struct*", $tRect, "uint", 0)
    If @error Or Not IsArray($aResult) Or Not $aResult[0] Then Return _MainWindow_SizeForWorkArea(@DesktopWidth, @DesktopHeight)
    Local $iLeft = DllStructGetData($tRect, "left"), $iTop = DllStructGetData($tRect, "top")
    Local $iWorkWidth = DllStructGetData($tRect, "right") - $iLeft, $iWorkHeight = DllStructGetData($tRect, "bottom") - $iTop
    Local $aSize = _MainWindow_SizeForWorkArea($iWorkWidth, $iWorkHeight)
    ReDim $aSize[4]
    $aSize[2] = $iLeft + Int(($iWorkWidth - $aSize[0]) / 2)
    $aSize[3] = $iTop + Int(($iWorkHeight - $aSize[1]) / 2)
    Return $aSize
EndFunc

Func _mainGui()
    _Debug_Log("Settings window requested; visible=" & $g_aGuiState[$GUI_STATE_WINDOW_VISIBLE])
    ;~ $g_aGuiState[$GUI_STATE_MAIN_WINDOW] = GUICreate("Hotkey Settings", 386, 242, -1, -1) ;close and minimize
    ;~ $g_aGuiState[$GUI_STATE_MAIN_WINDOW] = GUICreate("Hotkey Settings", 386, 242, -1, -1, BitOR($WS_SYSMENU,$WS_POPUP)) ;frame only
    If $g_aGuiState[$GUI_STATE_WINDOW_VISIBLE] == False Then
        Local $aSize = Call($g_sMainWorkAreaHandler), $iWidth = $aSize[0], $iHeight = $aSize[1]
        ; Minimum practical width keeps the four shortcut modifiers usable.
        If $iWidth < 500 Then $iWidth = 500
        If $iHeight < 340 Then $iHeight = 340
        Local $iX = -1, $iY = -1
        If UBound($aSize) >= 4 Then
            $iX = $aSize[2]
            $iY = $aSize[3]
        EndIf
        Local $iListHeight = $iHeight - 262, $iToolbarX = $iWidth - 326, $iKeyX = $iWidth - 252
        Local $iModifierStep = Int(($iKeyX - 28) / 4)
        $g_aGuiState[$GUI_STATE_MAIN_WINDOW] = GUICreate($APP_TITLE&" Settings", $iWidth, $iHeight, $iX, $iY, $WS_SYSMENU)
        _Debug_Log("Settings GUI created; handle=" & $g_aGuiState[$GUI_STATE_MAIN_WINDOW] & ", error=" & @error)
        GUISetFont(9, 400, 0, "Segoe UI")
        $g_aGuiState[$GUI_STATE_STARTUP_CHECKBOX] = GUICtrlCreateCheckbox("Start with Windows", 16, 16, 250, 22)
        GUICtrlCreateGroup("Enable / disable HotKeyz shortcut", 16, 46, $iWidth - 38, 62)
        $g_aGuiState[$GUI_STATE_CTRL_CHECKBOX] = GUICtrlCreateCheckbox("Ctrl", 28, 73, $iModifierStep, 20)
        GUICtrlSetOnEvent(-1, "_MainWindow_UpdateSaveState")
        $g_aGuiState[$GUI_STATE_ALT_CHECKBOX] = GUICtrlCreateCheckbox("Alt", 28 + $iModifierStep, 73, $iModifierStep, 20)
        GUICtrlSetOnEvent(-1, "_MainWindow_UpdateSaveState")
        $g_aGuiState[$GUI_STATE_SHIFT_CHECKBOX] = GUICtrlCreateCheckbox("Shift", 28 + $iModifierStep * 2, 73, $iModifierStep, 20)
        GUICtrlSetOnEvent(-1, "_MainWindow_UpdateSaveState")
        $g_aGuiState[$GUI_STATE_WIN_CHECKBOX] = GUICtrlCreateCheckbox("Win", 28 + $iModifierStep * 3, 73, $iModifierStep, 20)
        GUICtrlSetOnEvent(-1, "_MainWindow_UpdateSaveState")
        $g_aGuiState[$GUI_STATE_KEY_COMBO] = GUICtrlCreateCombo("", $iKeyX, 70, 216, 25, BitOR($GUI_SS_DEFAULT_COMBO,$CBS_SIMPLE))
        GUICtrlSetData(-1, $HOTKEY_CODEC_KEY_NAMES)
        GUICtrlSetOnEvent(-1, "_MainWindow_UpdateSaveState")
        GUICtrlCreateGroup("", -99, -99, 1, 1)
        GUICtrlCreateLabel("Hotkeys", 16, 124, 100, 22)
        Local $addBtn = GUICtrlCreateButton("Add", $iToolbarX, 117, 94, 30)
        $g_iMainEditButton = GUICtrlCreateButton("Edit", $iToolbarX + 102, 117, 94, 30)
        $g_iMainDeleteButton = GUICtrlCreateButton("Delete", $iToolbarX + 204, 117, 100, 30)
        $g_aGuiState[$GUI_STATE_LIST_VIEW] = GUICtrlCreateListView("", 16, 154, $iWidth - 38, $iListHeight, BitOR($GUI_SS_DEFAULT_LISTVIEW,$WS_HSCROLL,$WS_VSCROLL), BitOR($WS_EX_CLIENTEDGE,$LVS_EX_FULLROWSELECT))
        $g_iMainListHint = GUICtrlCreateLabel("", 16, 162 + $iListHeight, $iWidth - 38, 22)
        $g_aGuiState[$GUI_STATE_CANCEL_BUTTON] = GUICtrlCreateButton("Cancel", $iWidth - 230, 187 + $iListHeight, 100, 30)
        $g_aGuiState[$GUI_STATE_SAVE_BUTTON] = GUICtrlCreateButton("Save", $iWidth - 122, 187 + $iListHeight, 100, 30)
        ;edit ui
        GUISetIcon(@ScriptFullPath, 201)
        GUICtrlSetOnEvent($g_aGuiState[$GUI_STATE_LIST_VIEW], '_sort')
        GUICtrlSetOnEvent($addBtn, "_addBtn")
        GUICtrlSetOnEvent($g_iMainEditButton, "_editBtn")
        GUICtrlSetOnEvent($g_iMainDeleteButton, "_delBtn")
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
        _MainWindow_UpdateListState()
        GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
        GUIRegisterMsg($WM_COMMAND, "_HotkeyEditor_WM_COMMAND")
        _GUICtrlListView_RegisterSortCallBack($g_aGuiState[$GUI_STATE_LIST_VIEW])
        GUISetState(@SW_SHOWNORMAL, $g_aGuiState[$GUI_STATE_MAIN_WINDOW])
        _Debug_Log("Settings GUI shown; error=" & @error)
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
        If $iCode = $LVN_ITEMCHANGED Then _MainWindow_UpdateListState()
        If $iCode = $NM_DBLCLK Then
            _editBtn()
            ;~ ConsoleWrite(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 1)&@LF)
            ;~ ConsoleWrite(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], Number(_GUICtrlListView_GetSelectedIndices($g_aGuiState[$GUI_STATE_LIST_VIEW])), 2)&@LF)
        EndIf
    EndSwitch
    Return $GUI_RUNDEFMSG
EndFunc

Func _MainWindow_UpdateListState()
    If Not $g_iMainEditButton Or Not $g_iMainDeleteButton Then Return
    Local $iCount = _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW])
    Local $iState = $GUI_DISABLE
    If _GUICtrlListView_GetSelectedCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) > 0 Then $iState = $GUI_ENABLE
    GUICtrlSetState($g_iMainEditButton, $iState)
    GUICtrlSetState($g_iMainDeleteButton, $iState)
    If $iCount Then
        GUICtrlSetData($g_iMainListHint, "Double-click a hotkey to edit it.")
    Else
        GUICtrlSetData($g_iMainListHint, "No hotkeys yet. Select Add to create one.")
    EndIf
EndFunc

Func _iniToGui($iniFile) ;just reads ini and sets the gui
    Local $i, $c, $s, $type, $item
    ReDim $g_aRestrictionRows[1][8]
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
        _aTags()
        ; The catalog is constant during this load. Decoding it inside the row
        ; loop repeats the same file classification and parsing for every hotkey.
        Local $aSpecialCatalog[UBound($sPaths, 1)][3], $aSpecialRecord
        For $s = 0 To UBound($sPaths, 1) - 1
            $aSpecialRecord = _HotkeyCodec_DecodeLegacy("^!a", StringReplace($sPaths[$s][1], ' [Parameters] ', $HOTKEY_CODEC_PARAMETER), _HotkeyRepository_ClassifyPlainValue($sPaths[$s][1]))
            If Not IsArray($aSpecialRecord) Then ContinueLoop
            $aSpecialCatalog[$s][0] = $aSpecialRecord[$HOTKEY_FIELD_ACTION]
            $aSpecialCatalog[$s][1] = $aSpecialRecord[$HOTKEY_FIELD_TARGET]
            $aSpecialCatalog[$s][2] = $aSpecialRecord[$HOTKEY_FIELD_PARAMETERS]
        Next
        For $i = 1 To _HotkeyRepository_Count($aArray)
            Local $opts = ''
            Local $special = False
            $item = $aArray[$i][$HOTKEY_FIELD_TARGET]
            If $item = $ACTION_CATALOG_LEGACY_HIGH Then $item = "Set Process Priority to High"
            $type = _HotkeyModel_ActionLabel($aArray[$i][$HOTKEY_FIELD_ACTION])
            If $aArray[$i][$HOTKEY_FIELD_ACTION] = $HOTKEY_ACTION_FILE And $aArray[$i][$HOTKEY_FIELD_PARAMETERS] = '' Then
                Local $sExpandedItem = _HotkeyCodec_ExpandTags($item, $aTags)
                ; Load already classified ordinary unexpanded paths. Bracketed
                ; values bypass that check; tags may also change the path.
                If $sExpandedItem <> $item Or StringLeft($item, 1) = '[' Then
                    If StringInStr(FileGetAttrib($sExpandedItem), 'D') Then $type = 'Folder'
                EndIf
            EndIf
            For $c = 0 To UBound($clsid, 1)-1
                If _strCompare($item, $clsid[$c][1]) Then
                    $item = $clsid[$c][0]
                    ExitLoop
                EndIf
            Next
            For $s = 0 To UBound($sPaths, 1)-1
                If $aSpecialCatalog[$s][0] <> '' And _strCompare($aArray[$i][$HOTKEY_FIELD_ACTION], $aSpecialCatalog[$s][0]) And _strCompare($aArray[$i][$HOTKEY_FIELD_TARGET], $aSpecialCatalog[$s][1]) And _strCompare($aArray[$i][$HOTKEY_FIELD_PARAMETERS], $aSpecialCatalog[$s][2]) Then
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
            Local $aListRecord = _HotkeyRepository_GetRecord($aArray, $i)
            ; The repository has already rejected duplicates and the list was reset.
            _HotkeyEditor_SetRestrictions($aListRecord[$HOTKEY_FIELD_HOTKEY], $aListRecord, True)
            Local $sRestrictionSummary = _HotkeyEditor_RestrictionSummary($aListRecord)
            If $sRestrictionSummary <> '' Then
                If $opts <> '' Then $opts &= ', '
                $opts &= $sRestrictionSummary
            EndIf
            GUICtrlCreateListViewItem($type&'|'&_HotkeyCodec_DecodeHotkey($aArray[$i][$HOTKEY_FIELD_HOTKEY])&'|'&$item&'|'&$opts, $g_aGuiState[$GUI_STATE_LIST_VIEW])
        Next
    EndIf
    ; Keep each column usable even with empty lists or unusually long values.
    ; Native column dragging and horizontal scrolling expose longer content.
    _GUICtrlListView_SetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 75)
    _GUICtrlListView_SetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 1, 140)
    _GUICtrlListView_SetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 2, 255)
    _GUICtrlListView_SetColumnWidth($g_aGuiState[$GUI_STATE_LIST_VIEW], 3, 155)
    If _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) Then _GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], 0)
EndFunc

Global $g_bSavedInactiveRestrictions = False

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
        _HotkeyEditor_ApplyRestrictions($aRecord[$HOTKEY_FIELD_HOTKEY], $aRecord)
        ; Paths may be unavailable until the hotkey runs (for example, a removable drive).
        If Not _ActionValidator_ValidateRecord($aRecord, False) Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $x + 1, False)
        If Not _HotkeyRepository_SetRecord($aNewHotkeys, $x + 1, $aRecord) Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $x + 1, False)
    Next
    If Not _HotkeyEditorModel_ValidateToggle($appHotkey, $aNewHotkeys) Then Return SetError($HOTKEY_REPOSITORY_ERROR_DUPLICATE, @error, False)
    If Not _HotkeyRegistry_ApplyBindings($oldHotkey, $aHotkeys, $appHotkey, $aNewHotkeys, True) Then Return SetError($HOTKEY_REPOSITORY_ERROR_HOTKEY_UNAVAILABLE, @extended, False)
    Local $aAppliedHotkeys = $g_aLastAppliedHotkeys
    Local $bToggleAvailable = $g_bLastToggleAvailable
    If Not _HotkeyRepository_Save($iniFile, $aNewHotkeys) Then
        Local $iSaveError = @error
        Local $iSaveExtended = @extended
        _HotkeyRegistry_ApplyBindings($appHotkey, $aAppliedHotkeys, $oldHotkey, $aHotkeys)
        Return SetError($iSaveError, $iSaveExtended, False)
    EndIf
    If Not IniWrite($iniFile, 'Options', 'Main', $appHotkey) Then
        _HotkeyRegistry_ApplyBindings($appHotkey, $aAppliedHotkeys, $oldHotkey, $aHotkeys)
        Return SetError($HOTKEY_REPOSITORY_ERROR_WRITE, 0, False)
    EndIf
    $g_bSavedInactiveRestrictions = False
    $aHotkeys = $aAppliedHotkeys
    $txt = _HotkeyCodec_DecodeHotkey($appHotkey) ;decode hotkey to text
    TrayItemSetText($enableTray, 'Enable '&$APP_TITLE&@TAB&$txt) ;change menu entry to new hotkey
    If Not $bToggleAvailable Then TrayItemSetText($enableTray, 'Enable ' & $APP_TITLE & @TAB & 'Shortcut unavailable')
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
    Local $i, $j, $iCount = _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW])
    Local $aKeys[$iCount + 1]
    For $i = 0 To $iCount - 1
        $aKeys[$i] = _HotkeyCodec_NormalizeHotkey(_HotkeyCodec_EncodeHotkey(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $i, 1)))
        If $aKeys[$i] = $sToggle Then Return False
        For $j = 0 To $i - 1
            If $aKeys[$i] = $aKeys[$j] Then Return False
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
