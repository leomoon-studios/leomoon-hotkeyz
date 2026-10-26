#include-once

#include "..\core\HotkeyRepository.au3"

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
    Return RegRead($APP_STARTUP_REGISTRY_KEY, $APP_TITLE) <> ""
EndFunc

Func _HotkeyRegistry_SetStartupEnabled($bEnabled)
    If $bEnabled Then Return RegWrite($APP_STARTUP_REGISTRY_KEY, $APP_TITLE, "REG_SZ", '"' & @ScriptFullPath & '"')
    RegDelete($APP_STARTUP_REGISTRY_KEY, $APP_TITLE)
    Return Not @error
EndFunc

Func HotKeyPressed()
    Local $x, $hkzoptadmin, $hkzoptone, $hkzcmd, $hkzaction, $moveresize, $move, $resize, $oldClip, $hkzparam, $hWnd
    For $x = 1 To _HotkeyRepository_Count($aHotkeys)
        If @HotKeyPressed == $aHotkeys[$x][$HOTKEY_FIELD_HOTKEY] Then
            _aTags()
            $hkzoptadmin = ''
            If BitAND($aHotkeys[$x][$HOTKEY_FIELD_OPTIONS], $HOTKEY_OPTION_ADMIN) Then $hkzoptadmin = 'runas'
            $hkzoptone = BitAND($aHotkeys[$x][$HOTKEY_FIELD_OPTIONS], $HOTKEY_OPTION_SINGLETON) <> 0
            $hkzaction = $aHotkeys[$x][$HOTKEY_FIELD_ACTION]
            $hkzcmd = _HotkeyCodec_ExpandTags($aHotkeys[$x][$HOTKEY_FIELD_TARGET], $aTags)
            $hkzparam = _HotkeyCodec_ExpandTags($aHotkeys[$x][$HOTKEY_FIELD_PARAMETERS], $aTags)
            If $hkzaction = $HOTKEY_ACTION_MEDIA Then ;execute special volume and media tasks
                _ProcessActions_ExecuteMedia($hkzcmd)
            ElseIf $hkzaction = $HOTKEY_ACTION_COMMAND Then ;run special dos commands
                _ProcessActions_ExecuteCommand($hkzcmd, $hkzoptadmin)
            ElseIf $hkzaction = $HOTKEY_ACTION_SYSTEM Then ;execute commands as is
                _SystemActions_Execute($hkzcmd)
            ElseIf $hkzaction = $HOTKEY_ACTION_WINDOW Then ;window manager
                ;parse cmd: x,y,width,height,center,opacity,top
                $hkzcmd = StringStripWS($hkzcmd, 7)
                $hWnd = WinGetHandle("[ACTIVE]")
                If _isReal($hWnd) Then ;if is a real window
                    ;pos, size
                    Local $anim = 1
                    Local $area = _getMonitorArea(_WinAPI_MonitorFromWindow($hWnd))
                    Local $areaWidth = _Max($area[0], $area[1]) - _Min($area[0], $area[1])
                    Local $areaHeight = _Max($area[2], $area[3]) - _Min($area[2], $area[3])
                    ;define
                    Select
                        Case (StringInStr($hkzcmd, 'Move to ') Or StringInStr($hkzcmd, 'Resize to ')) And Not StringInStr($hkzcmd, 'Monitor')
                            If StringInStr($hkzcmd, ' & ') Then
                                $moveresize = StringSplit(StringReplace(StringReplace($hkzcmd, 'Move to ', ''), 'Resize to ', ''), ' & ', 1)
                                $move = StringSplit($moveresize[1], ',')
                                $resize = StringSplit($moveresize[2], 'x')
                                If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                                _typeCheck($hWnd)
                                If IsArray($move) And $move[0] == 2 And IsArray($resize) And $resize[0] == 2 Then WinMove($hWnd, '', $move[1], $move[2], $resize[1]+$xf, $resize[2]+$yf, $anim)
                            ElseIf StringInStr($hkzcmd, ',') Then
                                $move = StringSplit(StringReplace($hkzcmd, 'Move to ', ''), ',')
                                If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                                _typeCheck($hWnd)
                                If IsArray($move) And $move[0] == 2 Then WinMove($hWnd, '', $move[1], $move[2], Default, Default, $anim)
                            ElseIf StringInStr($hkzcmd, 'x') Then
                                $resize = StringSplit(StringReplace($hkzcmd, 'Resize to ', ''), 'x')
                                If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                                _typeCheck($hWnd)
                                If IsArray($resize) And $resize[0] == 2 Then WinMove($hWnd, '', Default, Default, $resize[1]+$xf, $resize[2]+$yf, $anim)
                            EndIf
                        Case $hkzcmd == 'Move to Next Monitor'
                            _moveToMonitor($hWnd, _monitors(), True)
                        Case $hkzcmd == 'Move to Previous Monitor'
                            _moveToMonitor($hWnd, _monitors(), False)
                        Case $hkzcmd == 'Move Center'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', (($area[0]+($areaWidth/2))-($wpos[2]/2)), ((($areaHeight/2)+$area[2])-($wpos[3]/2)+($yf/2)), Default, Default, $anim)
                        Case $hkzcmd == 'Move Top Left'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2], Default, Default, $anim)
                        Case $hkzcmd == 'Move Top Mid'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', (($areaWidth/2)+$area[0])-($wpos[2]/2), $area[2], Default, Default, $anim)
                        Case $hkzcmd == 'Move Top Right'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[1]-$wpos[2]+($xf/2), $area[2], Default, Default, $anim)
                        Case $hkzcmd == 'Move Bottom Left'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), ($area[2]+$areaHeight)-$wpos[3]+($yf), Default, Default, $anim)
                        Case $hkzcmd == 'Move Bottom Mid'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', (($areaWidth/2)+$area[0])-($wpos[2]/2), ($area[2]+$areaHeight)-$wpos[3]+($yf), Default, Default, $anim)
                        Case $hkzcmd == 'Move Bottom Right'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[1]-$wpos[2]+($xf/2), ($area[2]+$areaHeight)-$wpos[3]+($yf), Default, Default, $anim)
                        Case $hkzcmd == 'Snap Fullscreen'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2], $areaWidth+$xf, $areaHeight+$yf, $anim)
                        Case $hkzcmd == 'Snap Top (1x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2], $areaWidth+$xf, ($areaHeight/2)+$yf, $anim)
                        Case $hkzcmd == 'Snap Bottom (1x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2]+($areaHeight/2), $areaWidth+$xf, ($areaHeight/2)+$yf, $anim)
                        Case $hkzcmd == 'Snap Left (2x1)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2], ($areaWidth/2)+$xf, $areaHeight+$yf, $anim)
                        Case $hkzcmd == 'Snap Right (2x1)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', ($area[0]+($areaWidth/2))-($xf/2), $area[2], ($areaWidth/2)+$xf, $areaHeight+$yf, $anim)
                        Case $hkzcmd == 'Snap Left (3x1)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2], ($areaWidth/3)+$xf, $areaHeight+$yf, $anim)
                        Case $hkzcmd == 'Snap Mid (3x1)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', Default, Default, ($areaWidth/3)+$xf, $areaHeight+$yf, $anim)
                            $wpos = WinGetPos($hWnd)
                            WinMove($hWnd, '', (($areaWidth/2)+$area[0])-($wpos[2]/2), $area[2], Default, Default, $anim)
                        Case $hkzcmd == 'Snap Right (3x1)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', Default, Default, ($areaWidth/3)+$xf, $areaHeight+$yf, $anim)
                            $wpos = WinGetPos($hWnd)
                            WinMove($hWnd, '', $area[1]-$wpos[2]+($xf/2), $area[2], Default, Default, $anim)
                        Case $hkzcmd == 'Snap Top Left (2x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2], ($areaWidth/2)+$xf, ($areaHeight/2)+$yf, $anim)
                        Case $hkzcmd == 'Snap Top Right (2x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', ($area[0]+($areaWidth/2))-($xf/2), $area[2], ($areaWidth/2)+$xf, ($areaHeight/2)+$yf, $anim)
                        Case $hkzcmd == 'Snap Bottom Left (2x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2]+($areaHeight/2), ($areaWidth/2)+$xf, ($areaHeight/2)+$yf, $anim)
                        Case $hkzcmd == 'Snap Bottom Right (2x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', ($area[0]+($areaWidth/2))-($xf/2), $area[2]+($areaHeight/2), ($areaWidth/2)+$xf, ($areaHeight/2)+$yf, $anim)
                        Case $hkzcmd == 'Snap Top Left (3x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2], ($areaWidth/3)+$xf, ($areaHeight/2)+$yf, $anim)
                        Case $hkzcmd == 'Snap Top Mid (3x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', Default, Default, ($areaWidth/3)+$xf, ($areaHeight/2)+$yf, $anim)
                            $wpos = WinGetPos($hWnd)
                            WinMove($hWnd, '', (($areaWidth/2)+$area[0])-($wpos[2]/2), $area[2], Default, Default, $anim)
                        Case $hkzcmd == 'Snap Top Right (3x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', Default, Default, ($areaWidth/3)+$xf, ($areaHeight/2)+$yf, $anim)
                            $wpos = WinGetPos($hWnd)
                            WinMove($hWnd, '', $area[1]-$wpos[2]+($xf/2), $area[2], Default, Default, $anim)
                        Case $hkzcmd == 'Snap Bottom Left (3x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', Default, Default, ($areaWidth/3)+$xf, ($areaHeight/2)+$yf, $anim)
                            $wpos = WinGetPos($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), ($area[2]+$areaHeight)-$wpos[3]+($yf), Default, Default, $anim)
                        Case $hkzcmd == 'Snap Bottom Mid (3x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', Default, Default, ($areaWidth/3)+$xf, ($areaHeight/2)+$yf, $anim)
                            $wpos = WinGetPos($hWnd)
                            WinMove($hWnd, '', (($areaWidth/2)+$area[0])-($wpos[2]/2), ($area[2]+$areaHeight)-$wpos[3]+($yf), Default, Default, $anim)
                        Case $hkzcmd == 'Snap Bottom Right (3x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', Default, Default, ($areaWidth/3)+$xf, ($areaHeight/2)+$yf, $anim)
                            $wpos = WinGetPos($hWnd)
                            WinMove($hWnd, '', $area[1]-$wpos[2]+($xf/2), ($area[2]+$areaHeight)-$wpos[3]+($yf), Default, Default, $anim)
                        Case $hkzcmd == 'Set Process Priority to Low'
                            _setPriority($hWnd, 0)
                        Case $hkzcmd == 'Set Process Priority to Below Normal'
                            _setPriority($hWnd, 1)
                        Case $hkzcmd == 'Set Process Priority to Normal'
                            _setPriority($hWnd, 2)
                        Case $hkzcmd == 'Set Process Priority to Above Normal'
                            _setPriority($hWnd, 3)
                        Case $hkzcmd == 'Set Process Priority to Hight'
                            _setPriority($hWnd, 4)
                        Case $hkzcmd == 'Set Process Priority to Realtime'
                            _setPriority($hWnd, 5)
                        Case $hkzcmd == 'Close'
                            WinClose($hWnd)
                        Case $hkzcmd == 'Minimize'
                            WinSetState($hWnd, '', @SW_MINIMIZE)
                        Case $hkzcmd == 'Terminate'
                            WinKill($hWnd)
                        Case $hkzcmd == 'Transparency +'
                            _transPlus($hWnd)
                        Case $hkzcmd == 'Transparency -'
                            _transMinus($hWnd)
                        Case $hkzcmd == 'Toggle On Top'
                            _topToggle($hWnd)
                        Case $hkzcmd == 'Take Screenshot'
                            _shot($hWnd)
                        Case $hkzcmd == 'Toggle Ghost (Advanced)'
                            _ghostToggle($hWnd)
                        Case $hkzcmd == 'Resize 3x2'
                            If BitAND(WinGetState(WinGetHandle($hWnd)), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            ;flooring to eliminate .33
                            WinMove($hWnd, '', Default, Default, Floor(($areaWidth/3)+$xf), Floor(($areaHeight/2)+$yf), $anim)
                        Case $hkzcmd == 'Hide'
                            WinSetState($hWnd, '', @SW_HIDE)
                        Case $hkzcmd == 'Generate Random Password (Letters)'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            ClipPut(_generator('<RAND_LETTERS>'))
                            Send('^v')
                            ClipPut($oldClip)
                        Case $hkzcmd == 'Generate Random Password (Numbers)'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            ClipPut(_generator('<RAND_NUMBERS>'))
                            Send('^v')
                            ClipPut($oldClip)
                        Case $hkzcmd == 'Generate Random Password (Letters and Numbers)'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            ClipPut(_generator('<RAND_LETTERS_NUMBERS>'))
                            Send('^v')
                            ClipPut($oldClip)
                        Case $hkzcmd == 'Generate Random Password (PPP)'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            ClipPut(_generator('<RAND_PPP>'))
                            Send('^v')
                            ClipPut($oldClip)
                        Case $hkzcmd == 'Generate Random UUID'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            ClipPut(uuid())
                            Send('^v')
                            ClipPut($oldClip)
                        Case $hkzcmd == 'Upper Case Selected Text'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            Send('^c')
                            ClipPut(StringUpper(ClipGet()))
                            Send('^v')
                            ClipPut($oldClip)
                        Case $hkzcmd == 'Lower Case Selected Text'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            Send('^c')
                            ClipPut(StringLower(ClipGet()))
                            Send('^v')
                            ClipPut($oldClip)
                        Case $hkzcmd == 'Title Case Selected Text'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            Send('^c')
                            ClipPut(_StringTitleCase(ClipGet()))
                            Send('^v')
                            ClipPut($oldClip)
                        Case $hkzcmd == 'Reverse Selected Text'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            Send('^c')
                            ClipPut(StringReverse(ClipGet()))
                            Send('^v')
                            ClipPut($oldClip)
                        Case $hkzcmd == 'MD5 Selected Text'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            Send('^c')
                            ClipPut(StringLower(StringTrimLeft(_Crypt_HashData(ClipGet(), $CALG_MD5), 2)))
                            Send('^v')
                            ClipPut($oldClip)
                        Case $hkzcmd == 'SHA1 Selected Text'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            Send('^c')
                            ClipPut(StringLower(StringTrimLeft(_Crypt_HashData(ClipGet(), $CALG_SHA1), 2)))
                            Send('^v')
                            ClipPut($oldClip)
                        Case $hkzcmd == 'SHA-256 Selected Text'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            Send('^c')
                            ClipPut(StringLower(StringTrimLeft(_Crypt_HashData(ClipGet(), $CALG_SHA_256), 2)))
                            Send('^v')
                            ClipPut($oldClip)
                        Case $hkzcmd == 'SHA-512 Selected Text'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            Send('^c')
                            ClipPut(StringLower(StringTrimLeft(_Crypt_HashData(ClipGet(), $CALG_SHA_512), 2)))
                            Send('^v')
                            ClipPut($oldClip)
                        Case $hkzcmd == 'Base64 Encode Selected Text'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            Send('^c')
                            ClipPut(_Base64Encode(ClipGet()))
                            Send('^v')
                            ClipPut($oldClip)
                        Case $hkzcmd == 'Base64 Decode Selected Text'
                            ;~ ConsoleWrite($hkzcmd)
                            $oldClip = ClipGet()
                            Send('^c')
                            ClipPut(_Base64Decode(ClipGet()))
                            Send('^v')
                            ClipPut($oldClip)
                    EndSelect
                    ;~ WinActivate($hWnd)
                EndIf
            ElseIf $hkzaction = $HOTKEY_ACTION_TEXT Then ;paste text to active window
                _TextActions_Paste($hkzcmd)
            Else ;execute program or file
                _ProcessActions_ExecuteTarget($hkzcmd, $hkzparam, $hkzoptadmin, $hkzoptone)
            EndIf
        EndIf
    Next
EndFunc

Func _isKnownSpecialAction($sAction, $sTarget)
    Local $i, $aSpecialRecord
    For $i = 0 To UBound($sPaths, 1) - 1
        $aSpecialRecord = _HotkeyCodec_DecodeLegacy("^!a", StringReplace($sPaths[$i][1], ' [Parameters] ', $HOTKEY_CODEC_PARAMETER), _HotkeyRepository_ClassifyPlainValue($sPaths[$i][1]))
        If IsArray($aSpecialRecord) And $aSpecialRecord[$HOTKEY_FIELD_ACTION] = $sAction And $aSpecialRecord[$HOTKEY_FIELD_TARGET] = $sTarget Then Return True
    Next
    Return False
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
        _ExtMsgBox(48, 'OK', 'Oops!', $APP_TITLE&' was unable to write settings file at this location:'&@CRLF&'"'&@ScriptDir&'"'&@CRLF, 0)
        Exit
    EndIf
EndFunc

Func _iniToApply($iniFile)
    Local $i
    $aHotkeys = _HotkeyRepository_Load($iniFile)
    If @error Then
        $aHotkeys = _HotkeyRepository_CreateTable(0)
        _ExtMsgBox(48, 'OK', 'Invalid hotkey settings', 'One or more hotkey entries are malformed or duplicated. No action hotkeys were registered.', 0)
        Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, 0, False)
    EndIf
    If IsArray($aHotkeys) Then
        For $i = 1 To _HotkeyRepository_Count($aHotkeys)
            HotKeySet($aHotkeys[$i][$HOTKEY_FIELD_HOTKEY], "HotKeyPressed")
        Next
    Endif
EndFunc
