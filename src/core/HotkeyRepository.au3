#include-once

#include <WinAPIFiles.au3>
#include "HotkeyCodec.au3"

Global Const $HOTKEY_REPOSITORY_ERROR_READ = 1
Global Const $HOTKEY_REPOSITORY_ERROR_INVALID = 2
Global Const $HOTKEY_REPOSITORY_ERROR_DUPLICATE = 3
Global Const $HOTKEY_REPOSITORY_ERROR_WRITE = 4
Global Const $HOTKEY_REPOSITORY_ERROR_VERIFY = 5
Global Const $HOTKEY_REPOSITORY_ERROR_REPLACE = 6

Func _HotkeyRepository_CreateTable($iCount)
    If Not IsInt($iCount) Or $iCount < 0 Then Return SetError(1, 0, 0)
    Local $aRecords[$iCount + 1][$HOTKEY_FIELD_COUNT]
    $aRecords[0][$HOTKEY_FIELD_HOTKEY] = $iCount
    Return $aRecords
EndFunc

Func _HotkeyRepository_Count(ByRef $aRecords)
    If Not IsArray($aRecords) Or UBound($aRecords, 2) <> $HOTKEY_FIELD_COUNT Then Return SetError(1, 0, 0)
    Return $aRecords[0][$HOTKEY_FIELD_HOTKEY]
EndFunc

Func _HotkeyRepository_SetRecord(ByRef $aRecords, $iRow, ByRef $aRecord)
    If Not IsArray($aRecords) Or UBound($aRecords, 2) <> $HOTKEY_FIELD_COUNT Then Return SetError(1, 0, False)
    If Not IsInt($iRow) Or $iRow < 1 Or $iRow > _HotkeyRepository_Count($aRecords) Then Return SetError(2, 0, False)
    If Not _HotkeyModel_IsValid($aRecord) Then Return SetError(3, @error, False)
    Local $i
    For $i = 0 To $HOTKEY_FIELD_COUNT - 1
        $aRecords[$iRow][$i] = $aRecord[$i]
    Next
    Return True
EndFunc

Func _HotkeyRepository_GetRecord(ByRef $aRecords, $iRow)
    If Not IsArray($aRecords) Or UBound($aRecords, 2) <> $HOTKEY_FIELD_COUNT Then Return SetError(1, 0, 0)
    If Not IsInt($iRow) Or $iRow < 1 Or $iRow > _HotkeyRepository_Count($aRecords) Then Return SetError(2, 0, 0)
    Local $aRecord[$HOTKEY_FIELD_COUNT]
    Local $i
    For $i = 0 To $HOTKEY_FIELD_COUNT - 1
        $aRecord[$i] = $aRecords[$iRow][$i]
    Next
    Return $aRecord
EndFunc

Func _HotkeyRepository_Load($sIniFile)
    If Not FileExists($sIniFile) Then Return SetError($HOTKEY_REPOSITORY_ERROR_READ, 0, 0)
    Local $aSection = IniReadSection($sIniFile, "Hotkeys")
    If @error Then Return _HotkeyRepository_CreateTable(0)
    Local $aRecords = _HotkeyRepository_CreateTable($aSection[0][0])
    Local $i, $j, $sPlainAction, $aRecord, $sNormalized
    For $i = 1 To $aSection[0][0]
        $sPlainAction = _HotkeyRepository_ClassifyPlainValue($aSection[$i][1])
        $aRecord = _HotkeyCodec_DecodeLegacy($aSection[$i][0], $aSection[$i][1], $sPlainAction)
        If @error Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $i, 0)
        $sNormalized = _HotkeyCodec_NormalizeHotkey($aRecord[$HOTKEY_FIELD_HOTKEY])
        For $j = 1 To $i - 1
            If $sNormalized = _HotkeyCodec_NormalizeHotkey($aRecords[$j][$HOTKEY_FIELD_HOTKEY]) Then Return SetError($HOTKEY_REPOSITORY_ERROR_DUPLICATE, $i, 0)
        Next
        If Not _HotkeyRepository_SetRecord($aRecords, $i, $aRecord) Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $i, 0)
    Next
    Return $aRecords
EndFunc

Func _HotkeyRepository_Save($sIniFile, ByRef $aRecords)
    If Not _HotkeyRepository_ValidateTable($aRecords) Then
        Local $iValidationError = @extended
        Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $iValidationError, False)
    EndIf
    Local $sTemporaryFile = $sIniFile & ".tmp"
    Local $sBackupFile = $sIniFile & ".bak"
    FileDelete($sTemporaryFile)
    If FileExists($sIniFile) And Not FileCopy($sIniFile, $sTemporaryFile, 1) Then Return SetError($HOTKEY_REPOSITORY_ERROR_WRITE, 1, False)
    If Not FileExists($sTemporaryFile) Then
        Local $hTemporaryFile = FileOpen($sTemporaryFile, 2)
        If $hTemporaryFile = -1 Then Return SetError($HOTKEY_REPOSITORY_ERROR_WRITE, 2, False)
        FileClose($hTemporaryFile)
    EndIf
    IniDelete($sTemporaryFile, "Hotkeys")
    Local $aRemainingSection = IniReadSection($sTemporaryFile, "Hotkeys")
    If IsArray($aRemainingSection) Then
        FileDelete($sTemporaryFile)
        Return SetError($HOTKEY_REPOSITORY_ERROR_WRITE, 3, False)
    EndIf

    Local $i, $aRecord, $sValue
    For $i = 1 To _HotkeyRepository_Count($aRecords)
        $aRecord = _HotkeyRepository_GetRecord($aRecords, $i)
        $sValue = _HotkeyCodec_EncodeLegacy($aRecord)
        If @error Or Not IniWrite($sTemporaryFile, "Hotkeys", _HotkeyCodec_EncodeIniKey($aRecord), $sValue) Then
            FileDelete($sTemporaryFile)
            Return SetError($HOTKEY_REPOSITORY_ERROR_WRITE, $i, False)
        EndIf
    Next

    Local $aVerified = _HotkeyRepository_Load($sTemporaryFile)
    If @error Or Not _HotkeyRepository_TablesEqual($aRecords, $aVerified) Then
        FileDelete($sTemporaryFile)
        Return SetError($HOTKEY_REPOSITORY_ERROR_VERIFY, 0, False)
    EndIf

    If FileExists($sIniFile) Then
        FileDelete($sBackupFile)
        If Not _WinAPI_ReplaceFile($sIniFile, $sTemporaryFile, $sBackupFile) Then
            FileDelete($sTemporaryFile)
            Return SetError($HOTKEY_REPOSITORY_ERROR_REPLACE, @error, False)
        EndIf
    ElseIf Not FileMove($sTemporaryFile, $sIniFile, 1) Then
        FileDelete($sTemporaryFile)
        Return SetError($HOTKEY_REPOSITORY_ERROR_REPLACE, 0, False)
    EndIf
    Return True
EndFunc

Func _HotkeyRepository_ValidateTable(ByRef $aRecords)
    If Not IsArray($aRecords) Or UBound($aRecords, 2) <> $HOTKEY_FIELD_COUNT Then Return SetError(1, 0, False)
    Local $iCount = _HotkeyRepository_Count($aRecords)
    If Not IsInt($iCount) Or $iCount < 0 Or UBound($aRecords, 1) <> $iCount + 1 Then Return SetError(2, 0, False)
    Local $i, $j, $aRecord, $sNormalized
    For $i = 1 To $iCount
        $aRecord = _HotkeyRepository_GetRecord($aRecords, $i)
        If Not _HotkeyModel_IsValid($aRecord) Then Return SetError(3, $i, False)
        $sNormalized = _HotkeyCodec_NormalizeHotkey($aRecord[$HOTKEY_FIELD_HOTKEY])
        For $j = 1 To $i - 1
            If $sNormalized = _HotkeyCodec_NormalizeHotkey($aRecords[$j][$HOTKEY_FIELD_HOTKEY]) Then Return SetError(4, $i, False)
        Next
    Next
    Return True
EndFunc

Func _HotkeyRepository_TablesEqual(ByRef $aLeft, ByRef $aRight)
    If Not IsArray($aLeft) Or Not IsArray($aRight) Then Return False
    If _HotkeyRepository_Count($aLeft) <> _HotkeyRepository_Count($aRight) Then Return False
    Local $i, $j
    For $i = 1 To _HotkeyRepository_Count($aLeft)
        For $j = 0 To $HOTKEY_FIELD_COUNT - 1
            If $aLeft[$i][$j] <> $aRight[$i][$j] Then Return False
        Next
    Next
    Return True
EndFunc

Func _HotkeyRepository_ClassifyPlainValue($sValue)
    Local $sCandidate = StringReplace(StringReplace($sValue, $HOTKEY_CODEC_OPTION_ADMIN, ""), $HOTKEY_CODEC_OPTION_SINGLETON, "")
    If StringLeft($sCandidate, 1) = "[" Then Return $HOTKEY_ACTION_FILE
    If StringRegExp($sCandidate, "(?i)^(https?|ftp)://") And Not StringInStr($sCandidate, $HOTKEY_CODEC_PARAMETER) Then Return $HOTKEY_ACTION_URL
    $sCandidate = StringReplace($sCandidate, $HOTKEY_CODEC_EQUAL, "=")
    If StringLeft($sCandidate, 3) = "::{" Or StringInStr(FileGetAttrib($sCandidate), "D") Then Return $HOTKEY_ACTION_FOLDER
    Return $HOTKEY_ACTION_FILE
EndFunc
