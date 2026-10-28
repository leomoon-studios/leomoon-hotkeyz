#NoTrayIcon
; Interactive test: creates a temporary INI beside this script and registers
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
Global $g_bOwnProfile = False
If FileExists($APP_INI_PATH) Or FileExists($APP_INI_PATH & ".bak") Or FileExists($APP_INI_PATH & ".tmp") Then Exit 2
OnAutoItExitRegister("_TestCleanup")
$g_bOwnProfile = True
Global $sMissing = @TempDir & "\hotkeyz-missing-profile-" & @AutoItPID & "\app.exe"
IniWrite($APP_INI_PATH, "Options", "Main", "^!+{F11}")
IniWrite($APP_INI_PATH, "Hotkeys", "^!{F9}", $sMissing)
IniWrite($APP_INI_PATH, "Hotkeys", "^!{F10}", "[HkzExe]Cycle Playback Device")
_HotkeyRegistry_ConfigureHotkeyBackend("_TestBinding")
_mainGui()
If _GUICtrlListView_GetItemCount($g_aGuiState[$GUI_STATE_LIST_VIEW]) <> 2 Then _TestFail("profile did not load both actions")
If Not StringInStr(_HotkeyEditor_FindConflict("^!{F9}", -1), $sMissing) Then _TestFail("duplicate does not identify its action")
If Not StringInStr(_HotkeyEditor_FindConflict("^!+{F11}", -1), "enable/disable") Then _TestFail("toggle conflict was not identified")
If _HotkeyEditor_IsAvailable("^!{F10}") Then _TestFail("external conflict was accepted")
If Not _HotkeyEditor_IsAvailable("^!{F8}") Then _TestFail("available shortcut was rejected")
_GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], 0)
_editBtn()
Global $aEdited = _HotkeyEditor_ReadRecord()
If IsArray($aEdited) Then _TestFail("editor accepted an unavailable file")
_hideChild()
If Not _guiToIni($APP_INI_PATH) Then _TestFail("save failed: error=" & @error & ", detail=" & @extended)
If _HotkeyRepository_Count($aHotkeys) <> 1 Then _TestFail("unavailable hotkey was included in active bindings")
Global $aSaved = _HotkeyRepository_Load($APP_INI_PATH)
If Not IsArray($aSaved) Or _HotkeyRepository_Count($aSaved) <> 2 Then _TestFail("saved profile did not reload")
If $aSaved[1][$HOTKEY_FIELD_TARGET] <> $sMissing Then _TestFail("save changed unavailable target")
If $aSaved[2][$HOTKEY_FIELD_TARGET] <> "Cycle Playback Device" Then _TestFail("save changed other action")
_iniToApply($APP_INI_PATH)
If $g_hWarningWindow = 0 Or _HotkeyRepository_Count($aHotkeys) <> 1 Then _TestFail("startup warning or available binding missing")
_AppWarning_ReportNonBlocking("Another warning")
If Not StringInStr(GUICtrlRead($g_iWarningText), "Another warning") Then _TestFail("startup warnings were not combined")
_AppWarning_Close()
ConsoleWrite("PASSED: imported save and nonblocking startup warnings" & @CRLF)
Exit 0
Func _TestBinding($sHotkey, $sHandler)
    If $sHotkey = "^!{F10}" And $sHandler <> "" Then Return False
    Return True
EndFunc
Func _TestFail($sMessage)
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
    Exit 1
EndFunc
Func _TestCleanup()
    If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    If $g_bOwnProfile Then
        FileDelete($APP_INI_PATH)
        FileDelete($APP_INI_PATH & ".bak")
        FileDelete($APP_INI_PATH & ".tmp")
    EndIf
EndFunc

