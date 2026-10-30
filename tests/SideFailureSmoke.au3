#NoTrayIcon
; Interactive test: creates a temporary INI beside this test and registers
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
Global $g_iFailures = 0, $g_iChecks = 0, $g_iChild = 0, $g_bOwnProfile = False, $g_sToggleError = ""
Global $g_sSignal = @TempDir & "\hkz-failure-" & @AutoItPID & ".ready"
If $CmdLine[0] Then
    If $CmdLine[1] = "probe" Then
        If HotKeySet("^!+{F9}", "_FailureSink") Then Exit 9
        Exit 0
    EndIf
    If $CmdLine[1] = "hold" Then
        If Not HotKeySet("^!+{F10}", "_FailureSink") Then Exit 8
        FileWrite($CmdLine[2], "ready")
        Sleep(20000)
        HotKeySet("^!+{F10}")
        Exit 0
    EndIf
EndIf
If FileExists($APP_INI_PATH) Or FileExists($APP_INI_PATH & ".bak") Or FileExists($APP_INI_PATH & ".tmp") Or FileExists($g_sSignal) Then Exit 2
OnAutoItExitRegister("_FailureCleanup")
$g_bOwnProfile = True
IniWrite($APP_INI_PATH, "Options", "Main", "^!+{F11}")
$g_sTrayToggleErrorHandler = "_FailureReport"
Global $aOrdinary = _HotkeyModel_Create("^!+{F9}", $HOTKEY_ACTION_COMMAND, "echo ordinary"), $aSide = _HotkeyModel_Create("^!+{F10}", $HOTKEY_ACTION_COMMAND, "echo side")
$aSide[$HOTKEY_FIELD_CTRL_SIDE] = $HOTKEY_SIDE_LEFT
_FailureCheck(_HotkeyRegistry_BindRecord($aOrdinary), "register ordinary shortcut")
$g_sSideInstallHandler = "_FailureInstall"
_FailureCheck(Not _SideHotkeys_Register($aSide), "hook installation failure is reported")
_FailureCheck($g_iSideCount = 0 And $g_hSideHook = 0 And $g_hSideCallback = 0, "failed installation cleans callback and registration")
_FailureProbeOrdinary()
$g_sSideInstallHandler = "_SideHotkeys_NativeInstall"
_FailureCheck(_SideHotkeys_Register($aSide), "side shortcut recovers after installation failure")
$g_sSideUnhookHandler = "_FailureUnhook"
_FailureCheck(_SideHotkeys_Unregister($aSide), "release side shortcut before stop")
_SideHotkeys_Poll()
_FailureCheck($g_bSideHookStopFailed And $g_hSideHook <> 0 And $g_hSideCallback <> 0, "failed unhook retains callback and marks observer unsafe")
_FailureCheck($g_hWarningWindow <> 0, "unhook failure shows nonblocking warning")
Global $hOriginalWarning = $g_hWarningWindow, $sLongWarning = "Details: " & StringFormat("%0400d", 0)
_AppWarning_ReportNonBlocking($sLongWarning)
_FailureCheck($g_hWarningWindow = $hOriginalWarning And StringInStr(GUICtrlRead($g_iWarningText), $sLongWarning) > 0, "long warning is appended without losing text or opening a blocking window")
Global $sWarning = GUICtrlRead($g_iWarningText)
_SideHotkeys_Poll()
_FailureCheck(GUICtrlRead($g_iWarningText) = $sWarning, "unhook retry does not repeat warning")
_FailureCheck(Not _SideHotkeys_Start(), "unsafe observer cannot be reused")
_mainGui()
_FailureCheck(IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]), "settings can open while warning is visible")
_guiDel()
_FailureProbeOrdinary()
$g_sSideUnhookHandler = "_SideHotkeys_NativeUnhook"
_SideHotkeys_Poll()
_FailureCheck(Not $g_bSideHookStopFailed And $g_hSideHook = 0 And $g_hSideCallback = 0, "successful retry releases hook and callback")
_AppWarning_Close()
; Failed refresh plus failed unregister must not dispatch stale side events.
_FailureCheck(_SideHotkeys_Register($aSide), "register side for refresh failure")
$g_sSideUnhookHandler = "_FailureUnhook"
$g_sSideUnregisterHandler = "_FailureUnregister"
_FailureCheck(Not _SideHotkeys_RefreshObserver(), "refresh failure reported")
_FailureCheck($g_bSideHookStopFailed And $g_iSideCount = 1 And $g_hWarningWindow <> 0, "failed release retains state and warning")
_FailureCheck(StringInStr(GUICtrlRead($g_iWarningText), "could not be released") > 0, "warning explains shortcut may remain captured")
$sWarning = GUICtrlRead($g_iWarningText)
_SideHotkeys_RefreshObserver()
_FailureCheck(GUICtrlRead($g_iWarningText) = $sWarning, "repeated refresh failure does not repeat warning")
Global $tEvent = DllStructCreate("dword vk;dword scan;dword flags;dword time;ulong_ptr extra"), $iQueueBefore = $g_iSideQueueWrite
DllStructSetData($tEvent, "vk", 0x79)
_SideHotkeys_Observe(0, 0x100, DllStructGetPtr($tEvent))
_FailureCheck($g_iSideQueueWrite = $iQueueBefore, "unsafe observer cannot queue side actions")
_FailureProbeOrdinary()
$g_sSideUnregisterHandler = "_SideHotkeys_NativeUnregister"
$g_sSideUnhookHandler = "_SideHotkeys_NativeUnhook"
_FailureCheck(_SideHotkeys_Unregister($aSide), "release retained shortcut on recovery")
_SideHotkeys_Poll()
_AppWarning_Close()
; A failed disable must restore earlier shortcuts and retain enabled state.
$aHotkeys = _HotkeyRepository_CreateTable(2)
_HotkeyRepository_SetRecord($aHotkeys, 1, $aOrdinary)
_HotkeyRepository_SetRecord($aHotkeys, 2, $aSide)
_FailureCheck(_SideHotkeys_Register($aSide), "register side for disable rollback")
$enabled = False
$g_sSideUnregisterHandler = "_FailureUnregister"
_FailureCheck(Not _toggle() And Not $enabled, "failed disable retains enabled state")
_FailureCheck($g_iSideCount = 1 And StringInStr($g_sToggleError, "could not be disabled") > 0, "failed disable retains side and reports error")
_FailureProbeOrdinary()
$g_sSideUnregisterHandler = "_SideHotkeys_NativeUnregister"
_toggle()
_FailureCheck($enabled, "disable succeeds after failure clears")
_SideHotkeys_Poll()
; External registration conflict on the second entry must undo the first.
$g_iChild = Run('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" hold "' & $g_sSignal & '"', "", @SW_HIDE)
Global $hWait = TimerInit()
While Not FileExists($g_sSignal) And ProcessExists($g_iChild) And TimerDiff($hWait) < 5000
    Sleep(10)
WEnd
If Not FileExists($g_sSignal) Then _FailureFatal("external conflict fixture did not start")
_FailureCheck(Not _toggle() And $enabled, "failed re-enable retains disabled state")
_FailureCheck($g_iSideCount = 0 And StringInStr($g_sToggleError, "could not be registered") > 0, "conflict is reported without side registration")
_FailureCheck(_HotkeyRegistry_TrySet("^!+{F9}", "_FailureSink"), "earlier shortcut released by rollback")
_HotkeyRegistry_TrySet("^!+{F9}")
ProcessClose($g_iChild)
ProcessWaitClose($g_iChild, 5)
$g_iChild = 0
_toggle()
_FailureCheck(Not $enabled And $g_iSideCount = 1, "re-enable recovers when conflict is removed")
_toggle()
_FailureCheck($enabled, "normal disable still works")
_SideHotkeys_Poll()
; Inject rollback failure and check a nonblocking warning instead of silence.
_HotkeyRegistry_ConfigureHotkeyBackend("_FailureRollbackBackend")
$enabled = False
_FailureCheck(Not _toggle(), "failed rollback returns failure")
_FailureCheck($g_hWarningWindow <> 0 And StringInStr(GUICtrlRead($g_iWarningText), "could not be restored") > 0, "partial rollback warns user")
_mainGui()
_FailureCheck(IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]), "settings remains usable during rollback warning")
_guiDel()
_AppWarning_Close()
_HotkeyRegistry_ResetHotkeyBackend()
$aHotkeys = _HotkeyRepository_CreateTable(0)
ConsoleWrite("Side failure assertions=" & $g_iChecks & "; failures=" & $g_iFailures & "; x64=" & @AutoItX64 & @CRLF)
If $g_iFailures Then Exit 1
Func _FailureProbeOrdinary()
    Local $iExit = RunWait('"' & @AutoItExe & '" /ErrorStdOut "' & @ScriptFullPath & '" probe', "", @SW_HIDE)
    _FailureCheck($iExit = 0, "unrelated ordinary shortcut remains registered")
EndFunc
Func _FailureInstall($pCallback)
    #forceref $pCallback
    Return SetError(1, 0, 0)
EndFunc
Func _FailureUnhook($hHook)
    #forceref $hHook
    Return SetError(1, 0, False)
EndFunc
Func _FailureUnregister($hWindow, $iId)
    #forceref $hWindow, $iId
    Return False
EndFunc
Func _FailureReport($sMessage, $iError, $iExtended)
    $g_sToggleError = $sMessage
    Return SetError($iError, $iExtended, False)
EndFunc
Func _FailureRollbackBackend($sHotkey, $sHandler)
    If $sHotkey = "^!+{F10}" And $sHandler = "" Then Return False
    If $sHotkey = "^!+{F9}" And $sHandler <> "" Then Return False
    Return True
EndFunc
Func _FailureSink()
EndFunc
Func _FailureCheck($bOk, $sMessage)
    $g_iChecks += 1
    If $bOk Then Return
    $g_iFailures += 1
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
EndFunc
Func _FailureFatal($sMessage)
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
    Exit 1
EndFunc
Func _FailureCleanup()
    If $g_iChild And ProcessExists($g_iChild) Then ProcessClose($g_iChild)
    $g_sSideUnhookHandler = "_SideHotkeys_NativeUnhook"
    $g_sSideUnregisterHandler = "_SideHotkeys_NativeUnregister"
    _HotkeyRegistry_ResetHotkeyBackend()
    _SideHotkeys_Unregister($aSide)
    _HotkeyRegistry_TrySet("^!+{F9}")
    _SideHotkeys_Shutdown()
    _AppWarning_Close()
    If IsHWnd($g_aGuiState[$GUI_STATE_MAIN_WINDOW]) Then GUIDelete($g_aGuiState[$GUI_STATE_MAIN_WINDOW])
    FileDelete($g_sSignal)
    If $g_bOwnProfile Then
        FileDelete($APP_INI_PATH)
        FileDelete($APP_INI_PATH & ".bak")
        FileDelete($APP_INI_PATH & ".tmp")
    EndIf
EndFunc
