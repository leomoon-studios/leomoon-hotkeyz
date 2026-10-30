; Desktop-only check: uses Windows tray balloons, without touching audio devices.
#include <ScreenCapture.au3>
#include "..\src\app\Notification.au3"
Opt("MustDeclareVars", 1)
Global $sOutput = @ScriptDir & "\..\build\visual-ui-conditions"
If Not DirCreate($sOutput) Then Exit 1
TraySetState(1)
Sleep(800)
_Notification_Show("LeoMoon HotKeyz", "Example action error", 5, 3)
Sleep(1500)
_ScreenCapture_Capture($sOutput & "\toast-action.png", @DesktopWidth - 540, @DesktopHeight - 440, @DesktopWidth - 1, @DesktopHeight - 1, False)
_Notification_Show("Playback Device", "Example headphones", 3, 1)
Sleep(80)
_Notification_Show("Playback Device", "Example monitor", 3, 1)
Sleep(80)
_Notification_Show("Playback Device", "Example speakers", 3, 1)
Sleep(1500)
_ScreenCapture_Capture($sOutput & "\toast-audio.png", @DesktopWidth - 540, @DesktopHeight - 440, @DesktopWidth - 1, @DesktopHeight - 1, False)
_Notification_Clear()
ConsoleWrite("Captured Windows tray notification area after action and audio examples." & @CRLF)
