#include-once

#include <Clipboard.au3>
#include <WinAPISys.au3>

Global Enum $SYSTEM_ACTION_NONE = 0, _
            $SYSTEM_ACTION_EMPTY_RECYCLE_BIN, _
            $SYSTEM_ACTION_LOCK, _
            $SYSTEM_ACTION_LOG_OFF, _
            $SYSTEM_ACTION_RESTART, _
            $SYSTEM_ACTION_SHUTDOWN, _
            $SYSTEM_ACTION_TURN_OFF_MONITORS, _
            $SYSTEM_ACTION_TURN_OFF_MONITORS_AND_LOCK, _
            $SYSTEM_ACTION_START_SCREENSAVER, _
            $SYSTEM_ACTION_START_SCREENSAVER_AND_LOCK, _
            $SYSTEM_ACTION_EMPTY_CLIPBOARD

Func _SystemActions_GetId($sTarget)
    Switch $sTarget
        Case "Empty Recycle Bin"
            Return $SYSTEM_ACTION_EMPTY_RECYCLE_BIN
        Case "Lock"
            Return $SYSTEM_ACTION_LOCK
        Case "Log Off"
            Return $SYSTEM_ACTION_LOG_OFF
        Case "Restart"
            Return $SYSTEM_ACTION_RESTART
        Case "Shutdown"
            Return $SYSTEM_ACTION_SHUTDOWN
        Case "Turn Off Monitors"
            Return $SYSTEM_ACTION_TURN_OFF_MONITORS
        Case "Turn Off Monitors And Lock"
            Return $SYSTEM_ACTION_TURN_OFF_MONITORS_AND_LOCK
        Case "Start Screensaver"
            Return $SYSTEM_ACTION_START_SCREENSAVER
        Case "Start Screensaver And Lock"
            Return $SYSTEM_ACTION_START_SCREENSAVER_AND_LOCK
        Case "Empty Clipboard"
            Return $SYSTEM_ACTION_EMPTY_CLIPBOARD
    EndSwitch
    Return $SYSTEM_ACTION_NONE
EndFunc

Func _SystemActions_Execute($sTarget)
    Local $vResult
    Switch _SystemActions_GetId($sTarget)
        Case $SYSTEM_ACTION_EMPTY_RECYCLE_BIN
            $vResult = _EmptyRecycleBin()
        Case $SYSTEM_ACTION_LOCK
            $vResult = _Lock()
        Case $SYSTEM_ACTION_LOG_OFF
            $vResult = _LogOff()
        Case $SYSTEM_ACTION_RESTART
            $vResult = _Restart()
        Case $SYSTEM_ACTION_SHUTDOWN
            $vResult = _Shutdown()
        Case $SYSTEM_ACTION_TURN_OFF_MONITORS
            $vResult = _TurnOffMonitors()
        Case $SYSTEM_ACTION_TURN_OFF_MONITORS_AND_LOCK
            $vResult = _TurnOffMonitorsAndLock()
        Case $SYSTEM_ACTION_START_SCREENSAVER
            $vResult = _StartScreensaver()
        Case $SYSTEM_ACTION_START_SCREENSAVER_AND_LOCK
            $vResult = _StartScreensaverAndLock()
        Case $SYSTEM_ACTION_EMPTY_CLIPBOARD
            $vResult = _EmptyClipboard()
        Case Else
            Return SetError(1, 0, False)
    EndSwitch
    If Not $vResult Then Return SetError(2, @error, False)
    Return True
EndFunc

Func _StartScreensaver()
    ;~ _WinAPI_Wow64EnableWow64FsRedirection(False)
    Local $iPid = Run('ssText3d.scr /s')
    ;~ _WinAPI_Wow64EnableWow64FsRedirection(True)
    Return $iPid <> 0
EndFunc

Func _StartScreensaverAndLock()
    ;~ _WinAPI_Wow64EnableWow64FsRedirection(False)
    ;~ _RunDos('start /wait ssText3d.scr /s & rundll32 user32.dll,LockWorkStation')
    Local $iExitCode = RunWait('ssText3d.scr /s')
    ;~ _WinAPI_Wow64EnableWow64FsRedirection(True)
    If @error Or $iExitCode = -1 Then Return SetError(1, @error, False)
    Return _Lock()
EndFunc

Func _EmptyClipboard()
    If Not _ClipBoard_Open(WinGetHandle("[ACTIVE]")) Then Return SetError(1, 0, False)
    If Not _ClipBoard_Empty() Then
        _ClipBoard_Close()
        Return SetError(2, 0, False)
    EndIf
    If Not _ClipBoard_Close() Then Return SetError(3, 0, False)
    Return True
EndFunc

Func _Lock()
    Local $iPid = ShellExecute('Rundll32.exe', 'User32.dll,LockWorkStation', '', '', @SW_HIDE)
    If @error Or $iPid = 0 Then Return SetError(1, @error, False)
    Return True
EndFunc

Func _LogOff()
    Return Shutdown(0)
EndFunc

Func _Restart()
    Return Shutdown(2)
EndFunc

Func _Shutdown()
    Return Shutdown(1)
EndFunc

Func _EmptyRecycleBin()
    FileRecycleEmpty()
    Return Not @error
EndFunc

Func _TurnOffMonitorsAndLock()
    If Not _TurnOffMonitors() Then Return SetError(1, @error, False)
    Return _Lock()
EndFunc

Func _TurnOffMonitors($OnOff = 0)
    Sleep(500)
    ;turns off the monitor by default, but as it happens, monitor comes back on upon user input - keyboard or mouse
    Local $opt = Opt("WinTitleMatchMode", 4)
    Local $hWnd
    Local $Param
    Local $SC_MonitorPower
    Local $WM_SYSCommand
    If $OnOff = 0 Then
        $Param = 2
    Else
        $Param = -1
    EndIf
    $hWnd = WinGetHandle("classname=Progman")
    $WM_SYSCommand = 274
    $SC_MonitorPower = 61808
    Local $aResult = DllCall("user32.dll", "int", "SendMessage", "hwnd", $hWnd, _
            "int", $WM_SYSCommand, "int", $SC_MonitorPower, "int", $Param)
    Local $iCallError = @error
    Opt("WinTitleMatchMode", $opt)
    If $iCallError Or Not IsArray($aResult) Then Return SetError(1, $iCallError, False)
    Return True
EndFunc
