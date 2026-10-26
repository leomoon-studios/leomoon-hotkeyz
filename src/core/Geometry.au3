#include-once

; Work-area records always contain absolute virtual-desktop coordinates in this order:
; left, top, right, bottom. Right and bottom are exclusive edges.
Global Enum $WORK_AREA_LEFT = 0, _
            $WORK_AREA_TOP, _
            $WORK_AREA_RIGHT, _
            $WORK_AREA_BOTTOM, _
            $WORK_AREA_COUNT

Global Enum $WINDOW_RECT_X = 0, _
            $WINDOW_RECT_Y, _
            $WINDOW_RECT_WIDTH, _
            $WINDOW_RECT_HEIGHT, _
            $WINDOW_RECT_COUNT

Func _Geometry_CreateWorkArea($iLeft, $iTop, $iRight, $iBottom)
    If $iRight <= $iLeft Or $iBottom <= $iTop Then Return SetError(1, 0, 0)
    Local $aArea[$WORK_AREA_COUNT] = [$iLeft, $iTop, $iRight, $iBottom]
    Return $aArea
EndFunc

Func _Geometry_CreateRect($iX, $iY, $iWidth, $iHeight)
    If $iWidth <= 0 Or $iHeight <= 0 Then Return SetError(1, 0, 0)
    Local $aRect[$WINDOW_RECT_COUNT] = [$iX, $iY, $iWidth, $iHeight]
    Return $aRect
EndFunc

Func _Geometry_WorkWidth(ByRef $aArea)
    If Not _Geometry_IsWorkArea($aArea) Then Return SetError(1, 0, 0)
    Return $aArea[$WORK_AREA_RIGHT] - $aArea[$WORK_AREA_LEFT]
EndFunc

Func _Geometry_WorkHeight(ByRef $aArea)
    If Not _Geometry_IsWorkArea($aArea) Then Return SetError(1, 0, 0)
    Return $aArea[$WORK_AREA_BOTTOM] - $aArea[$WORK_AREA_TOP]
EndFunc

Func _Geometry_IsWorkArea(ByRef $aArea)
    Return IsArray($aArea) And UBound($aArea) = $WORK_AREA_COUNT And $aArea[$WORK_AREA_RIGHT] > $aArea[$WORK_AREA_LEFT] And $aArea[$WORK_AREA_BOTTOM] > $aArea[$WORK_AREA_TOP]
EndFunc

Func _Geometry_IsRect(ByRef $aRect)
    Return IsArray($aRect) And UBound($aRect) = $WINDOW_RECT_COUNT And $aRect[$WINDOW_RECT_WIDTH] > 0 And $aRect[$WINDOW_RECT_HEIGHT] > 0
EndFunc

Func _Geometry_GridRect(ByRef $aArea, $iColumn, $iColumns, $iRow, $iRows)
    If Not _Geometry_IsWorkArea($aArea) Or $iColumns < 1 Or $iRows < 1 Or $iColumn < 0 Or $iColumn >= $iColumns Or $iRow < 0 Or $iRow >= $iRows Then Return SetError(1, 0, 0)
    Local $iWidth = _Geometry_WorkWidth($aArea)
    Local $iHeight = _Geometry_WorkHeight($aArea)
    Local $iLeft = $aArea[$WORK_AREA_LEFT] + Floor($iWidth * $iColumn / $iColumns)
    Local $iTop = $aArea[$WORK_AREA_TOP] + Floor($iHeight * $iRow / $iRows)
    Local $iRight = $aArea[$WORK_AREA_LEFT] + Floor($iWidth * ($iColumn + 1) / $iColumns)
    Local $iBottom = $aArea[$WORK_AREA_TOP] + Floor($iHeight * ($iRow + 1) / $iRows)
    Return _Geometry_CreateRect($iLeft, $iTop, $iRight - $iLeft, $iBottom - $iTop)
EndFunc

Func _Geometry_CalculateActionRect($sAction, ByRef $aArea, ByRef $aCurrent)
    If Not _Geometry_IsWorkArea($aArea) Or Not _Geometry_IsRect($aCurrent) Then Return SetError(1, 0, 0)
    Local $iWidth = _Geometry_WorkWidth($aArea)
    Local $iHeight = _Geometry_WorkHeight($aArea)
    Switch $sAction
        Case "Move Center"
            Return _Geometry_CreateRect($aArea[$WORK_AREA_LEFT] + Floor(($iWidth - $aCurrent[$WINDOW_RECT_WIDTH]) / 2), $aArea[$WORK_AREA_TOP] + Floor(($iHeight - $aCurrent[$WINDOW_RECT_HEIGHT]) / 2), $aCurrent[$WINDOW_RECT_WIDTH], $aCurrent[$WINDOW_RECT_HEIGHT])
        Case "Move Top Left"
            Return _Geometry_CreateRect($aArea[$WORK_AREA_LEFT], $aArea[$WORK_AREA_TOP], $aCurrent[$WINDOW_RECT_WIDTH], $aCurrent[$WINDOW_RECT_HEIGHT])
        Case "Move Top Mid"
            Return _Geometry_CreateRect($aArea[$WORK_AREA_LEFT] + Floor(($iWidth - $aCurrent[$WINDOW_RECT_WIDTH]) / 2), $aArea[$WORK_AREA_TOP], $aCurrent[$WINDOW_RECT_WIDTH], $aCurrent[$WINDOW_RECT_HEIGHT])
        Case "Move Top Right"
            Return _Geometry_CreateRect($aArea[$WORK_AREA_RIGHT] - $aCurrent[$WINDOW_RECT_WIDTH], $aArea[$WORK_AREA_TOP], $aCurrent[$WINDOW_RECT_WIDTH], $aCurrent[$WINDOW_RECT_HEIGHT])
        Case "Move Bottom Left"
            Return _Geometry_CreateRect($aArea[$WORK_AREA_LEFT], $aArea[$WORK_AREA_BOTTOM] - $aCurrent[$WINDOW_RECT_HEIGHT], $aCurrent[$WINDOW_RECT_WIDTH], $aCurrent[$WINDOW_RECT_HEIGHT])
        Case "Move Bottom Mid"
            Return _Geometry_CreateRect($aArea[$WORK_AREA_LEFT] + Floor(($iWidth - $aCurrent[$WINDOW_RECT_WIDTH]) / 2), $aArea[$WORK_AREA_BOTTOM] - $aCurrent[$WINDOW_RECT_HEIGHT], $aCurrent[$WINDOW_RECT_WIDTH], $aCurrent[$WINDOW_RECT_HEIGHT])
        Case "Move Bottom Right"
            Return _Geometry_CreateRect($aArea[$WORK_AREA_RIGHT] - $aCurrent[$WINDOW_RECT_WIDTH], $aArea[$WORK_AREA_BOTTOM] - $aCurrent[$WINDOW_RECT_HEIGHT], $aCurrent[$WINDOW_RECT_WIDTH], $aCurrent[$WINDOW_RECT_HEIGHT])
        Case "Snap Fullscreen"
            Return _Geometry_GridRect($aArea, 0, 1, 0, 1)
        Case "Snap Top (1x2)"
            Return _Geometry_GridRect($aArea, 0, 1, 0, 2)
        Case "Snap Bottom (1x2)"
            Return _Geometry_GridRect($aArea, 0, 1, 1, 2)
        Case "Snap Left (2x1)"
            Return _Geometry_GridRect($aArea, 0, 2, 0, 1)
        Case "Snap Right (2x1)"
            Return _Geometry_GridRect($aArea, 1, 2, 0, 1)
        Case "Snap Left (3x1)"
            Return _Geometry_GridRect($aArea, 0, 3, 0, 1)
        Case "Snap Mid (3x1)"
            Return _Geometry_GridRect($aArea, 1, 3, 0, 1)
        Case "Snap Right (3x1)"
            Return _Geometry_GridRect($aArea, 2, 3, 0, 1)
        Case "Snap Top Left (2x2)"
            Return _Geometry_GridRect($aArea, 0, 2, 0, 2)
        Case "Snap Top Right (2x2)"
            Return _Geometry_GridRect($aArea, 1, 2, 0, 2)
        Case "Snap Bottom Left (2x2)"
            Return _Geometry_GridRect($aArea, 0, 2, 1, 2)
        Case "Snap Bottom Right (2x2)"
            Return _Geometry_GridRect($aArea, 1, 2, 1, 2)
        Case "Snap Top Left (3x2)"
            Return _Geometry_GridRect($aArea, 0, 3, 0, 2)
        Case "Snap Top Mid (3x2)"
            Return _Geometry_GridRect($aArea, 1, 3, 0, 2)
        Case "Snap Top Right (3x2)"
            Return _Geometry_GridRect($aArea, 2, 3, 0, 2)
        Case "Snap Bottom Left (3x2)"
            Return _Geometry_GridRect($aArea, 0, 3, 1, 2)
        Case "Snap Bottom Mid (3x2)"
            Return _Geometry_GridRect($aArea, 1, 3, 1, 2)
        Case "Snap Bottom Right (3x2)"
            Return _Geometry_GridRect($aArea, 2, 3, 1, 2)
    EndSwitch
    Return SetError(2, 0, 0)
EndFunc

Func _Geometry_MapRect(ByRef $aSourceArea, ByRef $aTargetArea, ByRef $aRect)
    If Not _Geometry_IsWorkArea($aSourceArea) Or Not _Geometry_IsWorkArea($aTargetArea) Or Not _Geometry_IsRect($aRect) Then Return SetError(1, 0, 0)
    Local $iSourceWidth = _Geometry_WorkWidth($aSourceArea)
    Local $iSourceHeight = _Geometry_WorkHeight($aSourceArea)
    Local $iTargetWidth = _Geometry_WorkWidth($aTargetArea)
    Local $iTargetHeight = _Geometry_WorkHeight($aTargetArea)
    Local $fX = ($aRect[$WINDOW_RECT_X] - $aSourceArea[$WORK_AREA_LEFT]) / $iSourceWidth
    Local $fY = ($aRect[$WINDOW_RECT_Y] - $aSourceArea[$WORK_AREA_TOP]) / $iSourceHeight
    Local $iWidth = Round($aRect[$WINDOW_RECT_WIDTH] * $iTargetWidth / $iSourceWidth)
    Local $iHeight = Round($aRect[$WINDOW_RECT_HEIGHT] * $iTargetHeight / $iSourceHeight)
    If $iWidth < 1 Then $iWidth = 1
    If $iHeight < 1 Then $iHeight = 1
    If $iWidth > $iTargetWidth Then $iWidth = $iTargetWidth
    If $iHeight > $iTargetHeight Then $iHeight = $iTargetHeight
    Local $iX = Round($aTargetArea[$WORK_AREA_LEFT] + ($fX * $iTargetWidth))
    Local $iY = Round($aTargetArea[$WORK_AREA_TOP] + ($fY * $iTargetHeight))
    If $iX < $aTargetArea[$WORK_AREA_LEFT] Then $iX = $aTargetArea[$WORK_AREA_LEFT]
    If $iY < $aTargetArea[$WORK_AREA_TOP] Then $iY = $aTargetArea[$WORK_AREA_TOP]
    If $iX + $iWidth > $aTargetArea[$WORK_AREA_RIGHT] Then $iX = $aTargetArea[$WORK_AREA_RIGHT] - $iWidth
    If $iY + $iHeight > $aTargetArea[$WORK_AREA_BOTTOM] Then $iY = $aTargetArea[$WORK_AREA_BOTTOM] - $iHeight
    Return _Geometry_CreateRect($iX, $iY, $iWidth, $iHeight)
EndFunc
