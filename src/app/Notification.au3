#include-once

; Audio notices and errors share one timer and one tray notification. A new
; notice cancels the previous timer before replacing the displayed message.
Global $g_sNotificationTrayHandler = "_Notification_NativeTray"
Global $g_sNotificationScheduleHandler = "_Notification_NativeSchedule"

Func _Notification_NativeTray($sTitle, $sText, $iSeconds, $iIcon)
    Return TrayTip($sTitle, $sText, $iSeconds, $iIcon)
EndFunc

Func _Notification_NativeSchedule($iMilliseconds)
    Return AdlibRegister("_Notification_Clear", $iMilliseconds)
EndFunc

Func _Notification_Show($sTitle, $sText, $iSeconds = 5, $iIcon = 3)
    AdlibUnRegister("_Notification_Clear")
    Call($g_sNotificationTrayHandler, "", "", 0, 0)
    ; Windows limits tray balloon text; keep the full error in the diagnostic log.
    If StringLen($sText) > 250 Then $sText = StringLeft($sText, 247) & "..."
    Call($g_sNotificationTrayHandler, $sTitle, $sText, $iSeconds, $iIcon)
    Call($g_sNotificationScheduleHandler, $iSeconds * 1000)
EndFunc

Func _Notification_Clear()
    AdlibUnRegister("_Notification_Clear")
    Call($g_sNotificationTrayHandler, "", "", 0, 0)
EndFunc
