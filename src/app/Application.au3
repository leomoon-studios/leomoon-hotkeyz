#include-once

Global $g_bApplicationShuttingDown = False

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
