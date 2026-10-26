#include-once

#include <FileConstants.au3>
#include <ScreenCapture.au3>
#include <WinAPIGdi.au3>
#include <WinAPISys.au3>
#include <WinAPISysWin.au3>
#include <WindowsConstants.au3>
#include "..\core\Geometry.au3"
#include "..\core\ActionCatalog.au3"
#include "TextActions.au3"
#include "ClipboardTransaction.au3"

Global $g_iWindowActionsComError = 0
Global $g_sMonitorEnumHandler = "_WinAPI_EnumDisplayMonitors"
Global $g_sMonitorInfoHandler = "_WinAPI_GetMonitorInfo"
Global $g_sComCreateHandler = "_WindowActions_ObjCreate"
Global $g_sLayeredAttributesHandler = "_WindowActions_GetLayeredAttributes"
Global $g_sPathFromUrlHandler = "_WindowActions_PathFromUrl"

Func _WindowActions_ConfigureBackends($sMonitorEnum, $sMonitorInfo, $sComCreate, $sLayeredAttributes, $sPathFromUrl)
    $g_sMonitorEnumHandler = $sMonitorEnum
    $g_sMonitorInfoHandler = $sMonitorInfo
    $g_sComCreateHandler = $sComCreate
    $g_sLayeredAttributesHandler = $sLayeredAttributes
    $g_sPathFromUrlHandler = $sPathFromUrl
EndFunc

Func _WindowActions_ResetBackends()
    _WindowActions_ConfigureBackends("_WinAPI_EnumDisplayMonitors", "_WinAPI_GetMonitorInfo", "_WindowActions_ObjCreate", "_WindowActions_GetLayeredAttributes", "_WindowActions_PathFromUrl")
EndFunc

Func _WindowActions_ObjCreate($sProgramId)
    Return ObjCreate($sProgramId)
EndFunc

Func _WindowActions_CreateComObject($sProgramId)
    Return Call($g_sComCreateHandler, $sProgramId)
EndFunc

Func _WindowActions_GetLayeredAttributes($hWnd, $iColor, $iTransparency)
    Return DllCall("user32.dll", "bool", "GetLayeredWindowAttributes", "hwnd", $hWnd, "dword*", $iColor, "byte*", $iTransparency, "dword*", 0)
EndFunc

Func _WindowActions_PathFromUrl($sUrl)
    Return DllCall("shlwapi.dll", "long", "PathCreateFromUrlW", "wstr", $sUrl, "wstr", "", "dword*", 65534, "dword", 0)
EndFunc

Func _WindowActions_IsValid($sAction)
    If _ActionCatalog_IsWindowAction($sAction) Then Return True
    Return StringRegExp($sAction, "^(?:Move to -?\d+,-?\d+(?: & Resize to [1-9]\d*x[1-9]\d*)?|Resize to [1-9]\d*x[1-9]\d*)$") = 1
EndFunc

Func _WindowActions_NormalizeScreenshotPath($sPath)
    If $sPath = "" Then Return SetError(1, 0, "")
    If Not StringRegExp($sPath, "(?i)\.jpg$") Then $sPath &= ".jpg"
    Return $sPath
EndFunc

Func _WindowActions_SaveScreenshot($sPath, $hWnd, $sCaptureHandler = "_ScreenCapture_CaptureWnd", $sSaveHandler = "_ScreenCapture_SaveImage")
    $sPath = _WindowActions_NormalizeScreenshotPath($sPath)
    If @error Then Return SetError(1, 0, False)
    Local $hImage = Call($sCaptureHandler, "", $hWnd)
    If @error Or Not $hImage Then Return SetError(2, @error, False)
    Local $bSaved = Call($sSaveHandler, $sPath, $hImage)
    If @error Or Not $bSaved Then Return SetError(3, @error, False)
    Return True
EndFunc

Func _shot($hWnd)
    If Not WinActivate($hWnd) Then Return SetError(1, 0, False)
    Local $sPath = FileSaveDialog("Choose a filename.", "::{450D8FBA-AD25-11D0-98A8-0800361B1103}", "Image as JPG (*.jpg)", $FD_PATHMUSTEXIST)
    If @error Or $sPath = "" Then Return SetError(2, @error, False)
    Return _WindowActions_SaveScreenshot($sPath, $hWnd)
EndFunc

Func _WinGetTrans($hWnd, ByRef $iTransparency, $bAsColorRef = False)
    Local $iColor = -1
    $iTransparency = -1
    Local $iStyle = _WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE)
    If @error Then Return SetError(1, @error, 0)
    ; Ordinary windows have no layered attributes yet and start fully opaque.
    If Not BitAND($iStyle, $WS_EX_LAYERED) Then
        $iTransparency = 255
        Return $LWA_ALPHA
    EndIf
    Local $aResult = Call($g_sLayeredAttributesHandler, $hWnd, $iColor, $iTransparency)
    If @error Or Not IsArray($aResult) Or Not $aResult[0] Then Return SetError(1, @error, 0)
    If Not $bAsColorRef Then $aResult[2] = Int(BinaryMid($aResult[2], 3, 1) & BinaryMid($aResult[2], 2, 1) & BinaryMid($aResult[2], 1, 1))
    $iTransparency = 255
    If BitAND($aResult[4], $LWA_ALPHA) Then $iTransparency = $aResult[3]
    Return $aResult[4]
EndFunc

Func _transPlus($hWnd)
    Local $iTransparency
    _WinGetTrans($hWnd, $iTransparency)
    If @error Then Return SetError(1, @error, False)
    If $iTransparency > 17 Then Return WinSetTrans($hWnd, "", $iTransparency - 17) <> 0
    Return WinSetTrans($hWnd, "", 0) <> 0
EndFunc

Func _transMinus($hWnd)
    Local $iTransparency
    _WinGetTrans($hWnd, $iTransparency)
    If @error Then Return SetError(1, @error, False)
    If $iTransparency + 17 > 255 Then Return WinSetTrans($hWnd, "", 255) <> 0
    Return WinSetTrans($hWnd, "", $iTransparency + 17) <> 0
EndFunc

Func _ghostToggle($hWnd)
    Local $iStyle = _WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE)
    If @error Then Return SetError(1, @error, False)
    If BitAND($iStyle, $WS_EX_TRANSPARENT) Then
        _WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, BitAND($iStyle, BitNOT($WS_EX_TRANSPARENT)))
    Else
        _WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, BitOR($iStyle, $WS_EX_TRANSPARENT))
    EndIf
    Return Not @error
EndFunc

Func _isReal($hWnd)
    If Not IsHWnd($hWnd) Then Return False
    Local $iStyle = _WinAPI_GetWindowLong($hWnd, $GWL_STYLE)
    Return BitAND(WinGetState($hWnd), 4) = 4 And WinGetTitle($hWnd) <> "" And WinGetTitle($hWnd) <> "Snap Assist" And BitAND($iStyle, $WS_VISIBLE) = $WS_VISIBLE And BitAND($iStyle, $WS_MINIMIZE) <> $WS_MINIMIZE
EndFunc

Func _topToggle($hWnd)
    Local $iStyle = _WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE)
    If @error Then Return SetError(1, @error, False)
    If BitAND($iStyle, $WS_EX_TOPMOST) Then Return WinSetOnTop($hWnd, "", $WINDOWS_NOONTOP) <> 0
    Return WinSetOnTop($hWnd, "", $WINDOWS_ONTOP) <> 0
EndFunc

Func _setPriority($hWnd, $iPriority = 2)
    Local $iPid = WinGetProcess($hWnd, "")
    If @error Or $iPid = -1 Then Return SetError(1, @error, False)
    If Not ProcessSetPriority($iPid, $iPriority) Then Return SetError(2, @error, False)
    Return True
EndFunc

Func _GetWindowsExplorerPath($hWnd)
    If Not IsHWnd($hWnd) Then Return SetError(1, 0, "")
    Local $aWindows = WinList("[REGEXPCLASS:(Explore|Cabinet)WClass]")
    If @error Or Not IsArray($aWindows) Then Return SetError(2, @error, "")
    Local $bFound = False, $i
    For $i = 1 To UBound($aWindows) - 1
        If $hWnd = $aWindows[$i][1] Then
            $bFound = True
            ExitLoop
        EndIf
    Next
    If Not $bFound Then Return SetError(3, 0, "")
    Local $oShell = _WindowActions_CreateComObject("Shell.Application")
    If Not IsObj($oShell) Then Return SetError(4, 0, "")
    $g_iWindowActionsComError = 0
    Local $oComError = ObjEvent("AutoIt.Error", "_WindowActions_ComError")
    If Not IsObj($oComError) Then Return SetError(5, 0, "")
    Local $oWindows = $oShell.Windows()
    If $g_iWindowActionsComError Or Not IsObj($oWindows) Then
        $oComError = 0
        Return SetError(6, $g_iWindowActionsComError, "")
    EndIf
    Local $oWindow, $sUrl = ""
    For $oWindow In $oWindows
        If $oWindow.hwnd = $hWnd Then
            $sUrl = $oWindow.LocationURL
            ExitLoop
        EndIf
    Next
    $oComError = 0
    If $g_iWindowActionsComError Or $sUrl = "" Then Return SetError(7, $g_iWindowActionsComError, "")
    Local $aResult = Call($g_sPathFromUrlHandler, $sUrl)
    If @error Or Not IsArray($aResult) Or $aResult[0] <> 0 Then Return SetError(8, @error, "")
    Return $aResult[2]
EndFunc

Func _WindowActions_ComError($oError)
    $g_iWindowActionsComError = $oError.number
EndFunc

Func _getMonitorArea($hMonitor)
    If Not $hMonitor Then Return SetError(1, 0, 0)
    Local $aInfo = Call($g_sMonitorInfoHandler, $hMonitor)
    If @error Or Not IsArray($aInfo) Or Not IsDllStruct($aInfo[1]) Then Return SetError(2, @error, 0)
    Local $aArea = _Geometry_CreateWorkArea(DllStructGetData($aInfo[1], 1), DllStructGetData($aInfo[1], 2), DllStructGetData($aInfo[1], 3), DllStructGetData($aInfo[1], 4))
    If @error Then Return SetError(3, 0, 0)
    Return $aArea
EndFunc

Func _monitors()
    Local $aDisplay = Call($g_sMonitorEnumHandler)
    If @error Or Not IsArray($aDisplay) Or $aDisplay[0][0] < 1 Then Return SetError(1, @error, 0)
    Local $aMonitors[$aDisplay[0][0] + 1][5]
    $aMonitors[0][0] = $aDisplay[0][0]
    Local $i, $aArea
    For $i = 1 To $aDisplay[0][0]
        $aArea = _getMonitorArea($aDisplay[$i][0])
        If @error Then Return SetError(2, $i, 0)
        $aMonitors[$i][0] = $aDisplay[$i][0]
        $aMonitors[$i][1] = $aArea[$WORK_AREA_LEFT]
        $aMonitors[$i][2] = $aArea[$WORK_AREA_TOP]
        $aMonitors[$i][3] = $aArea[$WORK_AREA_RIGHT]
        $aMonitors[$i][4] = $aArea[$WORK_AREA_BOTTOM]
    Next
    Return $aMonitors
EndFunc

Func _WindowActions_GetRect($hWnd)
    Local $aPosition = WinGetPos($hWnd)
    If @error Or Not IsArray($aPosition) Or UBound($aPosition) < 4 Then Return SetError(1, @error, 0)
    Return _Geometry_CreateRect($aPosition[0], $aPosition[1], $aPosition[2], $aPosition[3])
EndFunc

Func _WindowActions_ApplyRect($hWnd, ByRef $aRect)
    If Not _Geometry_IsRect($aRect) Then Return SetError(1, 0, False)
    If BitAND(WinGetState($hWnd), 32) And Not WinSetState($hWnd, "", @SW_RESTORE) Then Return SetError(2, 0, False)
    If Not WinMove($hWnd, "", $aRect[$WINDOW_RECT_X], $aRect[$WINDOW_RECT_Y], $aRect[$WINDOW_RECT_WIDTH], $aRect[$WINDOW_RECT_HEIGHT], 1) Then Return SetError(3, @error, False)
    Return True
EndFunc

Func _moveToMonitor($hWnd, ByRef $aMonitors, $bNext = False)
    If Not IsArray($aMonitors) Or $aMonitors[0][0] < 1 Then Return SetError(1, 0, False)
    Local $hCurrent = _WinAPI_MonitorFromWindow($hWnd, $MONITOR_DEFAULTTONEAREST)
    If @error Or Not $hCurrent Then Return SetError(2, @error, False)
    Local $i, $iTarget
    For $i = 1 To $aMonitors[0][0]
        If $aMonitors[$i][0] = $hCurrent Then ExitLoop
    Next
    If $i > $aMonitors[0][0] Then Return SetError(3, 0, False)
    If $bNext Then
        $iTarget = $i + 1
        If $iTarget > $aMonitors[0][0] Then $iTarget = 1
    Else
        $iTarget = $i - 1
        If $iTarget < 1 Then $iTarget = $aMonitors[0][0]
    EndIf
    Local $aSource = _Geometry_CreateWorkArea($aMonitors[$i][1], $aMonitors[$i][2], $aMonitors[$i][3], $aMonitors[$i][4])
    Local $aTarget = _Geometry_CreateWorkArea($aMonitors[$iTarget][1], $aMonitors[$iTarget][2], $aMonitors[$iTarget][3], $aMonitors[$iTarget][4])
    Local $aRect = _WindowActions_GetRect($hWnd)
    If @error Then Return SetError(4, @error, False)
    Local $aMapped = _Geometry_MapRect($aSource, $aTarget, $aRect)
    If @error Then Return SetError(5, @error, False)
    Return _WindowActions_ApplyRect($hWnd, $aMapped)
EndFunc

Func _almostEqual($a, $b, $iMin, $iMax)
    Local $iDifference = Abs($a - $b)
    Return $iDifference <= $iMax And $iDifference >= $iMin
EndFunc

Func _WindowActions_CustomGeometry($hWnd, $sAction)
    Local $aCurrent = _WindowActions_GetRect($hWnd)
    If @error Then Return SetError(1, @error, False)
    Local $aMatch = StringRegExp($sAction, "^Move to (-?\d+),(-?\d+)(?: & Resize to ([1-9]\d*)x([1-9]\d*))?$", 1)
    If IsArray($aMatch) Then
        $aCurrent[$WINDOW_RECT_X] = Number($aMatch[0])
        $aCurrent[$WINDOW_RECT_Y] = Number($aMatch[1])
        If UBound($aMatch) = 4 Then
            $aCurrent[$WINDOW_RECT_WIDTH] = Number($aMatch[2])
            $aCurrent[$WINDOW_RECT_HEIGHT] = Number($aMatch[3])
        EndIf
        Return _WindowActions_ApplyRect($hWnd, $aCurrent)
    EndIf
    $aMatch = StringRegExp($sAction, "^Resize to ([1-9]\d*)x([1-9]\d*)$", 1)
    If Not IsArray($aMatch) Then Return SetError(2, 0, False)
    $aCurrent[$WINDOW_RECT_WIDTH] = Number($aMatch[0])
    $aCurrent[$WINDOW_RECT_HEIGHT] = Number($aMatch[1])
    Return _WindowActions_ApplyRect($hWnd, $aCurrent)
EndFunc

Func _WindowActions_PasteGenerated($sToken)
    Local $sGenerated = _generator($sToken)
    If @error Then Return SetError(1, @error, False)
    Return _ClipboardTransaction_Paste($sGenerated)
EndFunc

Func _WindowActions_PasteUuid()
    Local $sUuid = uuid()
    If @error Then Return SetError(1, @error, False)
    Return _ClipboardTransaction_Paste($sUuid)
EndFunc

Func _WindowActions_Execute($sAction)
    $sAction = StringStripWS($sAction, 7)
    If Not _WindowActions_IsValid($sAction) Then Return SetError(1, 0, False)
    Local $hWnd = WinGetHandle("[ACTIVE]")
    ; As in v1.8.12, ignore repeats that land on the desktop or another ineligible
    ; target after the previous foreground window has been minimized or closed.
    If Not _isReal($hWnd) Then Return True
    If StringRegExp($sAction, "^(?:Move to -?\d+,-?\d+|Resize to )") Then Return _WindowActions_CustomGeometry($hWnd, $sAction)
    If $sAction = "Move to Next Monitor" Or $sAction = "Move to Previous Monitor" Then
        Local $aMonitors = _monitors()
        If @error Then Return SetError(3, @error, False)
        Return _moveToMonitor($hWnd, $aMonitors, $sAction = "Move to Next Monitor")
    EndIf
    If StringLeft($sAction, 5) = "Move " Or StringLeft($sAction, 5) = "Snap " Or $sAction = "Resize 3x2" Then
        ; Legacy resize preserves the restored window's position, not its maximized position.
        If $sAction = "Resize 3x2" And BitAND(WinGetState($hWnd), 32) Then
            If Not WinSetState($hWnd, "", @SW_RESTORE) Then Return SetError(4, 0, False)
        EndIf
        Local $aCurrent = _WindowActions_GetRect($hWnd)
        If @error Then Return SetError(4, @error, False)
        Local $hMonitor = _WinAPI_MonitorFromWindow($hWnd, $MONITOR_DEFAULTTONEAREST)
        If @error Or Not $hMonitor Then Return SetError(5, @error, False)
        Local $aArea = _getMonitorArea($hMonitor)
        If @error Then Return SetError(6, @error, False)
        Local $aCalculated = _Geometry_CalculateActionRect($sAction, $aArea, $aCurrent)
        If @error Then Return SetError(7, @error, False)
        If $sAction = "Resize 3x2" And @OSVersion = "WIN_10" Then
            ; Preserve v1.8.12's allowance for the invisible Windows frame borders.
            Local $aClient = WinGetClientSize($hWnd)
            If @error Or Not IsArray($aClient) Then Return SetError(7, @error, False)
            If $aCurrent[$WINDOW_RECT_WIDTH] - $aClient[0] > 15 Then
                $aCalculated[$WINDOW_RECT_WIDTH] += 14
                $aCalculated[$WINDOW_RECT_HEIGHT] += 7
            EndIf
        EndIf
        Return _WindowActions_ApplyRect($hWnd, $aCalculated)
    EndIf
    Switch $sAction
        Case "Set Process Priority to Low"
            Return _setPriority($hWnd, 0)
        Case "Set Process Priority to Below Normal"
            Return _setPriority($hWnd, 1)
        Case "Set Process Priority to Normal"
            Return _setPriority($hWnd, 2)
        Case "Set Process Priority to Above Normal"
            Return _setPriority($hWnd, 3)
        Case "Set Process Priority to High", $ACTION_CATALOG_LEGACY_HIGH
            Return _setPriority($hWnd, 4)
        Case "Set Process Priority to Realtime"
            Return _setPriority($hWnd, 5)
        Case "Close"
            Return WinClose($hWnd) <> 0
        Case "Minimize"
            Return WinSetState($hWnd, "", @SW_MINIMIZE) <> 0
        Case "Hide"
            Return WinSetState($hWnd, "", @SW_HIDE) <> 0
        Case "Terminate"
            Return WinKill($hWnd) <> 0
        Case "Transparency +"
            Return _transPlus($hWnd)
        Case "Transparency -"
            Return _transMinus($hWnd)
        Case "Toggle On Top"
            Return _topToggle($hWnd)
        Case "Take Screenshot"
            Return _shot($hWnd)
        Case "Toggle Ghost (Advanced)"
            Return _ghostToggle($hWnd)
        Case "Generate Random Password (Letters)"
            Return _WindowActions_PasteGenerated("<RAND_LETTERS>")
        Case "Generate Random Password (Numbers)"
            Return _WindowActions_PasteGenerated("<RAND_NUMBERS>")
        Case "Generate Random Password (Letters and Numbers)"
            Return _WindowActions_PasteGenerated("<RAND_LETTERS_NUMBERS>")
        Case "Generate Random Password (PPP)"
            Return _WindowActions_PasteGenerated("<RAND_PPP>")
        Case "Generate Random UUID"
            Return _WindowActions_PasteUuid()
        Case "Upper Case Selected Text", "Lower Case Selected Text", "Title Case Selected Text", "Reverse Selected Text", "MD5 Selected Text", "SHA1 Selected Text", "SHA-256 Selected Text", "SHA-512 Selected Text", "Base64 Encode Selected Text", "Base64 Decode Selected Text"
            Return _ClipboardTransaction_TransformSelection($sAction)
    EndSwitch
    Return SetError(8, 0, False)
EndFunc
