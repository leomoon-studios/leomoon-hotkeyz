#include-once

Global Const $OPTICAL_ACTION_OPEN = "Open optical drive tray"
Global Const $OPTICAL_ACTION_CLOSE = "Close optical drive tray"

Func _OpticalDriveModel_IsDrive($sDrive)
    Return StringRegExp($sDrive, "^[A-Za-z]:\z") = 1
EndFunc

Func _OpticalDriveModel_Operation($sTarget)
    If Not StringRegExp($sTarget, "^(Open|Close) optical drive tray [A-Za-z]:\z") Then Return ""
    If StringLeft($sTarget, 5) = "Open " Then Return "open"
    Return "closed"
EndFunc

Func _OpticalDriveModel_Target($sAction, $sDrive)
    If ($sAction <> $OPTICAL_ACTION_OPEN And $sAction <> $OPTICAL_ACTION_CLOSE) Or Not _OpticalDriveModel_IsDrive($sDrive) Then Return SetError(1, 0, "")
    Return $sAction & " " & StringUpper($sDrive)
EndFunc
