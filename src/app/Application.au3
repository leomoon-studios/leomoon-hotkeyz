#include-once

Global $g_bApplicationShuttingDown = False

Func _Application_EnableGdiScaling()
    ; Keep DPI-unaware coordinate behavior while letting Windows render GDI
    ; text and controls at the display's DPI. Windows before 10 version 1809
    ; lacks this context; leave its existing DPI behavior unchanged.
    ; Process-wide mode also covers native popups such as the tray menu.
    Local $aResult = DllCall("user32.dll", "bool", "SetProcessDpiAwarenessContext", "ptr", -5)
    If Not @error And IsArray($aResult) And $aResult[0] Then Return True
    ; If AutoIt or a compatibility setting has already established a process
    ; mode, retain sharp rendering for windows created by this thread.
    $aResult = DllCall("user32.dll", "handle", "SetThreadDpiAwarenessContext", "ptr", -5)
    If @error Or Not IsArray($aResult) Or Not $aResult[0] Then Return False
    Return True
EndFunc

Func _Application_Compose($sIniFile, $sRegistryInitializer = "_HotkeyRegistry_Initialize", $sTrayInitializer = "_TrayController_Initialize")
    ; Gather both action and main-toggle conflicts into one notification after
    ; the tray is initialized, so one startup warning does not replace another.
    _AppWarning_BeginStartup()
    Local $vRegistryResult = Call($sRegistryInitializer, $sIniFile)
    If @error Or Not $vRegistryResult Then
        _AppWarning_FinishStartup(False)
        Return SetError(1, 0, False)
    EndIf
    Local $vTrayResult = Call($sTrayInitializer, $sIniFile)
    If @error Or Not $vTrayResult Then
        _AppWarning_FinishStartup(False)
        Return SetError(2, 0, False)
    EndIf
    _AppWarning_FinishStartup()
    Return True
EndFunc

Func _Application_Shutdown()
    If $g_bApplicationShuttingDown Then Return
    $g_bApplicationShuttingDown = True
    _HotkeyRegistry_Shutdown()
EndFunc
