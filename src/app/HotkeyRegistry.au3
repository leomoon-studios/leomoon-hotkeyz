#include-once

#include "..\core\HotkeyRepository.au3"
#include "..\actions\ActionDispatcher.au3"
#include "ErrorReporter.au3"

Global $aHotkeys = _HotkeyRepository_CreateTable(0)

Func _HotkeyRegistry_Initialize($sIniFile)
    _iniCheck($sIniFile)
    _iniToApply($sIniFile)
    Return Not @error
EndFunc

Func _HotkeyRegistry_Shutdown()
    Local $i
    For $i = 1 To _HotkeyRepository_Count($aHotkeys)
        HotKeySet($aHotkeys[$i][$HOTKEY_FIELD_HOTKEY])
    Next
    Local $sToggleHotkey = IniRead($APP_INI_PATH, "Options", "Main", "")
    If $sToggleHotkey <> "" Then HotKeySet($sToggleHotkey)
EndFunc

Func _HotkeyRegistry_IsStartupEnabled()
    Local $sValue = RegRead($APP_STARTUP_REGISTRY_KEY, $APP_TITLE)
    If @error Then Return False
    Return $sValue <> ""
EndFunc

Func _HotkeyRegistry_SetStartupEnabled($bEnabled)
    If $bEnabled Then
        If Not RegWrite($APP_STARTUP_REGISTRY_KEY, $APP_TITLE, "REG_SZ", '"' & @ScriptFullPath & '"') Then Return SetError(1, @error, False)
        Return True
    EndIf
    RegRead($APP_STARTUP_REGISTRY_KEY, $APP_TITLE)
    If @error Then Return True
    If Not RegDelete($APP_STARTUP_REGISTRY_KEY, $APP_TITLE) Then Return SetError(2, @error, False)
    Return True
EndFunc

Global Const $HOTKEY_REGISTRY_ERROR_NOT_FOUND = 1
Global Const $HOTKEY_REGISTRY_ERROR_DISPATCH = 2

Func HotKeyPressed()
    Local $iRow = _HotkeyRegistry_FindHotkey(@HotKeyPressed)
    If @error Then Return SetError($HOTKEY_REGISTRY_ERROR_NOT_FOUND, 0, False)
    Local $aRecord = _HotkeyRepository_GetRecord($aHotkeys, $iRow)
    Return _HotkeyRegistry_ExecuteRecord($aRecord)
EndFunc

Func _HotkeyRegistry_FindHotkey($sHotkey)
    Local $i
    For $i = 1 To _HotkeyRepository_Count($aHotkeys)
        If $aHotkeys[$i][$HOTKEY_FIELD_HOTKEY] = $sHotkey Then Return $i
    Next
    Return SetError($HOTKEY_REGISTRY_ERROR_NOT_FOUND, 0, 0)
EndFunc

Func _HotkeyRegistry_ExecuteRecord(ByRef $aRecord)
    _aTags()
    If Not _ActionDispatcher_Dispatch($aRecord, $aTags) Then
        Local $iDispatchError = @error
        _AppError_Report("The hotkey action could not be completed", $HOTKEY_REGISTRY_ERROR_DISPATCH, $iDispatchError)
        Return SetError($HOTKEY_REGISTRY_ERROR_DISPATCH, $iDispatchError, False)
    EndIf
    Return True
EndFunc


Func _iniCheck($iniFile)
    If Not FileExists($iniFile) Then
        IniWrite($iniFile, 'Options', 'Main', $APP_DEFAULT_TOGGLE_HOTKEY)
        IniWrite($iniFile, 'Hotkeys', '^#l', '[HkzExe]Turn Off Monitors And Lock')
        IniWrite($iniFile, 'Hotkeys', '^+e', 'C:\Windows\System32\notepad.exe')
        IniWrite($iniFile, 'Hotkeys', '^+i', 'C:\Program Files (x86)\Internet Explorer\iexplore.exe[HkzParam]https://leomoon.com')
        IniWrite($iniFile, 'Hotkeys', '^!c', '::{20d04fe0-3aea-1069-a2d8-08002b30309d}')
        IniWrite($iniFile, 'Hotkeys', '^!u', '%USERPROFILE%')
        IniWrite($iniFile, 'Hotkeys', '^!p', '::{26EE0668-A00A-44D7-9371-BEB064C98683}')
        IniWrite($iniFile, 'Hotkeys', '^!{PGDN}', '[HkzWM]Minimize')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPADADD}', '[HkzWM]Transparency +')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPADSUB}', '[HkzWM]Transparency -')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD0}', '[HkzWM]Toggle On Top')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPADMULT}', '[HkzWM]Take Screenshot')
        IniWrite($iniFile, 'Hotkeys', '^!{UP}', '[HkzWM]Snap Fullscreen')
        IniWrite($iniFile, 'Hotkeys', '^!{LEFT}', '[HkzWM]Snap Left (2x1)')
        IniWrite($iniFile, 'Hotkeys', '^!{RIGHT}', '[HkzWM]Snap Right (2x1)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD7}', '[HkzWM]Snap Top Left (3x2)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD8}', '[HkzWM]Snap Top Mid (3x2)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD9}', '[HkzWM]Snap Top Right (3x2)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD4}', '[HkzWM]Snap Left (3x1)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD5}', '[HkzWM]Snap Mid (3x1)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD6}', '[HkzWM]Snap Right (3x1)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD1}', '[HkzWM]Snap Bottom Left (3x2)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD2}', '[HkzWM]Snap Bottom Mid (3x2)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD3}', '[HkzWM]Snap Bottom Right (3x2)')
        IniWrite($iniFile, 'Hotkeys', '!+{RIGHT}', '[HkzWM]Move to Next Monitor')
        IniWrite($iniFile, 'Hotkeys', '!+{LEFT}', '[HkzWM]Move to Previous Monitor')
        IniWrite($iniFile, 'Hotkeys', '^!0', '[HkzSndTxt]Today is <DAYNAME>[HkzNL]Current time is: <HOUR>:<MINUTE>:<SECOND>[HkzNL]Current date is <MONTHNUMBER>\<DAYNUMBER>\<YEAR>')
    EndIf
    ;double check
    If Not FileExists($iniFile) Then
        _AppError_Report($APP_TITLE & " was unable to write its settings file", 1, 0)
        Exit
    EndIf
EndFunc

Func _iniToApply($iniFile)
    Local $i, $aRecord
    $aHotkeys = _HotkeyRepository_Load($iniFile)
    If @error Then
        $aHotkeys = _HotkeyRepository_CreateTable(0)
        _AppError_Report("One or more hotkey entries are malformed or duplicated; no action hotkeys were registered", $HOTKEY_REPOSITORY_ERROR_INVALID, 0)
        Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, 0, False)
    EndIf
    If IsArray($aHotkeys) Then
        For $i = 1 To _HotkeyRepository_Count($aHotkeys)
            $aRecord = _HotkeyRepository_GetRecord($aHotkeys, $i)
            If Not _ActionValidator_ValidateRecord($aRecord, False) Then
                $aHotkeys = _HotkeyRepository_CreateTable(0)
                _AppError_Report("One or more action values are not allowed; no action hotkeys were registered", $HOTKEY_REPOSITORY_ERROR_INVALID, $i)
                Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $i, False)
            EndIf
            HotKeySet($aHotkeys[$i][$HOTKEY_FIELD_HOTKEY], "HotKeyPressed")
        Next
    Endif
EndFunc
