#include-once
#include "..\core\OpticalDriveModel.au3"

Global $g_sOpticalListHandler = "_OpticalDriveActions_NativeList"
Global $g_sOpticalTrayHandler = "_OpticalDriveActions_NativeTray"
Global Const $OPTICAL_ERROR_INVALID = 1, $OPTICAL_ERROR_MISSING = 2, $OPTICAL_ERROR_OPERATION = 3, $OPTICAL_ERROR_ENUMERATION = 4

Func _OpticalDriveActions_NativeList()
    Local $aDrives = DriveGetDrive("CDROM")
    ; AutoIt uses @error=1 when no optical drives exist; that is an empty list.
    If @error Then
        Local $aEmpty[1] = [0]
        Return $aEmpty
    EndIf
    Return $aDrives
EndFunc

Func _OpticalDriveActions_NativeTray($sDrive, $sOperation)
    Return CDTray($sDrive, $sOperation)
EndFunc

Func _OpticalDriveActions_List()
    Local $aDrives = Call($g_sOpticalListHandler)
    If @error Or Not IsArray($aDrives) Then Return SetError($OPTICAL_ERROR_ENUMERATION, 0, 0)
    If UBound($aDrives, 0) <> 1 Or UBound($aDrives) < 1 Then Return SetError($OPTICAL_ERROR_ENUMERATION, 0, 0)
    If $aDrives[0] <> UBound($aDrives) - 1 Then Return SetError($OPTICAL_ERROR_ENUMERATION, 0, 0)
    Local $i
    For $i = 1 To $aDrives[0]
        If Not _OpticalDriveModel_IsDrive($aDrives[$i]) Then Return SetError($OPTICAL_ERROR_ENUMERATION, $i, 0)
        $aDrives[$i] = StringUpper($aDrives[$i])
    Next
    Return $aDrives
EndFunc

Func _OpticalDriveActions_IsAvailable($sDrive)
    If Not _OpticalDriveModel_IsDrive($sDrive) Then Return SetError($OPTICAL_ERROR_INVALID, 0, False)
    Local $aDrives = _OpticalDriveActions_List()
    If @error Then Return SetError($OPTICAL_ERROR_ENUMERATION, 0, False)
    Local $i
    For $i = 1 To $aDrives[0]
        If $aDrives[$i] = $sDrive Then Return True
    Next
    Return SetError($OPTICAL_ERROR_MISSING, 0, False)
EndFunc

Func _OpticalDriveActions_Execute($sTarget)
    Local $sOperation = _OpticalDriveModel_Operation($sTarget)
    If $sOperation = "" Then Return SetError($OPTICAL_ERROR_INVALID, 0, False)
    Local $sDrive = StringUpper(StringRight($sTarget, 2))
    ; Check drive type, not media readiness: an empty or open tray is still valid.
    If Not _OpticalDriveActions_IsAvailable($sDrive) Then Return SetError(@error, 0, False)
    Local $iResult = Call($g_sOpticalTrayHandler, $sDrive, $sOperation)
    If @error Or $iResult <> 1 Then Return SetError($OPTICAL_ERROR_OPERATION, 0, False)
    ; Success acknowledges the request, not physical closure (laptop trays vary).
    Return True
EndFunc
