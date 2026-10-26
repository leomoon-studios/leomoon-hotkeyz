#include-once

#include <Constants.au3>
#include "ErrorReporter.au3"

Global $enabled = False
Global $enableTray

Func _TrayController_Initialize($sIniFile)
    TraySetClick(8)
    TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE, "_toggle")
    TrayCreateItem($APP_TITLE & " " & $APP_VERSION)
    TrayItemSetState(-1, $TRAY_DISABLE)
    TrayCreateItem("")
    $enableTray = TrayCreateItem("Enable " & $APP_TITLE)
    TrayItemSetOnEvent(-1, "_toggle")
    TrayItemSetState(-1, $TRAY_CHECKED)
    TrayCreateItem("")
    TrayCreateItem("Settings...")
    TrayItemSetOnEvent(-1, "_mainGui")
    TrayCreateItem("")
    TrayCreateItem("Visit LeoMoon Studios website")
    TrayItemSetOnEvent(-1, "_web")
    TrayCreateItem("")
    TrayCreateItem("Exit")
    TrayItemSetOnEvent(-1, "_exit")
    If Not _readHotkey($sIniFile, "Options", "Main", $enableTray, "Enable " & $APP_TITLE, "_toggle", $APP_DEFAULT_TOGGLE_HOTKEY) Then Return False
    TraySetToolTip($APP_TITLE & " is enabled.")
    Return True
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
    If Not _HotkeyRegistry_TrySet($appHotkey, $function) Then Return _AppError_Report("The main toggle hotkey is unavailable", 1, 0)
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
