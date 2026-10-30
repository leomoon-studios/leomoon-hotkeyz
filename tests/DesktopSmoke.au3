#NoTrayIcon
; Interactive Windows desktop required. Uses only disposable windows and shortcuts.
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
    If Not _Application_EnableGdiScaling() Then Exit 2
EndIf
Global $g_iDesktopFailures = 0
Global $g_iDesktopCallbacks = 0
Global $g_bDesktopDispatch = False
Global $g_hDesktopWindow = GUICreate("HotKeyz disposable regression test", 320, 120)
OnAutoItExitRegister("_DesktopCleanup")
ConsoleWrite("Desktop test administrator token: " & IsAdmin() & @CRLF)

; Read incomplete and complete selections through the actual editor controls.
$g_aGuiState[$GUI_STATE_MAIN_WINDOW] = $g_hDesktopWindow
_editGui("HotKeyz test editor")
GUICtrlSetState($g_aGuiState[$GUI_STATE_SPECIAL_RADIO], $GUI_CHECKED)
_GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_SPECIAL_COMBO], "Empty Clipboard")
_GUICtrlComboBox_SetEditText($g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO], "")
Global $aRecord = _HotkeyEditor_ReadRecord()
Global $iReadError = @error
_DesktopAssert(Not IsArray($aRecord) And $iReadError <> 0, "incomplete system action is rejected without crashing")
GUICtrlSetState($g_aGuiState[$GUI_STATE_EDITOR_CTRL_CHECKBOX], $GUI_CHECKED)
_GUICtrlComboBox_SelectString($g_aGuiState[$GUI_STATE_EDITOR_KEY_COMBO], "A")
$aRecord = _HotkeyEditor_ReadRecord()
_DesktopAssert(IsArray($aRecord), "complete system action produces a record")
GUICtrlSetState($g_aGuiState[$GUI_STATE_SPECIAL_RADIO], $GUI_UNCHECKED)
GUICtrlSetState($g_aGuiState[$GUI_STATE_TEXT_RADIO], $GUI_CHECKED)
GUICtrlSetData($g_aGuiState[$GUI_STATE_TEXT_EDIT], "")
$aRecord = _HotkeyEditor_ReadRecord()
$iReadError = @error
_DesktopAssert(Not IsArray($aRecord) And $iReadError <> 0, "invalid ordinary action preserves its validation error")
GUIDelete($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
$g_aGuiState[$GUI_STATE_EDITOR_WINDOW] = 0

; Register and fire real shortcuts, including a subtract spelling from a broken INI.
$aHotkeys = _HotkeyRepository_CreateTable(3)
$aRecord = _HotkeyCodec_DecodeLegacy("^!+{NUMPADADD}", "[HkzWM]Transparency +")
_HotkeyRepository_SetRecord($aHotkeys, 1, $aRecord)
$aRecord = _HotkeyCodec_DecodeLegacy("^!+{NUMPADSUBTRACT}", "[HkzWM]Transparency -")
_HotkeyRepository_SetRecord($aHotkeys, 2, $aRecord)
$aRecord = _HotkeyCodec_DecodeLegacy("^!+{F24}", "[HkzWM]Minimize")
_HotkeyRepository_SetRecord($aHotkeys, 3, $aRecord)
If Not _HotkeyRegistry_SetTable($aHotkeys, "_DesktopHotkeyPressed") Then
    ConsoleWrite("FAIL: a test shortcut is unavailable" & @CRLF)
    Exit 1
EndIf
GUISetState(@SW_SHOW, $g_hDesktopWindow)
WinActivate($g_hDesktopWindow)
If Not WinWaitActive($g_hDesktopWindow, "", 3) Then
    ConsoleWrite("FAIL: test window could not become active" & @CRLF)
    Exit 1
EndIf
_DesktopAssert(Not BitAND(_WinAPI_GetWindowLong($g_hDesktopWindow, $GWL_EXSTYLE), $WS_EX_LAYERED), "test starts with an ordinary opaque window")
_DesktopInvoke("^!+{NUMPADADD}")
_DesktopAssert(_DesktopAlpha() = 238, "plus shortcut changes opacity from 255 to 238")
_DesktopInvoke("^!+{NUMPADADD}")
_DesktopAssert(_DesktopAlpha() = 221, "second plus shortcut changes opacity to 221")
_DesktopInvoke("^!+{NUMPADSUB}")
_DesktopAssert(_DesktopAlpha() = 238, "recovered minus shortcut changes opacity to 238")
_DesktopInvoke("^!+{NUMPADSUB}")
_DesktopAssert(_DesktopAlpha() = 255, "minus shortcut restores full opacity")
_DesktopInvoke("^!+{NUMPADSUB}")
_DesktopAssert(_DesktopAlpha() = 255, "minus shortcut stays at maximum opacity")
; Legacy Resize 3x2 must resize in place rather than move to a grid cell.
Global $aBeforeResize = WinGetPos($g_hDesktopWindow)
Global $aClientBeforeResize = WinGetClientSize($g_hDesktopWindow)
Global $aWorkArea = _getMonitorArea(_WinAPI_MonitorFromWindow($g_hDesktopWindow, $MONITOR_DEFAULTTONEAREST))
Global $iExpectedWidth = Floor(_Geometry_WorkWidth($aWorkArea) / 3)
Global $iExpectedHeight = Floor(_Geometry_WorkHeight($aWorkArea) / 2)
If @OSVersion = "WIN_10" And $aBeforeResize[2] - $aClientBeforeResize[0] > 15 Then
    $iExpectedWidth += 14
    $iExpectedHeight += 7
EndIf
Global $aDesktopTags[1][2] = [["<TEST>", "test"]]
$aRecord = _HotkeyCodec_DecodeLegacy("^!;", "[HkzWM]Resize 3x2")
_DesktopAssert(_ActionDispatcher_Dispatch($aRecord, $aDesktopTags), "legacy resize dispatch succeeds")
Global $aAfterResize = WinGetPos($g_hDesktopWindow)
_DesktopAssert($aAfterResize[0] = $aBeforeResize[0] And $aAfterResize[1] = $aBeforeResize[1], "legacy resize preserves window position")
_DesktopAssert($aAfterResize[2] = $iExpectedWidth And $aAfterResize[3] = $iExpectedHeight, "legacy resize matches v1.8.12 dimensions and frame allowance")
_DesktopInvoke("^!+{F24}")
_DesktopAssert(BitAND(WinGetState($g_hDesktopWindow), 16) <> 0, "minimize shortcut actually minimizes the window")

If $g_iDesktopFailures Then Exit 1
ConsoleWrite("PASSED: desktop editor, native hotkey callbacks, minimize, and transparency in both directions" & @CRLF)
Exit 0

Func _DesktopAssert($bCondition, $sMessage)
    If $bCondition Then Return
    $g_iDesktopFailures += 1
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
EndFunc

Func _DesktopInvoke($sHotkey)
    If Not WinActive($g_hDesktopWindow) Then
        _DesktopAssert(False, "test window lost focus; shortcut was not sent")
        Return
    EndIf
    Local $iBefore = $g_iDesktopCallbacks
    $g_bDesktopDispatch = False
    Send($sHotkey)
    Local $hTimer = TimerInit()
    While $g_iDesktopCallbacks = $iBefore And TimerDiff($hTimer) < 2000
        Sleep(10)
    WEnd
    _DesktopAssert($g_iDesktopCallbacks > $iBefore And $g_bDesktopDispatch, "native callback dispatch for " & $sHotkey)
EndFunc

Func _DesktopHotkeyPressed()
    $g_iDesktopCallbacks += 1
    Local $iRow = _HotkeyRegistry_FindHotkey(@HotKeyPressed)
    If @error Then Return
    Local $aRecord = _HotkeyRepository_GetRecord($aHotkeys, $iRow)
    Local $aTestTags[1][2] = [["<TEST>", "test"]]
    $g_bDesktopDispatch = _ActionDispatcher_Dispatch($aRecord, $aTestTags)
EndFunc

Func _DesktopAlpha()
    Local $iAlpha
    _WinGetTrans($g_hDesktopWindow, $iAlpha)
    Return $iAlpha
EndFunc

Func _DesktopCleanup()
    _HotkeyRegistry_ClearTable($aHotkeys)
    If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    GUIDelete($g_hDesktopWindow)
EndFunc
