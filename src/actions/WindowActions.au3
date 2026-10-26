#include-once

#include <Math.au3>
#include <Crypt.au3>
#include <Process.au3>
#include <ScreenCapture.au3>
#include <WinAPIGdi.au3>
#include <WinAPISys.au3>
#include <WinAPISysWin.au3>
#include <WindowsConstants.au3>

Global $wpos[3]
Global $xf = 0
Global $yf = 0
Global Const $WINDOW_ACTION_NAMES = "|Close|Minimize|Terminate|Transparency +|Transparency -|Toggle On Top|Take Screenshot|Set Process Priority to Low|Set Process Priority to Below Normal|Set Process Priority to Normal|Set Process Priority to Above Normal|Set Process Priority to Hight|Set Process Priority to Realtime|Move Center|Move Top Left|Move Top Mid|Move Top Right|Move Bottom Left|Move Bottom Mid|Move Bottom Right|Move to Next Monitor|Move to Previous Monitor|Snap Fullscreen|Snap Top (1x2)|Snap Bottom (1x2)|Snap Left (2x1)|Snap Right (2x1)|Snap Left (3x1)|Snap Mid (3x1)|Snap Right (3x1)|Snap Top Left (2x2)|Snap Top Right (2x2)|Snap Bottom Left (2x2)|Snap Bottom Right (2x2)|Snap Top Left (3x2)|Snap Top Mid (3x2)|Snap Top Right (3x2)|Snap Bottom Left (3x2)|Snap Bottom Mid (3x2)|Snap Bottom Right (3x2)|Toggle Ghost (Advanced)|Generate Random Password (PPP)|Generate Random Password (Letters)|Generate Random Password (Numbers)|Generate Random Password (Letters and Numbers)|Generate Random UUID|Upper Case Selected Text|Lower Case Selected Text|Title Case Selected Text|Reverse Selected Text|MD5 Selected Text|SHA1 Selected Text|SHA-256 Selected Text|SHA-512 Selected Text|Base64 Encode Selected Text|Base64 Decode Selected Text|"

Func _WindowActions_IsValid($sAction)
    If StringInStr($WINDOW_ACTION_NAMES, "|" & $sAction & "|", 1) Then Return True
    Return StringRegExp($sAction, "^(?:Move to -?\d+,-?\d+(?: & Resize to [1-9]\d*x[1-9]\d*)?|Resize to [1-9]\d*x[1-9]\d*)$") = 1
EndFunc

Func _shot($hWnd)
    WinActivate($hWnd)
    ;~ $hWnd = WinGetHandle("[ACTIVE]")
    Local Const $sMessage = "Choose a filename."
    Local $sFileSaveDialog = FileSaveDialog($sMessage, "::{450D8FBA-AD25-11D0-98A8-0800361B1103}", "Image as JPG (*.jpg)", $FD_PATHMUSTEXIST)
    If @error Then Return SetError(1)
    Local $sFileName = StringTrimLeft($sFileSaveDialog, StringInStr($sFileSaveDialog, "\", $STR_NOCASESENSEBASIC, -1))
    Local $iExtension = StringInStr($sFileName, ".", $STR_NOCASESENSEBASIC)
    If $iExtension Then
        If Not (StringTrimLeft($sFileName, $iExtension - 1) = ".jpg") Then $sFileSaveDialog &= ".jpg"
    Else
        $sFileSaveDialog &= ".jpg"
    EndIf
    ;~ Sleep(500)
    Local $img = _ScreenCapture_CaptureWnd('', $hWnd)
    _ScreenCapture_SaveImage($sFileSaveDialog, $img)
EndFunc

Func _WinGetTrans($hWnd, ByRef $Transparency, $asColorRef = False)
    Local $i_transcolor = -1
    $Transparency = -1
    Local $aResult = DllCall("user32.dll", "bool", "GetLayeredWindowAttributes", "hwnd", $hWnd, "dword*", $i_transcolor, "byte*", $Transparency, "dword*", 0)
    If @error Then Return SetError(@error, @extended, 0)
    If Not $asColorRef Then
        $aResult[2] = Int(BinaryMid($aResult[2], 3, 1) & BinaryMid($aResult[2], 2, 1) & BinaryMid($aResult[2], 1, 1))
    EndIf
    $i_transcolor = $aResult[2]
    $Transparency = $aResult[3]
    Return $aResult[4]
EndFunc

Func _transPlus($hWnd)
    Local $o = 17 ;0 to 255
    Local $iTransparency
    _WinGetTrans($hWnd, $iTransparency)
    If Not @error Then
        If $iTransparency > $o Then
            WinSetTrans($hWnd, '', $iTransparency-$o)
        Else
            WinSetTrans($hWnd, '', 0)
        EndIf
    EndIf
EndFunc

Func _transMinus($hWnd)
    Local $o = 17 ;0 to 255
    Local $iTransparency
    _WinGetTrans($hWnd, $iTransparency)
    If Not @error Then
        If $iTransparency + $o > 255 Then
            WinSetTrans($hWnd, '', 255)
        Else
            WinSetTrans($hWnd, '', $iTransparency+$o)
        EndIf
    EndIf
EndFunc

Func _ghostToggle($hWnd)
    If BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE), $WS_EX_TRANSPARENT) Then
        _WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE), BitNOT($WS_EX_TRANSPARENT)))
    Else
        _WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, BitOR(_WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE), $WS_EX_TRANSPARENT))
    EndIf
EndFunc

Func _typeCheck($hWnd)
    Local $csiz
    $wpos = WinGetPos($hWnd)
    $csiz = WinGetClientSize($hWnd)
    ;~ ConsoleWrite($csiz[0]&' '&$wpos[2]&@LF)
    ;~ ConsoleWrite($csiz[1]&' '&$wpos[3]&@LF)
    If @OSVersion == 'WIN_10' Then
        If $csiz[0] <> $wpos[2] And $wpos[2] - $csiz[0] > 15 And @OSVersion == 'WIN_10' Then
            $xf = 14
            $yf = 7
        Else
            $xf = 0
            $yf = 0
        EndIf
    Else
        $xf = 0
        $yf = 0
    EndIf
EndFunc

Func _isReal($hWnd)
    Local $vWinStyle = _WinAPI_GetWindowLong($hWnd, $GWL_STYLE)
    If BitAND(WinGetState($hWnd), 4) = 4 _
        And WinGetTitle($hWnd) <> '' _
        And WinGetTitle($hWnd) <> 'Snap Assist' _
        And BitAND($vWinStyle, $WS_VISIBLE) = $WS_VISIBLE _
        And BitAND($vWinStyle, $WS_MINIMIZE) <> $WS_MINIMIZE Then Return True
    ;~ If BitAND(WinGetState($hWnd), 4) = 4 _
    ;~     And BitAND($vWinStyle, $WS_VISIBLE) = $WS_VISIBLE _
    ;~     And BitAND($vWinStyle, $WS_MINIMIZE) <> $WS_MINIMIZE _
    ;~     And BitAND($vWinStyle, $WS_MINIMIZEBOX) = $WS_MINIMIZEBOX _
    ;~     And BitAND($vWinStyle, $WS_MAXIMIZEBOX) = $WS_MAXIMIZEBOX Then Return True
EndFunc

Func _topToggle($hWnd)
    If BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE), $WS_EX_TOPMOST) Then
        WinSetOnTop($hWnd, '', $WINDOWS_NOONTOP)
    Else
        WinSetOnTop($hWnd, '', $WINDOWS_ONTOP)
    EndIf
EndFunc

Func _setPriority($hWnd, $priority=2)
    ProcessSetPriority(_ProcessGetName(WinGetProcess($hWnd, "")), $priority)
EndFunc

Func _GetWindowsExplorerPath($hWnd)
    Local $i, $oShellApp_Inst
    If Not IsHWnd($hWnd) Then Return SetError(1)
    Local $aWinList = WinList("[REGEXPCLASS:(Explore|Cabinet)WClass]")
    While 1
        For $i = 1 To UBound($aWinList) - 1
            If $hWnd == $aWinList[$i][1] Then ExitLoop 2
        Next
        Return SetError(2)
    WEnd
    Local $oShellApp = ObjCreate("Shell.Application")
    If Not IsObj($oShellApp) Then Return SetError(3)
    Local $oShellApp_Windows = $oShellApp.Windows()
    If Not IsObj($oShellApp_Windows) Then Return SetError(4)
    For $oShellApp_Inst In $oShellApp_Windows
        If $oShellApp_Inst.hwnd = $hWnd Then ExitLoop
    Next
    Local $sShellApp_Inst_LocationURL = $oShellApp_Inst.LocationURL
    Local $aRet = DllCall('shlwapi.dll', 'long', 'PathCreateFromUrlW', 'wstr', $sShellApp_Inst_LocationURL, 'wstr', '', 'dword*', 65534, 'dword', 0)
    If Not @error And $aRet[0] == 0 Then $sShellApp_Inst_LocationURL = $aRet[2]
    $oShellApp = 0
    $oShellApp_Windows = 0
    $oShellApp_Inst = 0
    Return $sShellApp_Inst_LocationURL
EndFunc

Func _monitors()
    Local $aPos, $aData = _WinAPI_EnumDisplayMonitors()
    Local $i, $j
    If IsArray($aData) Then
        ReDim $aData[$aData[0][0] + 1][5]
        For $i = 1 To $aData[0][0]
            $aPos = _WinAPI_GetPosFromRect($aData[$i][1])
            For $j = 0 To 3
                $aData[$i][$j + 1] = $aPos[$j]
            Next
        Next
        Return $aData
    EndIf
EndFunc

Func _moveToMonitor($hWnd, $monitors, $dir = False)
    Local $i, $n
    ;~ For $i = 1 To $monitors[0][0]
    ;~     ConsoleWrite($monitors[$i][0]&': X='&$monitors[$i][1]&' Y='&$monitors[$i][2]&' W='&$monitors[$i][3]&' H='&$monitors[$i][4]&@LF)
    ;~ Next
    For $i = 1 To $monitors[0][0]
        If _WinAPI_MonitorFromWindow($hWnd, $MONITOR_DEFAULTTONEAREST) == $monitors[$i][0] Then
            ExitLoop
        EndIf
    Next
    Local $pos = WinGetPos($hWnd)
    If $dir Then ;right
        If $i >= $monitors[0][0] Then
            $n = 1
        Else
            $n = $i + 1
        EndIf
    Else
        If $i <= 1 Then
            $n = $monitors[0][0]
        Else
            $n = $i - 1
        EndIf
    EndIf
    ;get old monitor's area
    Local $oArea = _getMonitorArea($monitors[$i][0])
    Local $oAreaWidth = _Max($oArea[0], $oArea[1]) - _Min($oArea[0], $oArea[1])
    Local $oAreaHeight = _Max($oArea[2], $oArea[3]) - _Min($oArea[2], $oArea[3])
    ;get new monitor's area
    Local $area = _getMonitorArea($monitors[$n][0])
    Local $areaWidth = _Max($area[0], $area[1]) - _Min($area[0], $area[1])
    Local $areaHeight = _Max($area[2], $area[3]) - _Min($area[2], $area[3])
    ;main vars
    Local $oxVal = $pos[0] - $monitors[$i][1]
    Local $oyVal = $pos[1] - $monitors[$i][2]
    Local $wWin = $pos[2]
    Local $hWin = $pos[3]
    _typeCheck($hWnd)
    ;calculate the new range
    Local $xMul = $areaWidth/$oAreaWidth
    Local $yMul = $areaHeight/$oAreaHeight
    Local $nxVal = ((($oxVal - 0) * ($monitors[$n][3] - 0)) / ($monitors[$i][3] - 0) + 0)/$xMul
    Local $nyVal = ((($oyVal - 0) * ($monitors[$n][4] - 0)) / ($monitors[$i][4] - 0) + 0)/$yMul
    ;check if window was fullscreened by Windows
    If BitAND(WinGetState($hWnd), 32) Then
        $wWin = $areaWidth
        $hWin = $areaHeight
    EndIf
    ;check if prev window height and width was 100% so we can fullscreen it in the next monitor
    If $wWin - $xf == $oAreaWidth And $hWin - $yf == $oAreaHeight Then ;check for fullscreen
        $wWin = $areaWidth + $xf
        $hWin = $areaHeight + $yf
        $nxVal = -($xf/2)
    EndIf
    ;check if prev window height or width was 100%
    If $wWin - $xf == $oAreaWidth Then $wWin = $areaWidth + $xf
    If $hWin - $yf == $oAreaHeight Then $hWin = $areaHeight + $yf
    ;check if window is still bigger than the next monitor
    If $wWin - $xf > $areaWidth Then $wWin = $areaWidth + $xf
    If $hWin - $yf > $areaHeight Then $hWin = $areaHeight + $yf
    ;check if window can fit by shriking the positiong values
    If $nxVal + ($wWin - $xf) >= $areaWidth Then $nxVal = ($areaWidth - $wWin + $xf)-($xf/2)
    If $nyVal + ($hWin - $yf) >= $areaHeight Then $nyVal = ($areaHeight - $hWin + $yf)
    ;check if window was touching right and bottom edges of previous monitor
    If $wWin + $oxVal - ($xf/2) == $oAreaWidth Then $nxVal = $areaWidth - ($wWin - ($xf/2))
    If $hWin + $oyVal - ($yf) == $oAreaHeight Then $nyVal = $areaHeight - ($hWin - ($yf))
    ;check if prev window was split in half on x
    If _almostEqual(($oAreaWidth/2), ($pos[2]-$xf), 0, 1) Then $wWin = ($areaWidth/2)+$xf
    ;check if prev window was split in half on y
    If _almostEqual(($oAreaHeight/2), ($pos[3]-$yf), 0, 1) Then $hWin = ($areaHeight/2)+$yf
    ;check if prev window was split in thirds
    If _almostEqual(($oAreaWidth/3), ($pos[2]-$xf), 0 ,1) Then $wWin = ($areaWidth/3)+$xf
    ;check if window was centered on x
    If _almostEqual(($oArea[0]+($oAreaWidth/2)), ($pos[0]+($pos[2]/2)), 0, 1) Then $nxVal = ($areaWidth/2) - ($wWin/2)
    ;check if window was centered on y
    If _almostEqual(($oArea[2]+($oAreaHeight/2)), (($pos[1]+($pos[3]/2))-($yf/2)), 0, 1) Then $nyVal = (($areaHeight/2) - ($hWin/2)) + ($yf/2)
    ;if half window is at x right
    If _almostEqual(($pos[0]-$monitors[$i][1])+($xf/2), ($oAreaWidth/2), 0, 1) Then $nxVal = ($areaWidth/2)-($xf/2)
    ;if half window is at y btm
    If _almostEqual($pos[1]-$monitors[$i][2], ($oAreaHeight/2), 0, 1) Then $nyVal = ($areaHeight/2)
    ;if third window is at third x mid
    If _almostEqual((($pos[0]-$monitors[$i][1])+($xf/2)), ($oAreaWidth/3), 0, 1) Then $nxVal = ($areaWidth/2)-($wWin/2)
    ;if third window is at third x right
    If _almostEqual(($pos[0]-$monitors[$i][1])+($xf/2), ($oAreaWidth/3)*2, 0, 1) Then $nxVal = Ceiling((($areaWidth/3)*2)-($xf/2))
    ;resize only if the window is resizable
    If _isResizable($hWnd) Then
        WinMove($hWnd, '', ($monitors[$n][1] + $nxVal), ($monitors[$n][2] + $nyVal), ($wWin), ($hWin))
    Else
        WinMove($hWnd, '', ($monitors[$n][1] + $nxVal), ($monitors[$n][2] + $nyVal))
    EndIf
EndFunc

Func _almostEqual($a, $b, $min, $max)
    Local $val = $a - $b
    If Abs($val) <= $max And Abs($val) >= $min Then Return True
EndFunc

Func _isResizable($hWnd)
    If BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_STYLE), $WS_SIZEBOX) Or _
    BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_STYLE), $WS_THICKFRAME) Or _
    BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_STYLE), $WS_MAXIMIZEBOX) Then Return True
    ;~ If BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_STYLE), $WS_MAXIMIZEBOX) Then Return True
EndFunc

Func _getMonitorArea($monitor)
    Local $monitorInfo = _WinAPI_GetMonitorInfo($monitor)
    Local $area[] = [DllStructGetData($monitorInfo[1], 1), DllStructGetData($monitorInfo[1], 3), DllStructGetData($monitorInfo[1], 2), DllStructGetData($monitorInfo[1], 4)]
    If @error Then
        Return
    EndIf
    Return $area
EndFunc

Func _WindowActions_Execute($hkzcmd)
    Local $moveresize, $move, $resize, $oldClip, $hWnd
    ;parse cmd: x,y,width,height,center,opacity,top
    $hkzcmd = StringStripWS($hkzcmd, 7)
    $hWnd = WinGetHandle("[ACTIVE]")
    If Not _isReal($hWnd) Then Return SetError(1, 0, False)
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
    Return True
EndFunc
