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
    Switch _SystemActions_GetId($sTarget)
        Case $SYSTEM_ACTION_EMPTY_RECYCLE_BIN
            _EmptyRecycleBin()
        Case $SYSTEM_ACTION_LOCK
            _Lock()
        Case $SYSTEM_ACTION_LOG_OFF
            _LogOff()
        Case $SYSTEM_ACTION_RESTART
            _Restart()
        Case $SYSTEM_ACTION_SHUTDOWN
            _Shutdown()
        Case $SYSTEM_ACTION_TURN_OFF_MONITORS
            _TurnOffMonitors()
        Case $SYSTEM_ACTION_TURN_OFF_MONITORS_AND_LOCK
            _TurnOffMonitorsAndLock()
        Case $SYSTEM_ACTION_START_SCREENSAVER
            _StartScreensaver()
        Case $SYSTEM_ACTION_START_SCREENSAVER_AND_LOCK
            _StartScreensaverAndLock()
        Case $SYSTEM_ACTION_EMPTY_CLIPBOARD
            _EmptyClipboard()
        Case Else
            Return SetError(1, 0, False)
    EndSwitch
    Return True
EndFunc

Func _StartScreensaver()
    ;~ _WinAPI_Wow64EnableWow64FsRedirection(False)
    Run('ssText3d.scr /s')
    ;~ _WinAPI_Wow64EnableWow64FsRedirection(True)
EndFunc

Func _StartScreensaverAndLock()
    ;~ _WinAPI_Wow64EnableWow64FsRedirection(False)
    ;~ _RunDos('start /wait ssText3d.scr /s & rundll32 user32.dll,LockWorkStation')
    RunWait('ssText3d.scr /s')
    ;~ _WinAPI_Wow64EnableWow64FsRedirection(True)
    _Lock()
EndFunc

Func _EmptyClipboard()
    _ClipBoard_Open(WinGetHandle("[ACTIVE]"))
    _ClipBoard_Empty()
    _ClipBoard_Close()
    ClipPut('')
    ;~ ConsoleWrite('DONE'&@LF)
EndFunc

Func _Lock()
    ShellExecute('Rundll32.exe', 'User32.dll,LockWorkStation', '', '', @SW_HIDE)
EndFunc

Func _LogOff()
    Shutdown(0)
EndFunc

Func _Restart()
    Shutdown(2)
EndFunc

Func _Shutdown()
    Shutdown(1)
EndFunc

Func _EmptyRecycleBin()
    FileRecycleEmpty()
EndFunc

Func _TurnOffMonitorsAndLock()
    _TurnOffMonitors()
    _Lock()
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
    DllCall("user32.dll", "int", "SendMessage", "hwnd", $hWnd, _
            "int", $WM_SYSCommand, "int", $SC_MonitorPower, "int", $Param)
    Opt("WinTitleMatchMode", $opt)
EndFunc
