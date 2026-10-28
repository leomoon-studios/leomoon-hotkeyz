#include-once

#include "..\core\HotkeyRepository.au3"
#include "..\actions\ActionDispatcher.au3"
#include "ErrorReporter.au3"

Global $aHotkeys = _HotkeyRepository_CreateTable(0)
Global $g_sHotkeySetHandler = "_HotkeyRegistry_SetBinding"
Global $g_sRegistryReadHandler = "_HotkeyRegistry_RegRead"
Global $g_sRegistryWriteHandler = "_HotkeyRegistry_RegWrite"
Global $g_sRegistryDeleteHandler = "_HotkeyRegistry_RegDelete"

Func _HotkeyRegistry_ConfigureHotkeyBackend($sHandler)
    $g_sHotkeySetHandler = $sHandler
EndFunc

Func _HotkeyRegistry_ResetHotkeyBackend()
    $g_sHotkeySetHandler = "_HotkeyRegistry_SetBinding"
EndFunc

Func _HotkeyRegistry_ConfigureRegistryBackend($sReadHandler, $sWriteHandler, $sDeleteHandler)
    $g_sRegistryReadHandler = $sReadHandler
    $g_sRegistryWriteHandler = $sWriteHandler
    $g_sRegistryDeleteHandler = $sDeleteHandler
EndFunc

Func _HotkeyRegistry_ResetRegistryBackend()
    _HotkeyRegistry_ConfigureRegistryBackend("_HotkeyRegistry_RegRead", "_HotkeyRegistry_RegWrite", "_HotkeyRegistry_RegDelete")
EndFunc

Func _HotkeyRegistry_RegRead($sKey, $sValue)
    Local $vResult = RegRead($sKey, $sValue)
    Return SetError(@error, @extended, $vResult)
EndFunc

Func _HotkeyRegistry_RegWrite($sKey, $sValue, $sType, $sData)
    Local $iResult = RegWrite($sKey, $sValue, $sType, $sData)
    Return SetError(@error, @extended, $iResult)
EndFunc

Func _HotkeyRegistry_RegDelete($sKey, $sValue)
    Local $iResult = RegDelete($sKey, $sValue)
    Return SetError(@error, @extended, $iResult)
EndFunc

Func _HotkeyRegistry_SetBinding($sHotkey, $sHandler = "")
    $sHotkey = _HotkeyCodec_ToNativeHotkey($sHotkey)
    If $sHandler = "" Then Return HotKeySet($sHotkey)
    Return HotKeySet($sHotkey, $sHandler)
EndFunc

Func _HotkeyRegistry_TrySet($sHotkey, $sHandler = "")
    Local $vResult = Call($g_sHotkeySetHandler, $sHotkey, $sHandler)
    If @error Or Not $vResult Then Return SetError(1, @error, False)
    Return True
EndFunc

Func _HotkeyRegistry_SetTable(ByRef $aRecords, $sHandler)
    Local $i
    For $i = 1 To _HotkeyRepository_Count($aRecords)
        If Not _HotkeyRegistry_TrySet($aRecords[$i][$HOTKEY_FIELD_HOTKEY], $sHandler) Then Return SetError(1, $i, False)
    Next
    Return True
EndFunc

Func _HotkeyRegistry_ClearTable(ByRef $aRecords)
    Local $bSuccess = True, $i
    For $i = 1 To _HotkeyRepository_Count($aRecords)
        If Not _HotkeyRegistry_TrySet($aRecords[$i][$HOTKEY_FIELD_HOTKEY]) Then $bSuccess = False
    Next
    Return $bSuccess
EndFunc

Func _HotkeyRegistry_ApplyBindings($sOldToggle, ByRef $aOldRecords, $sNewToggle, ByRef $aNewRecords)
    ; HotKeySet returns 0 when removing an already unregistered shortcut (for example,
    ; while disabled or after a startup conflict). Still release every old binding.
    If $sOldToggle <> "" Then _HotkeyRegistry_TrySet($sOldToggle)
    _HotkeyRegistry_ClearTable($aOldRecords)
    If Not _HotkeyRegistry_TrySet($sNewToggle, "_toggle") Then
        _HotkeyRegistry_RestoreBindings($sOldToggle, $aOldRecords)
        Return SetError(3, 0, False)
    EndIf
    If Not _HotkeyRegistry_SetTable($aNewRecords, "HotKeyPressed") Then
        Local $iFailedRow = @extended
        _HotkeyRegistry_TrySet($sNewToggle)
        _HotkeyRegistry_ClearTable($aNewRecords)
        _HotkeyRegistry_RestoreBindings($sOldToggle, $aOldRecords)
        Return SetError(4, $iFailedRow, False)
    EndIf
    Return True
EndFunc

Func _HotkeyRegistry_RestoreBindings($sToggle, ByRef $aRecords)
    Local $bSuccess = True, $i
    If $sToggle <> "" And Not _HotkeyRegistry_TrySet($sToggle, "_toggle") Then $bSuccess = False
    ; A conflict on one old shortcut must not prevent restoring the others.
    For $i = 1 To _HotkeyRepository_Count($aRecords)
        If Not _HotkeyRegistry_TrySet($aRecords[$i][$HOTKEY_FIELD_HOTKEY], "HotKeyPressed") Then $bSuccess = False
    Next
    Return $bSuccess
EndFunc

Func _HotkeyRegistry_Initialize($sIniFile)
    _iniCheck($sIniFile)
    Return _iniToApply($sIniFile)
EndFunc

Func _HotkeyRegistry_Shutdown()
    Local $i
    For $i = 1 To _HotkeyRepository_Count($aHotkeys)
        If Not _HotkeyRegistry_TrySet($aHotkeys[$i][$HOTKEY_FIELD_HOTKEY]) Then Return False
    Next
    Local $sToggleHotkey = IniRead($APP_INI_PATH, "Options", "Main", "")
    If $sToggleHotkey <> "" And Not _HotkeyRegistry_TrySet($sToggleHotkey) Then Return False
    Return True
EndFunc

Func _HotkeyRegistry_IsStartupEnabled()
    Local $sValue = Call($g_sRegistryReadHandler, $APP_STARTUP_REGISTRY_KEY, $APP_TITLE)
    If @error Then Return False
    Return $sValue <> ""
EndFunc

Func _HotkeyRegistry_SetStartupEnabled($bEnabled)
    If $bEnabled Then
        Local $iWriteResult = Call($g_sRegistryWriteHandler, $APP_STARTUP_REGISTRY_KEY, $APP_TITLE, "REG_SZ", '"' & @ScriptFullPath & '"')
        If @error Or $iWriteResult <> 1 Then Return SetError(1, @error, False)
        Return True
    EndIf
    Call($g_sRegistryReadHandler, $APP_STARTUP_REGISTRY_KEY, $APP_TITLE)
    Local $iReadError = @error
    ; An absent value already satisfies an unchecked startup setting.
    If $iReadError = -1 Then Return True
    If $iReadError <> 0 And $iReadError <> 1 Then Return SetError(2, $iReadError, False)
    ; RegDelete returns 0 when already absent, 1 when deleted, and 2 on failure.
    Local $iDeleteResult = Call($g_sRegistryDeleteHandler, $APP_STARTUP_REGISTRY_KEY, $APP_TITLE)
    If @error Or ($iDeleteResult <> 0 And $iDeleteResult <> 1) Then Return SetError(2, @error, False)
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
    Local $sNormalized = _HotkeyCodec_NormalizeHotkey($sHotkey)
    Local $i
    For $i = 1 To _HotkeyRepository_Count($aHotkeys)
        If _HotkeyCodec_NormalizeHotkey($aHotkeys[$i][$HOTKEY_FIELD_HOTKEY]) = $sNormalized Then Return $i
    Next
    Return SetError($HOTKEY_REGISTRY_ERROR_NOT_FOUND, 0, 0)
EndFunc

Func _HotkeyRegistry_ExecuteRecord(ByRef $aRecord, $bShowMessage = True)
    _aTags()
    If Not _ActionDispatcher_Dispatch($aRecord, $aTags) Then
        Local $iDispatchError = @error
        Local $sMessage = "The hotkey action could not be completed."
        If $iDispatchError = $ACTION_DISPATCH_ERROR_TARGET_NOT_FOUND Then $sMessage = "The target file or folder does not exist. Update this hotkey's path in Settings."
        If _HotkeyModel_IsValid($aRecord) Then
            $sMessage &= @CRLF & @CRLF & "Hotkey: " & _HotkeyCodec_DecodeHotkey($aRecord[$HOTKEY_FIELD_HOTKEY])
            $sMessage &= @CRLF & "Target: " & _HotkeyCodec_ExpandTags($aRecord[$HOTKEY_FIELD_TARGET], $aTags)
        EndIf
        _AppError_Report($sMessage, $HOTKEY_REGISTRY_ERROR_DISPATCH, $iDispatchError, $bShowMessage)
        Return SetError($HOTKEY_REGISTRY_ERROR_DISPATCH, $iDispatchError, False)
    EndIf
    Return True
EndFunc


Func _iniCheck($iniFile)
    If Not FileExists($iniFile) Then
        IniWrite($iniFile, 'Options', 'Main', $APP_DEFAULT_TOGGLE_HOTKEY)
        IniWrite($iniFile, 'Hotkeys', '^!l', '[HkzExe]Turn Off Monitors And Lock')
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
    Local $i, $aRecord, $iRegistered = 0, $sUnavailable = ""
    Local $aConfiguredHotkeys = _HotkeyRepository_Load($iniFile)
    If @error Then
        $aHotkeys = _HotkeyRepository_CreateTable(0)
        _AppError_Report("One or more hotkey entries are malformed or duplicated; no action hotkeys were registered", $HOTKEY_REPOSITORY_ERROR_INVALID, 0)
        Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, 0, False)
    EndIf
    If IsArray($aConfiguredHotkeys) Then
        Local $sToggleHotkey = _HotkeyCodec_NormalizeHotkey(IniRead($iniFile, "Options", "Main", ""))
        For $i = 1 To _HotkeyRepository_Count($aConfiguredHotkeys)
            $aRecord = _HotkeyRepository_GetRecord($aConfiguredHotkeys, $i)
            ; Fail closed until the side/condition-aware input backend exists.
            If _HotkeyModel_HasRestrictions($aRecord) Then
                _AppError_Report("This profile contains restricted hotkeys that this build cannot safely apply", $HOTKEY_REPOSITORY_ERROR_INVALID, $i)
                Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $i, False)
            EndIf
            If Not _ActionValidator_ValidateRecord($aRecord, False) Then
                $aHotkeys = _HotkeyRepository_CreateTable(0)
                _AppError_Report("One or more action values are not allowed; no action hotkeys were registered", $HOTKEY_REPOSITORY_ERROR_INVALID, $i)
                Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $i, False)
            EndIf
            If $sToggleHotkey = _HotkeyCodec_NormalizeHotkey($aConfiguredHotkeys[$i][$HOTKEY_FIELD_HOTKEY]) Then
                _AppError_Report("The main toggle hotkey conflicts with an action hotkey", $HOTKEY_REPOSITORY_ERROR_DUPLICATE, $i)
                Return SetError($HOTKEY_REPOSITORY_ERROR_DUPLICATE, $i, False)
            EndIf
        Next
        $aHotkeys = _HotkeyRepository_CreateTable(_HotkeyRepository_Count($aConfiguredHotkeys))
        For $i = 1 To _HotkeyRepository_Count($aConfiguredHotkeys)
            $aRecord = _HotkeyRepository_GetRecord($aConfiguredHotkeys, $i)
            If _HotkeyRegistry_TrySet($aRecord[$HOTKEY_FIELD_HOTKEY], "HotKeyPressed") Then
                $iRegistered += 1
                _HotkeyRepository_SetRecord($aHotkeys, $iRegistered, $aRecord)
            Else
                $sUnavailable &= "- " & _HotkeyCodec_DecodeHotkey($aRecord[$HOTKEY_FIELD_HOTKEY]) & @CRLF
            EndIf
        Next
        ReDim $aHotkeys[$iRegistered + 1][$HOTKEY_FIELD_COUNT]
        $aHotkeys[0][$HOTKEY_FIELD_HOTKEY] = $iRegistered
        If $sUnavailable <> "" Then _AppWarning_Report("These hotkeys are already in use and could not be registered:" & @CRLF & @CRLF & $sUnavailable & @CRLF & "LeoMoon HotKeyz is still running. You can change or remove these hotkeys in Settings.")
    Endif
    Return True
EndFunc
