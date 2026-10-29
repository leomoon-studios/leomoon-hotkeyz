#NoTrayIcon
; Desktop benchmark: isolated profile and simulated registrations. No timing
; threshold; verify all records round-trip and print comparable measurements.
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
Global $sOriginalWorkingDir = @WorkingDir, $sFixture = @TempDir & "\hkz-settings-path-" & @AutoItPID, $bOwnFixture = False, $bOwnProfile = False
If FileExists($APP_INI_PATH) Or FileExists($APP_INI_PATH & ".bak") Or FileExists($APP_INI_PATH & ".tmp") Or FileExists($sFixture) Then Exit 2
OnAutoItExitRegister("_SettingsPathCleanup")
If Not DirCreate($sFixture & "\[folder]") Then Exit 3
$bOwnFixture = True
If Not FileChangeDir($sFixture) Then Exit 4
$bOwnProfile = True
IniWrite($APP_INI_PATH, "Options", "Main", "^!+{F11}")
IniWrite($APP_INI_PATH, "Hotkeys", "^!{F9}", "[folder]")
_mainGui()
If _GUICtrlListView_GetItemText($g_aGuiState[$GUI_STATE_LIST_VIEW], 0, 0) <> "Folder" Then
    ConsoleWrite("FAIL: bracketed existing folder was not classified" & @CRLF)
    Exit 1
EndIf
ConsoleWrite("PASSED: bracketed existing folder classified during Settings load" & @CRLF)
Func _SettingsPathCleanup()
    If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    FileChangeDir($sOriginalWorkingDir)
    If $bOwnProfile Then
        FileDelete($APP_INI_PATH)
        FileDelete($APP_INI_PATH & ".bak")
        FileDelete($APP_INI_PATH & ".tmp")
    EndIf
    If $bOwnFixture Then
        DirRemove($sFixture & "\[folder]")
        DirRemove($sFixture)
    EndIf
EndFunc