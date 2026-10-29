#include-once
#include "..\core\OpticalDriveModel.au3"

Global $g_sOpticalListHandler = "_OpticalDriveActions_NativeList"
Global $g_sOpticalTrayHandler = "_OpticalDriveActions_NativeTray"
Global $g_sOpticalStateHandler = "_OpticalDriveActions_NativeState"
Global Const $OPTICAL_ERROR_STATE = 5

Func _OpticalDriveActions_NativeState($sDrive)
    If Not _OpticalDriveModel_IsDrive($sDrive) Then Return SetError(1, 0, "")
    ; MCI reports "open" for some empty but physically closed Blu-ray drives.
    ; MMC GET EVENT STATUS NOTIFICATION reports the physical door bit instead.
    Local $aHandle = DllCall("kernel32.dll", "handle", "CreateFileW", "wstr", "\\.\" & $sDrive, "dword", 0xC0000000, "dword", 3, "ptr", 0, "dword", 3, "dword", 0, "handle", 0)
    If @error Or Not IsArray($aHandle) Then Return SetError(1, 0, "")
    If $aHandle[0] = Ptr(-1) Then Return SetError(1, 0, "")
    Local $tData = DllStructCreate("byte data[8]")
    Local $tPass = DllStructCreate("struct;ushort Length;byte ScsiStatus;byte PathId;byte TargetId;byte Lun;byte CdbLength;byte SenseInfoLength;byte DataIn;ulong DataTransferLength;ulong TimeOutValue;ptr DataBuffer;ulong SenseInfoOffset;byte Cdb[16];endstruct;byte Sense[32]")
    Local $iSenseOffset = DllStructGetPtr($tPass, "Sense") - DllStructGetPtr($tPass)
    DllStructSetData($tPass, "Length", $iSenseOffset)
    DllStructSetData($tPass, "SenseInfoOffset", $iSenseOffset)
    DllStructSetData($tPass, "SenseInfoLength", 32)
    DllStructSetData($tPass, "CdbLength", 10)
    DllStructSetData($tPass, "DataIn", 1)
    DllStructSetData($tPass, "DataTransferLength", 8)
    DllStructSetData($tPass, "TimeOutValue", 5)
    DllStructSetData($tPass, "DataBuffer", DllStructGetPtr($tData))
    DllStructSetData($tPass, "Cdb", 0x4A, 1) ; GET EVENT STATUS NOTIFICATION
    DllStructSetData($tPass, "Cdb", 1, 2) ; immediate response
    DllStructSetData($tPass, "Cdb", 0x10, 5) ; media event class
    DllStructSetData($tPass, "Cdb", 8, 9)
    Local $aResult = DllCall("kernel32.dll", "bool", "DeviceIoControl", "handle", $aHandle[0], "dword", 0x4D014, "ptr", DllStructGetPtr($tPass), "dword", DllStructGetSize($tPass), "ptr", DllStructGetPtr($tPass), "dword", DllStructGetSize($tPass), "dword*", 0, "ptr", 0)
    Local $iCallError = @error
    DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $aHandle[0])
    If $iCallError Or Not IsArray($aResult) Or Not $aResult[0] Or DllStructGetData($tPass, "ScsiStatus") <> 0 Then Return SetError(1, 0, "")
    Return _OpticalDriveActions_ParseState($tData)
EndFunc

Func _OpticalDriveActions_ParseState($tData)
    If Not IsDllStruct($tData) Or DllStructGetSize($tData) < 8 Then Return SetError(1, 0, "")
    Local $iLength = DllStructGetData($tData, "data", 1) * 256 + DllStructGetData($tData, "data", 2)
    Local $iClass = DllStructGetData($tData, "data", 3)
    If $iLength < 6 Or BitAND($iClass, 0x80) Or BitAND($iClass, 7) <> 4 Then Return SetError(1, 0, "")
    If BitAND(DllStructGetData($tData, "data", 6), 1) Then Return "open"
    Return "closed"
EndFunc
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
    If $sOperation = "toggle" Then
        Local $sState = Call($g_sOpticalStateHandler, $sDrive)
        If @error Or ($sState <> "open" And $sState <> "closed") Then Return SetError($OPTICAL_ERROR_STATE, 0, False)
        $sOperation = "open"
        If $sState = "open" Then $sOperation = "closed"
    EndIf
    Local $iResult = Call($g_sOpticalTrayHandler, $sDrive, $sOperation)
    If @error Or $iResult <> 1 Then Return SetError($OPTICAL_ERROR_OPERATION, 0, False)
    ; Success acknowledges the request, not physical closure (laptop trays vary).
    Return True
EndFunc
