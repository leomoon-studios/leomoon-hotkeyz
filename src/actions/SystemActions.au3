#include-once

#include <Clipboard.au3>
#include <WinAPISys.au3>

Func _SystemActions_Execute($sTarget)
    If Not _isKnownSpecialAction($HOTKEY_ACTION_SYSTEM, $sTarget) Then Return SetError(1, 0, False)
    Execute("_" & StringReplace($sTarget, " ", "") & "()")
    Return Not @error
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
