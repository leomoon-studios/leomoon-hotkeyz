#include-once

Global $g_bApplicationShuttingDown = False

Func _Application_Compose($sIniFile, $sRegistryInitializer = "_HotkeyRegistry_Initialize", $sTrayInitializer = "_TrayController_Initialize")
    Local $vRegistryResult = Call($sRegistryInitializer, $sIniFile)
    If @error Or Not $vRegistryResult Then Return SetError(1, 0, False)
    Local $vTrayResult = Call($sTrayInitializer, $sIniFile)
    If @error Or Not $vTrayResult Then Return SetError(2, 0, False)
    Return True
EndFunc

Func _Application_Shutdown()
    If $g_bApplicationShuttingDown Then Return
    $g_bApplicationShuttingDown = True
    _HotkeyRegistry_Shutdown()
EndFunc
