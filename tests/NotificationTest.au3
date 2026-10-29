#NoTrayIcon
#include "..\src\core\AppConstants.au3"
#include "..\src\app\HotkeyRegistry.au3"
#include "..\src\app\Application.au3"
Opt("MustDeclareVars", 1)
Global $g_iCalls = 0, $g_iSchedule = 0, $g_iFailures = 0, $g_iChecks = 0
Global $g_aNotifications[30][4], $g_iDelay = 0
$g_sNotificationTrayHandler = "_NoticeTraySpy"
$g_sNotificationScheduleHandler = "_NoticeScheduleSpy"
_AudioDeviceActions_Notify($AUDIO_FLOW_RENDER, "Speaker A")
_NoticeCheck($g_iCalls = 2 And $g_aNotifications[0][0] = "" And $g_aNotifications[1][0] = "Playback Device", "audio clears then displays")
_NoticeCheck($g_iDelay = 2000 And $g_aNotifications[1][3] = 1, "audio duration and icon preserved")
Global $aRecord = _HotkeyModel_Create("^!a", $HOTKEY_ACTION_FILE, @TempDir & "\hkz-notice-missing-" & @AutoItPID & "\missing.exe")
Global $bResult = _HotkeyRegistry_ExecuteRecord($aRecord, True), $iError = @error
_NoticeCheck(Not $bResult And $iError = $HOTKEY_REGISTRY_ERROR_DISPATCH, "missing target retains error result")
_NoticeCheck($g_iCalls = 4 And $g_aNotifications[2][0] = "" And $g_aNotifications[3][0] = "LeoMoon HotKeyz", "error replaces audio")
_NoticeCheck(StringInStr($g_aNotifications[3][1], "File or folder not found") And StringInStr($g_aNotifications[3][1], "Ctrl + Alt + A") And StringInStr($g_aNotifications[3][1], "missing.exe"), "missing target notice contains shortcut and target")
_NoticeCheck($g_iDelay = 5000 And $g_aNotifications[3][3] = 3, "error duration and icon")
_NoticeCheck(StringInStr($g_sLastApplicationError, "target file or folder does not exist") And StringInStr($g_sLastApplicationError, "missing.exe"), "full error remains in diagnostics")
_AudioDeviceActions_Notify($AUDIO_FLOW_CAPTURE, "Headset")
_NoticeCheck($g_iCalls = 6 And $g_aNotifications[4][0] = "" And $g_aNotifications[5][0] = "Recording Device", "audio replaces error")
Global $iBefore = $g_iCalls
_HotkeyRegistry_ExecuteRecord($aRecord, False)
_NoticeCheck($g_iCalls = $iBefore, "suppressed error does not show a notification")
Global $aLockRecord = _HotkeyModel_Create("^!b", $HOTKEY_ACTION_TEXT, "example")
$aLockRecord[$HOTKEY_FIELD_CAPS_LOCK] = $HOTKEY_LOCK_ON
$g_sActionLockReader = "_NoticeFailLockRead"
_HotkeyRegistry_ExecuteRecord($aLockRecord, True)
_NoticeCheck(StringInStr($g_aNotifications[$g_iCalls - 1][1], "input state") And StringInStr($g_aNotifications[$g_iCalls - 1][1], "Ctrl + Alt + B"), "state-read failure notifies with shortcut")
$g_sOpticalListHandler = "_NoticeNoDrives"
Global $aOptical = _HotkeyModel_Create("^!c", $HOTKEY_ACTION_SYSTEM, "Open optical drive tray D:")
_HotkeyRegistry_ExecuteRecord($aOptical, True)
_NoticeCheck(StringInStr($g_aNotifications[$g_iCalls - 1][1], "Optical drive not connected") And StringInStr($g_aNotifications[$g_iCalls - 1][1], "D:"), "missing optical drive notification identifies target")
_ProcessActions_ConfigureShellBackend("_NoticeShellFailure")
Global $aCommand = _HotkeyModel_Create("^!d", $HOTKEY_ACTION_COMMAND, "test command")
_HotkeyRegistry_ExecuteRecord($aCommand, True)
_NoticeCheck(StringInStr($g_aNotifications[$g_iCalls - 1][1], "could not be completed") And StringInStr($g_aNotifications[$g_iCalls - 1][1], "Ctrl + Alt + D"), "generic action failure notifies")
_AppError_Notify("Website failed", 1, 0)
_NoticeCheck($g_aNotifications[$g_iCalls - 2][0] = "" And $g_aNotifications[$g_iCalls - 1][1] = "Website failed", "website-style error replaces previous notice")
_Notification_Show("Long", StringFormat("%0300d", 0), 5, 3)
_NoticeCheck(StringLen($g_aNotifications[$g_iCalls - 1][1]) = 250 And StringRight($g_aNotifications[$g_iCalls - 1][1], 3) = "...", "long notification is bounded")
; Use real adlib scheduling with a spy tray: an old short timer must not clear a newer notice.
$g_sNotificationScheduleHandler = "_Notification_NativeSchedule"
_Notification_Show("First", "first", 1, 1)
_Notification_Show("Second", "second", 3, 3)
$iBefore = $g_iCalls
Sleep(1300)
_NoticeCheck($g_iCalls = $iBefore, "replaced notification is not cleared by old timer")
_Notification_Clear()
_NoticeCheck($g_iCalls = $iBefore + 1 And $g_aNotifications[$g_iCalls - 1][0] = "", "shared timer clears current notification")
$g_sNotificationScheduleHandler = "_NoticeScheduleSpy"
$iBefore = $g_iCalls
_AppWarning_BeginStartup()
_AppWarning_AddUnavailable("- Ctrl + Alt + A" & @CRLF)
_AppWarning_AddUnavailable("- Main toggle: Ctrl + Alt + B" & @CRLF)
_NoticeCheck($g_iCalls = $iBefore, "startup conflicts wait until tray is initialized")
_AppWarning_FinishStartup()
_NoticeCheck($g_iCalls = $iBefore + 2 And StringInStr($g_aNotifications[$g_iCalls - 1][1], "Ctrl + Alt + A") And StringInStr($g_aNotifications[$g_iCalls - 1][1], "Main toggle"), "startup conflicts share one notification")
_NoticeCheck($g_hWarningWindow = 0 And $g_iDelay = 7000, "startup conflicts are nonblocking and readable")
_AppWarning_AddUnavailable("- Ctrl + Alt + F9" & @CRLF)
_NoticeCheck(StringInStr($g_aNotifications[$g_iCalls - 1][1], "Ctrl + Alt + F9"), "later startup-style warning replaces previous notification")
_AppWarning_AddUnavailable(StringFormat("%0200d", 0))
_NoticeCheck(StringLen($g_aNotifications[$g_iCalls - 1][1]) <= 250 And StringInStr($g_aNotifications[$g_iCalls - 1][1], "..."), "long startup list is shortened safely")
$iBefore = $g_iCalls
_NoticeCheck(_Application_Compose("ignored", "_NoticeRegistryStartup", "_NoticeTrayStartup"), "application composition succeeds")
_NoticeCheck($g_iCalls = $iBefore + 2 And StringInStr($g_aNotifications[$g_iCalls - 1][1], "Ctrl + Alt + X") And StringInStr($g_aNotifications[$g_iCalls - 1][1], "Main toggle"), "application sends one combined notification after both initializers")
If $g_iFailures Then Exit 1
ConsoleWrite("PASSED: " & $g_iChecks & " notification assertions" & @CRLF)
Func _NoticeTraySpy($sTitle, $sText, $iSeconds, $iIcon)
    $g_aNotifications[$g_iCalls][0] = $sTitle
    $g_aNotifications[$g_iCalls][1] = $sText
    $g_aNotifications[$g_iCalls][2] = $iSeconds
    $g_aNotifications[$g_iCalls][3] = $iIcon
    $g_iCalls += 1
    Return 1
EndFunc
Func _NoticeScheduleSpy($iMilliseconds)
    $g_iSchedule += 1
    $g_iDelay = $iMilliseconds
    Return 1
EndFunc
Func _NoticeFailLockRead($iKey)
    #forceref $iKey
    Return SetError(1, 0, 0)
EndFunc
Func _NoticeNoDrives()
    Local $aEmpty[1] = [0]
    Return $aEmpty
EndFunc
Func _NoticeRegistryStartup($sIniFile)
    #forceref $sIniFile
    _AppWarning_AddUnavailable("- Ctrl + Alt + X" & @CRLF)
    Return True
EndFunc
Func _NoticeTrayStartup($sIniFile)
    #forceref $sIniFile
    _AppWarning_AddUnavailable("- Main toggle: Ctrl + Alt + Y" & @CRLF)
    Return True
EndFunc
Func _NoticeShellFailure($sTarget, $sParameters, $sWorkingDirectory, $sVerb, $iShow)
    #forceref $sTarget, $sParameters, $sWorkingDirectory, $sVerb, $iShow
    Return 0
EndFunc
Func _NoticeCheck($bOk, $sMessage)
    $g_iChecks += 1
    If $bOk Then Return
    $g_iFailures += 1
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
EndFunc
