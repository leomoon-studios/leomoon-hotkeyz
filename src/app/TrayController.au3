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
    Local $iTrayMessage = TrayGetMsg()
    If $iTrayMessage = 0 Then Return
    _Debug_Log("Tray message received: " & $iTrayMessage)
    Switch $iTrayMessage
        Case $enableTray
            _Debug_Log("Toggle menu item selected")
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
    Local $i
    ;$enabled = Not $enabled
    If $enabled == False Then ;disable it
        For $i = 1 To _HotkeyRepository_Count($aHotkeys)
            If Not _HotkeyRegistry_TrySet($aHotkeys[$i][$HOTKEY_FIELD_HOTKEY]) Then Return _AppError_Report("A hotkey could not be disabled", 1, $i)
        Next
        $enabled = True
        TraySetIcon(@ScriptFullPath, 202)
        TrayItemSetState($enableTray, $TRAY_UNCHECKED)
        TraySetToolTip($APP_TITLE&" is disabled.")
    Else
        For $i = 1 To _HotkeyRepository_Count($aHotkeys)
            If Not _HotkeyRegistry_TrySet($aHotkeys[$i][$HOTKEY_FIELD_HOTKEY], "HotKeyPressed") Then Return _AppError_Report("A hotkey is unavailable because Windows or another application uses it", 1, $i)
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
    If Not _HotkeyRegistry_TrySet($appHotkey, $function) Then
        TrayItemSetText($trayItem, $text & @TAB & "Shortcut unavailable")
        _AppWarning_Report("The main toggle hotkey is already in use. LeoMoon HotKeyz is still running, and you can choose another hotkey in Settings.")
        Return True
    EndIf
    TrayItemSetText($trayItem, $text&@TAB&_HotkeyCodec_DecodeHotkey($appHotkey))
    Return True
EndFunc

Func _web()
    Local $iPid = ShellExecute('http://leomoon.com', '', '', '', @SW_HIDE)
    If @error Or $iPid = 0 Then Return _AppError_Report("The LeoMoon Studios website could not be opened", 1, @error)
    Return True
EndFunc

Func _exit()
    Exit
EndFunc
