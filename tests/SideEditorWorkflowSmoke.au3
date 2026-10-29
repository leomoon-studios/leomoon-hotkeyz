#NoTrayIcon
; Interactive test: creates a temporary INI in Temp and registers
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
Global $g_iRuns = 0, $g_sLastFile = "", $g_iSender = 0, $g_bOwner = False
If $CmdLine[0] And $CmdLine[1] = "send" Then
    Sleep(250)
    Global $iControl = 0xA2
    If $CmdLine[2] = "right" Then $iControl = 0xA3
    _WorkflowKey($iControl, False)
    _WorkflowKey(0xA0, False)
    Global $iBase = 0x78
    If $CmdLine[3] = "F10" Then $iBase = 0x79
    _WorkflowKey($iBase, False)
    _WorkflowKey($iBase, True)
    _WorkflowKey(0xA0, True)
    _WorkflowKey($iControl, True)
    Exit 0
EndIf
If Not $CmdLine[0] Then
    If FileExists($APP_INI_PATH) Or FileExists($APP_INI_PATH & ".bak") Or FileExists($APP_INI_PATH & ".tmp") Then Exit 2
    $g_bOwner = True
EndIf
OnAutoItExitRegister("_WorkflowCleanup")
_ProcessActions_ConfigureShellBackend("_WorkflowSpy")
If $CmdLine[0] And $CmdLine[1] = "restart" Then
    If Not _iniToApply($APP_INI_PATH) Then _WorkflowFail("restart load")
    If _HotkeyRepository_Count($aHotkeys) <> 1 Or $g_iSideCount <> 1 Then _WorkflowFail("restart binding count")
    If $aHotkeys[1][$HOTKEY_FIELD_ACTION] <> $HOTKEY_ACTION_FILE Or $aHotkeys[1][$HOTKEY_FIELD_CTRL_SIDE] <> $HOTKEY_SIDE_LEFT Then _WorkflowFail("restart lost action or side")
    _WorkflowPress("right", "F9")
    If $g_iRuns <> 0 Then _WorkflowFail("restart wrong side ran")
    _WorkflowPress("left", "F9")
    If $g_iRuns <> 1 Or $g_sLastFile <> @AutoItExe Then _WorkflowFail("restart matching side did not launch changed action")
    _WorkflowCheckDeleted()
    If $g_iRuns <> 1 Then _WorkflowFail("deleted hotkey ran after restart")
    ConsoleWrite("PASSED: fresh process loaded and enforced edited side shortcut; x64=" & @AutoItX64 & @CRLF)
    Exit 0
EndIf
IniWrite($APP_INI_PATH, "Options", "Main", "^!+{F11}")
Global $aTable = _HotkeyRepository_CreateTable(2), $aFirst = _HotkeyModel_Create("^+{F9}", $HOTKEY_ACTION_COMMAND, "echo initial"), $aSecond = _HotkeyModel_Create("^+{F10}", $HOTKEY_ACTION_COMMAND, "echo second")
$aFirst[$HOTKEY_FIELD_CTRL_SIDE] = $HOTKEY_SIDE_LEFT
$aSecond[$HOTKEY_FIELD_CTRL_SIDE] = $HOTKEY_SIDE_RIGHT
_HotkeyRepository_SetRecord($aTable, 1, $aFirst)
_HotkeyRepository_SetRecord($aTable, 2, $aSecond)
If Not _HotkeyRepository_Save($APP_INI_PATH, $aTable) Or Not _iniToApply($APP_INI_PATH) Then _WorkflowFail("initial profile/binding")
If $g_iSideCount <> 2 Then _WorkflowFail("initial side registration")
_WorkflowPress("left", "F9")
_WorkflowPress("right", "F9")
_WorkflowPress("right", "F10")
If $g_iRuns <> 2 Then _WorkflowFail("initial matching and mismatching presses")
_mainGui()
_GUICtrlListView_SortItems($g_aGuiState[$GUI_STATE_LIST_VIEW], 1)
If StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 1), "F9") Then _GUICtrlListView_SortItems($g_aGuiState[$GUI_STATE_LIST_VIEW], 1)
If Not StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 1), "F10") Then _WorkflowFail("sort did not reorder rows")
Global $iRow = _WorkflowFind("F9")
_GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], -1, False)
_GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], $iRow)
_editBtn()
If $g_aEditorRestrictions[0] <> $HOTKEY_SIDE_LEFT Then _WorkflowFail("sort assigned wrong restriction to F9")
GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_RADIO], $GUI_CHECKED)
GUICtrlSetState($g_aGuiState[$GUI_STATE_COMMAND_CHECKBOX], $GUI_UNCHECKED)
_fileRdo()
GUICtrlSetData($g_aGuiState[$GUI_STATE_FILE_INPUT], @AutoItExe)
If Not _edit() Then _WorkflowFail("change action type")
If Not _guiToIni($APP_INI_PATH) Then _WorkflowFail("save edited sorted profile")
_WorkflowPress("left", "F9")
If $g_iRuns <> 3 Or $g_sLastFile <> @AutoItExe Then _WorkflowFail("changed action not active")
_WorkflowPress("right", "F9")
If $g_iRuns <> 3 Then _WorkflowFail("wrong side after edit")
$iRow = _WorkflowFind("F10")
If $iRow < 0 Then _WorkflowFail("second row lost after sort")
_GUICtrlListView_DeleteItem($g_aGuiState[$GUI_STATE_LIST_VIEW], $iRow)
_HotkeyEditor_RemoveRestrictions("^+{F10}")
If Not _guiToIni($APP_INI_PATH) Then _WorkflowFail("save deletion")
_WorkflowCheckDeleted()
If $g_iRuns <> 3 Or $g_iSideCount <> 1 Then _WorkflowFail("deleted shortcut remains active")
_HotkeyRegistry_ClearTable($aHotkeys)
_HotkeyRegistry_TrySet("^!+{F11}")
_SideHotkeys_Shutdown()
Global $iRestart = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" restart', "", @SW_HIDE, 2)
If Not $iRestart Then _WorkflowFail("could not launch fresh process")
If Not ProcessWaitClose($iRestart, 30) Then
    ProcessClose($iRestart)
    _WorkflowFail("fresh process restart timed out")
EndIf
Global $iExit = @extended, $sChildOutput = StdoutRead($iRestart)
ConsoleWrite($sChildOutput)
If $iExit <> 0 Then _WorkflowFail("fresh process restart failed: " & $iExit)
ConsoleWrite("PASSED: active side action edit, reorder, deletion and fresh restart; x64=" & @AutoItX64 & @CRLF)
Func _WorkflowFind($sKey)
    Local $i
    For $i = 0 To _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) - 1
        If StringInStr(_GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], $i, 1), $sKey) Then Return $i
    Next
    Return -1
EndFunc
Func _WorkflowPress($sSide, $sKey)
    $g_iSender = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" send ' & $sSide & ' ' & $sKey, "", @SW_HIDE)
    Local $hWait = TimerInit(), $i
    While ProcessExists($g_iSender) And TimerDiff($hWait) < 5000
        _SideHotkeys_Poll()
        Sleep(5)
    WEnd
    If ProcessExists($g_iSender) Then _WorkflowFail("sender timed out")
    For $i = 1 To 80
        _SideHotkeys_Poll()
        Sleep(2)
    Next
EndFunc
Func _WorkflowCheckDeleted()
    ; Claim the now-free shortcut as a sink so the synthetic press cannot
    ; trigger an unrelated application after deletion.
    If Not _HotkeyRegistry_TrySet("^+{F10}", "_WorkflowSink") Then _WorkflowFail("deleted shortcut was not released")
    _WorkflowPress("right", "F10")
    _HotkeyRegistry_TrySet("^+{F10}")
EndFunc
Func _WorkflowSink()
EndFunc
Func _WorkflowSpy($sFile, $sArgs, $sDir, $sVerb, $iShow)
    #forceref $sArgs, $sDir, $sVerb, $iShow
    $g_iRuns += 1
    $g_sLastFile = $sFile
    Return 123
EndFunc
Func _WorkflowKey($iVk, $bUp)
    Local $aScan = DllCall("user32.dll", "uint", "MapVirtualKeyW", "uint", $iVk, "uint", 0), $iFlags = 0
    If $iVk = 0xA3 Then $iFlags = 1
    If $bUp Then $iFlags = BitOR($iFlags, 2)
    DllCall("user32.dll", "none", "keybd_event", "byte", $iVk, "byte", $aScan[0], "dword", $iFlags, "ulong_ptr", 0)
EndFunc
Func _WorkflowFail($sMessage)
    ConsoleWrite("FAIL: " & $sMessage & "; runs=" & $g_iRuns & @CRLF)
    Exit 1
EndFunc
Func _WorkflowCleanup()
    If $g_iSender And ProcessExists($g_iSender) Then ProcessClose($g_iSender)
    _HotkeyRegistry_ClearTable($aHotkeys)
    _HotkeyRegistry_TrySet("^!+{F11}")
    _SideHotkeys_Shutdown()
    If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    If $g_bOwner Then
        FileDelete($APP_INI_PATH)
        FileDelete($APP_INI_PATH & ".bak")
        FileDelete($APP_INI_PATH & ".tmp")
    EndIf
EndFunc
