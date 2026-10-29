#include-once

Global Const $OPTICAL_ACTION_OPEN = "Open optical drive tray"
Global Const $OPTICAL_ACTION_CLOSE = "Close optical drive tray"
Global Const $OPTICAL_ACTION_TOGGLE = "Open/close optical drive tray"

Func _OpticalDriveModel_IsDrive($sDrive)
    Return StringRegExp($sDrive, "^[A-Za-z]:\z") = 1
EndFunc

Func _OpticalDriveModel_Operation($sTarget)
    If Not StringRegExp($sTarget, "^(Open|Close|Open/close) optical drive tray [A-Za-z]:\z") Then Return ""
    If StringLeft($sTarget, 5) = "Open " Then Return "open"
    If StringLeft($sTarget, 11) = "Open/close " Then Return "toggle"
    Return "closed"
EndFunc

Func _OpticalDriveModel_Target($sAction, $sDrive)
    If ($sAction <> $OPTICAL_ACTION_OPEN And $sAction <> $OPTICAL_ACTION_CLOSE And $sAction <> $OPTICAL_ACTION_TOGGLE) Or Not _OpticalDriveModel_IsDrive($sDrive) Then Return SetError(1, 0, "")
    Return $sAction & " " & StringUpper($sDrive)
EndFunc
