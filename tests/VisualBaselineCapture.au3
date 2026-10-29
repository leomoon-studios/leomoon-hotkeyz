#NoTrayIcon
; Captures test windows only. Refuses to overwrite an existing test INI.
#include <ScreenCapture.au3>
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
Global $g_sCaptureDir = @ScriptDir & "\..\build\visual-ui-baseline", $g_bOwnProfile = False
If FileExists($APP_INI_PATH) Or FileExists($APP_INI_PATH & ".bak") Or FileExists($APP_INI_PATH & ".tmp") Then Exit 2
If Not DirCreate($g_sCaptureDir) Then Exit 3
OnAutoItExitRegister("_BaselineCleanup")
$g_bOwnProfile = True
IniWrite($APP_INI_PATH, "Options", "Main", "^!+{F11}")
Global $hTime = TimerInit()
_mainGui()
ConsoleWrite("Settings empty open ms=" & Round(TimerDiff($hTime)) & @CRLF)
_BaselineCapture("settings-empty", $g_aGuiState[$GUI_STATE_MAIN_WINDOW])
Global $aRows[6] = ["File|Ctrl + Alt + F1|C:\Example\A long folder name\A long application name.exe|Admin, Ctrl: Left, Caps: On", "Folder|Ctrl + Alt + F2|C:\Example\Documents|", "System|Ctrl + Alt + F3|" & $sPaths[0][0] & "|", "Window|Ctrl + Alt + F4|Close|", "URL|Ctrl + Alt + F5|https://example.com|", "Text|Ctrl + Alt + F6|Example text|"]
Global $i
For $i = 0 To 5
    GUICtrlCreateListViewItem($aRows[$i], $g_aGuiState[$GUI_STATE_LIST_VIEW])
Next
_GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], 0)
_BaselineCapture("settings-populated", $g_aGuiState[$GUI_STATE_MAIN_WINDOW])
Global $aNames[6] = ["file", "folder", "system", "window", "url", "text"]
Global $aRadios[6] = [$GUI_STATE_FILE_RADIO, $GUI_STATE_FOLDER_RADIO, $GUI_STATE_SPECIAL_RADIO, $GUI_STATE_WINDOW_RADIO, $GUI_STATE_URL_RADIO, $GUI_STATE_TEXT_RADIO]
Global $aHandlers[6] = ["_fileRdo", "_folderRdo", "_specialRdo", "_windowRdo", "_urlRdo", "_txtRdo"]
For $i = 0 To 5
    $hTime = TimerInit()
    _addBtn()
    If $i = 0 Then ConsoleWrite("Add open ms=" & Round(TimerDiff($hTime)) & @CRLF)
    If $i <> 0 Then GUICtrlSetState($g_aGuiState[$GUI_STATE_FILE_RADIO], $GUI_UNCHECKED)
    GUICtrlSetState($g_aGuiState[$aRadios[$i]], $GUI_CHECKED)
    Call($aHandlers[$i])
    _BaselineCapture("add-" & $aNames[$i], $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    If $i = 0 Then
        _HotkeyEditor_ShowRestrictions()
        _BaselineCapture("conditions", $g_hRestrictionDialog)
        _HotkeyEditor_RestrictionsCancel()
    EndIf
    _hideChild()
    _GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], -1, False)
    _GUICtrlListView_SetItemSelected($g_aGuiState[$GUI_STATE_LIST_VIEW], $i)
    $hTime = TimerInit()
    _editBtn()
    If $i = 0 Then ConsoleWrite("Edit open ms=" & Round(TimerDiff($hTime)) & @CRLF)
    _BaselineCapture("edit-" & $aNames[$i], $g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    _hideChild()
Next
_AppWarning_ReportNonBlocking("These hotkeys could not be registered. Windows or another application may own them:" & @CRLF & "- Ctrl + Alt + F1" & @CRLF & "- Ctrl + Alt + F2")
_BaselineCapture("warning", $g_hWarningWindow)
_AppWarning_Close()
ConsoleWrite("Desktop=" & @DesktopWidth & "x" & @DesktopHeight & @CRLF)
Func _BaselineCapture($sName, $hWindow)
    If Not IsHWnd($hWindow) Then Exit 4
    WinActivate($hWindow)
    Sleep(200)
    Local $aPos = WinGetPos($hWindow), $aClient = WinGetClientSize($hWindow)
    ConsoleWrite($sName & ": outer=" & $aPos[2] & "x" & $aPos[3] & ", client=" & $aClient[0] & "x" & $aClient[1] & @CRLF)
    If Not _ScreenCapture_CaptureWnd($g_sCaptureDir & "\" & $sName & ".png", $hWindow) Then Exit 5
EndFunc
Func _BaselineCleanup()
    If $g_bOwnProfile Then FileDelete($APP_INI_PATH)
    If IsHWnd($g_hRestrictionDialog) Then GUIDelete($g_hRestrictionDialog)
    If IsHWnd($g_aGuiState[$GUI_STATE_EDITOR_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_EDITOR_WINDOW])
    If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    _AppWarning_Close()
EndFunc
