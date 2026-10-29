#include-once

#include <Constants.au3>
#include "ErrorReporter.au3"

Global $enabled = False
Global $enableTray
Global $g_iSettingsTrayItem
Global $g_iWebsiteTrayItem
Global $g_iExitTrayItem
Global Const $APP_DEBUG_LOG_PATH = @TempDir & "\\LeoMoon-HotKeyz-debug.log"

Func _Debug_Log($sMessage)
    Local $hLog = FileOpen($APP_DEBUG_LOG_PATH, 1)
    If $hLog = -1 Then Return False
    FileWrite($hLog, @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & " | " & $sMessage & @CRLF)
    FileClose($hLog)
    Return True
EndFunc

Func _TrayController_Initialize($sIniFile)
    FileDelete($APP_DEBUG_LOG_PATH)
    _Debug_Log("Tray initialization started")
    TraySetClick(8)
    TrayCreateItem($APP_TITLE & " " & $APP_VERSION)
    TrayItemSetState(-1, $TRAY_DISABLE)
    TrayCreateItem("")
    $enableTray = TrayCreateItem("Enable " & $APP_TITLE)
    TrayItemSetState(-1, $TRAY_CHECKED)
    TrayCreateItem("")
    $g_iSettingsTrayItem = TrayCreateItem("Settings...")
    TrayCreateItem("")
    $g_iWebsiteTrayItem = TrayCreateItem("Visit LeoMoon Studios website")
    TrayCreateItem("")
    $g_iExitTrayItem = TrayCreateItem("Exit")
    _Debug_Log("Tray item IDs: toggle=" & $enableTray & ", settings=" & $g_iSettingsTrayItem & ", website=" & $g_iWebsiteTrayItem & ", exit=" & $g_iExitTrayItem)
    If Not _readHotkey($sIniFile, "Options", "Main", $enableTray, "Enable " & $APP_TITLE, "_toggle", $APP_DEFAULT_TOGGLE_HOTKEY) Then Return False
    TraySetToolTip($APP_TITLE & " is enabled.")
    _Debug_Log("Tray initialization completed")
    Return True
EndFunc

Func _TrayController_ProcessEvents()
    _SideHotkeys_Poll()
    Local $iTrayMessage = TrayGetMsg()
    If $iTrayMessage = 0 Then Return
    _Debug_Log("Tray message received: " & $iTrayMessage)
    Switch $iTrayMessage
        Case $enableTray, $TRAY_EVENT_PRIMARYDOUBLE
            _Debug_Log("Toggle requested by tray menu or double-click")
            _toggle()
        Case $g_iSettingsTrayItem
            _Debug_Log("Settings menu item selected")
            _mainGui()
            _Debug_Log("Settings menu handler returned")
        Case $g_iWebsiteTrayItem
            _Debug_Log("Website menu item selected")
            _web()
        Case $g_iExitTrayItem
            _Debug_Log("Exit menu item selected")
            _exit()
    EndSwitch
EndFunc

Func _toggle()
    $g_iSideGeneration += 1
    Local $i, $j, $aRollbackRecord
    ;$enabled = Not $enabled
    If $enabled == False Then ;disable it
        For $i = 1 To _HotkeyRepository_Count($aHotkeys)
            Local $aDisabledRecord = _HotkeyRepository_GetRecord($aHotkeys, $i)
            If Not _HotkeyRegistry_UnbindRecord($aDisabledRecord) Then
                For $j = 1 To $i - 1
                    $aRollbackRecord = _HotkeyRepository_GetRecord($aHotkeys, $j)
                    _HotkeyRegistry_BindRecord($aRollbackRecord)
                Next
                Return _AppError_Report("A hotkey could not be disabled", 1, $i)
            EndIf
        Next
        $enabled = True
        TraySetIcon(@ScriptFullPath, 202)
        TrayItemSetState($enableTray, $TRAY_UNCHECKED)
        TraySetToolTip($APP_TITLE&" is disabled.")
    Else
        For $i = 1 To _HotkeyRepository_Count($aHotkeys)
            Local $aEnabledRecord = _HotkeyRepository_GetRecord($aHotkeys, $i)
            If Not _HotkeyRegistry_BindRecord($aEnabledRecord) Then
                For $j = 1 To $i - 1
                    $aRollbackRecord = _HotkeyRepository_GetRecord($aHotkeys, $j)
                    _HotkeyRegistry_UnbindRecord($aRollbackRecord)
                Next
                Return _AppError_Report("A hotkey could not be registered. Windows or another application may be using it", 1, $i)
            EndIf
        Next
        $enabled = False
        TraySetIcon(@ScriptFullPath, 201)
        TrayItemSetState($enableTray, $TRAY_CHECKED)
        TraySetToolTip($APP_TITLE&" is enabled.")
    EndIf
EndFunc

Func _readHotkey($iniFile, $section, $key, $trayItem, $text, $function, $default)
    ;inifile to read
    ;section of the ini
    ;key of the ini
    ;trayitem id to append the new hotkey
    ;trayitem text to append the new hotkey
    ;function to set hotkey
    Local $appHotkey = IniRead($iniFile, $section, $key, '')
    If $appHotkey == '' Then ;default hotkey if key not found in ini file
        $appHotkey = $default
        If Not IniWrite($iniFile, $section, $key, $appHotkey) Then Return _AppError_Report("The default main toggle hotkey could not be saved", 1, 0)
    EndIf
    $g_bLastToggleAvailable = _HotkeyRegistry_TrySet($appHotkey, $function)
    If Not $g_bLastToggleAvailable Then
        TrayItemSetText($trayItem, $text & @TAB & "Shortcut unavailable")
        _AppWarning_AddUnavailable("- Main toggle: " & _HotkeyCodec_DecodeHotkey($appHotkey) & @CRLF)
        Return True
    EndIf
    TrayItemSetText($trayItem, $text&@TAB&_HotkeyCodec_DecodeHotkey($appHotkey))
    Return True
EndFunc

Func _web()
    Local $iPid = ShellExecute('http://leomoon.com', '', '', '', @SW_HIDE)
    If @error Or $iPid = 0 Then Return _AppError_Notify("The LeoMoon Studios website could not be opened", 1, @error)
    Return True
EndFunc

Func _exit()
    Exit
EndFunc
