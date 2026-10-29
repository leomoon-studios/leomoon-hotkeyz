#include-once

#include <WinAPIFiles.au3>
#include <File.au3>
#include <FileConstants.au3>
#include "HotkeyCodec.au3"

Global Const $HOTKEY_REPOSITORY_ERROR_READ = 1
Global Const $HOTKEY_REPOSITORY_ERROR_INVALID = 2
Global Const $HOTKEY_REPOSITORY_ERROR_DUPLICATE = 3
Global Const $HOTKEY_REPOSITORY_ERROR_WRITE = 4
Global Const $HOTKEY_REPOSITORY_ERROR_VERIFY = 5
Global Const $HOTKEY_REPOSITORY_ERROR_REPLACE = 6
Global Const $HOTKEY_REPOSITORY_ERROR_HOTKEY_UNAVAILABLE = 7

; Windows INI APIs treat UTF-8 as the system code page. Convert a copy to
; UTF-16 for those APIs; never rewrite the original merely to read it.
Func _HotkeyRepository_CreateUnicodeCopy($sSource, $sDestination)
    Local $hSource = FileOpen($sSource, $FO_READ + $FO_BINARY)
    If $hSource = -1 Then Return SetError(1, 0, False)
    Local $bData = FileRead($hSource)
    Local $iReadError = @error
    FileClose($hSource)
    If $iReadError And $iReadError <> -1 Then Return SetError(2, $iReadError, False)
    Local $sText, $bContent = $bData
    If BinaryMid($bData, 1, 2) = Binary("0xFFFE") Then
        If Mod(BinaryLen($bData) - 2, 2) Then Return SetError(5, 0, False)
        $sText = BinaryToString(BinaryMid($bData, 3), 2)
    ElseIf BinaryMid($bData, 1, 2) = Binary("0xFEFF") Then
        If Mod(BinaryLen($bData) - 2, 2) Then Return SetError(5, 0, False)
        $sText = BinaryToString(BinaryMid($bData, 3), 3)
    Else
        Local $bUtf8Bom = BinaryMid($bData, 1, 3) = Binary("0xEFBBBF")
        If $bUtf8Bom Then $bContent = BinaryMid($bData, 4)
        $sText = BinaryToString($bContent, 4)
        ; Invalid UTF-8 is a legacy ANSI file in the current Windows code page.
        If StringToBinary($sText, 4) <> $bContent Then
            If $bUtf8Bom Then Return SetError(5, 0, False)
            $sText = BinaryToString($bData, 1)
        EndIf
    EndIf
    Local $hDestination = FileOpen($sDestination, $FO_OVERWRITE + $FO_UTF16_LE)
    If $hDestination = -1 Then Return SetError(3, 0, False)
    Local $bWritten = FileWrite($hDestination, $sText)
    FileClose($hDestination)
    If Not $bWritten Then Return SetError(4, 0, False)
    Return True
EndFunc

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
    Local $sReadCopy = _TempFile(@TempDir, "hotkeyz-read-", ".ini")
    If Not _HotkeyRepository_CreateUnicodeCopy($sIniFile, $sReadCopy) Then
        FileDelete($sReadCopy)
        Return SetError($HOTKEY_REPOSITORY_ERROR_READ, 0, 0)
    EndIf
    Local $aSection = IniReadSection($sReadCopy, "Hotkeys")
    Local $iReadError = @error
    Local $aRestrictions = IniReadSection($sReadCopy, "HotkeyRestrictions")
    Local $aRestrictedActions = IniReadSection($sReadCopy, "HotkeyRestrictedActions")
    Local $sRestrictionVersion = IniRead($sReadCopy, "HotkeyRestrictions", "Version", "")
    FileDelete($sReadCopy)
    If IsArray($aRestrictions) And $sRestrictionVersion <> "1" Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, 0, 0)
    If IsArray($aRestrictions) <> IsArray($aRestrictedActions) Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, 0, 0)
    If $iReadError Then
        If IsArray($aRestrictions) Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, 0, 0)
        Return _HotkeyRepository_CreateTable(0)
    EndIf
    Local $aRecords = _HotkeyRepository_CreateTable($aSection[0][0])
    Local $i, $j, $sPlainAction, $aRecord, $sNormalized, $sValue, $bRestricted, $iRestrictionIndex, $iActionIndex
    Local $iMatchedRestrictions = 0
    ; Normalize once per entry, not on every comparison in the matching loops.
    Local $aKeys[$aSection[0][0] + 1], $aRestrictionKeys[1], $aActionKeys[1]
    If IsArray($aRestrictions) Then
        ReDim $aRestrictionKeys[$aRestrictions[0][0] + 1]
        For $j = 1 To $aRestrictions[0][0]
            $aRestrictionKeys[$j] = _HotkeyCodec_NormalizeHotkey(_HotkeyCodec_ToNativeHotkey($aRestrictions[$j][0]))
        Next
    EndIf
    If IsArray($aRestrictedActions) Then
        ReDim $aActionKeys[$aRestrictedActions[0][0] + 1]
        For $j = 1 To $aRestrictedActions[0][0]
            $aActionKeys[$j] = _HotkeyCodec_NormalizeHotkey(_HotkeyCodec_ToNativeHotkey($aRestrictedActions[$j][0]))
        Next
    EndIf
    For $i = 1 To $aSection[0][0]
        $aKeys[$i] = _HotkeyCodec_NormalizeHotkey(_HotkeyCodec_ToNativeHotkey($aSection[$i][0]))
        $sValue = $aSection[$i][1]
        $bRestricted = $sValue = $HOTKEY_CODEC_RESTRICTED
        If $bRestricted Then
            If Not IsArray($aRestrictedActions) Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $i, 0)
            $iActionIndex = 0
            For $j = 1 To $aRestrictedActions[0][0]
                If $aActionKeys[$j] <> $aKeys[$i] Then ContinueLoop
                If $iActionIndex Then Return SetError($HOTKEY_REPOSITORY_ERROR_DUPLICATE, $i, 0)
                $iActionIndex = $j
            Next
            If Not $iActionIndex Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $i, 0)
            $sValue = $aRestrictedActions[$iActionIndex][1]
        EndIf
        $sPlainAction = _HotkeyRepository_ClassifyPlainValue($sValue)
        $aRecord = _HotkeyCodec_DecodeLegacy($aSection[$i][0], $sValue, $sPlainAction)
        If @error Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $i, 0)
        $sNormalized = _HotkeyCodec_NormalizeHotkey($aRecord[$HOTKEY_FIELD_HOTKEY])
        $aKeys[$i] = $sNormalized
        For $j = 1 To $i - 1
            If $sNormalized = $aKeys[$j] Then Return SetError($HOTKEY_REPOSITORY_ERROR_DUPLICATE, $i, 0)
        Next
        $iRestrictionIndex = 0
        If IsArray($aRestrictions) Then
            For $j = 1 To $aRestrictions[0][0]
                If $aRestrictions[$j][0] = "Version" Then ContinueLoop
                If $aRestrictionKeys[$j] <> $sNormalized Then ContinueLoop
                If $iRestrictionIndex Then Return SetError($HOTKEY_REPOSITORY_ERROR_DUPLICATE, $i, 0)
                $iRestrictionIndex = $j
            Next
        EndIf
        If $bRestricted <> ($iRestrictionIndex <> 0) Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $i, 0)
        If $bRestricted Then
            If Not _HotkeyCodec_DecodeRestrictions($aRecord, $aRestrictions[$iRestrictionIndex][1]) Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $i, 0)
            $iMatchedRestrictions += 1
        EndIf
        If Not _HotkeyRepository_SetRecord($aRecords, $i, $aRecord) Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $i, 0)
    Next
    If IsArray($aRestrictions) And $aRestrictions[0][0] <> $iMatchedRestrictions + 1 Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, 0, 0)
    If IsArray($aRestrictedActions) And $aRestrictedActions[0][0] <> $iMatchedRestrictions Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, 0, 0)
    Return $aRecords
EndFunc

Func _HotkeyRepository_Save($sIniFile, ByRef $aRecords)
    If Not _HotkeyRepository_ValidateTable($aRecords) Then
        Local $iValidationError = @extended
        Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, $iValidationError, False)
    EndIf
    ; Never overwrite an unreadable or newer profile format with older data.
    If FileExists($sIniFile) Then
        Local $aExisting = _HotkeyRepository_Load($sIniFile)
        If @error Or Not IsArray($aExisting) Then Return SetError($HOTKEY_REPOSITORY_ERROR_INVALID, 0, False)
    EndIf
    Local $sTemporaryFile = $sIniFile & ".tmp"
    Local $sBackupFile = $sIniFile & ".bak"
    FileDelete($sTemporaryFile)
    If FileExists($sIniFile) And Not _HotkeyRepository_CreateUnicodeCopy($sIniFile, $sTemporaryFile) Then Return SetError($HOTKEY_REPOSITORY_ERROR_WRITE, 1, False)
    If Not FileExists($sTemporaryFile) Then
        Local $hTemporaryFile = FileOpen($sTemporaryFile, $FO_OVERWRITE + $FO_UTF16_LE)
        If $hTemporaryFile = -1 Then Return SetError($HOTKEY_REPOSITORY_ERROR_WRITE, 2, False)
        FileClose($hTemporaryFile)
    EndIf
    IniDelete($sTemporaryFile, "Hotkeys")
    IniDelete($sTemporaryFile, "HotkeyRestrictions")
    IniDelete($sTemporaryFile, "HotkeyRestrictedActions")
    Local $aRemainingSection = IniReadSection($sTemporaryFile, "Hotkeys")
    If IsArray($aRemainingSection) Then
        FileDelete($sTemporaryFile)
        Return SetError($HOTKEY_REPOSITORY_ERROR_WRITE, 3, False)
    EndIf

    ; Build each section in memory, then write it once. Per-entry IniWrite calls
    ; repeatedly rewrite the growing file, especially for restricted profiles.
    Local $i, $aRecord, $sValue, $sKey, $iCount = _HotkeyRepository_Count($aRecords), $iRestricted = 0
    Local $aHotkeySection[$iCount + 1][2], $aRestrictionSection[$iCount + 2][2], $aActionSection[$iCount + 1][2]
    $aRestrictionSection[1][0] = "Version"
    $aRestrictionSection[1][1] = "1"
    For $i = 1 To $iCount
        $aRecord = _HotkeyRepository_GetRecord($aRecords, $i)
        $sValue = _HotkeyCodec_EncodeLegacy($aRecord)
        If @error Then
            FileDelete($sTemporaryFile)
            Return SetError($HOTKEY_REPOSITORY_ERROR_WRITE, $i, False)
        EndIf
        $sKey = _HotkeyCodec_EncodeIniKey($aRecord)
        If _HotkeyModel_HasRestrictions($aRecord) Then
            $iRestricted += 1
            $aRestrictionSection[$iRestricted + 1][0] = $sKey
            $aRestrictionSection[$iRestricted + 1][1] = _HotkeyCodec_EncodeRestrictions($aRecord)
            $aActionSection[$iRestricted][0] = $sKey
            $aActionSection[$iRestricted][1] = $sValue
            $sValue = $HOTKEY_CODEC_RESTRICTED
        EndIf
        $aHotkeySection[$i][0] = $sKey
        $aHotkeySection[$i][1] = $sValue
    Next
    If $iCount And Not IniWriteSection($sTemporaryFile, "Hotkeys", $aHotkeySection) Then
        FileDelete($sTemporaryFile)
        Return SetError($HOTKEY_REPOSITORY_ERROR_WRITE, 4, False)
    EndIf
    If $iRestricted Then
        ReDim $aRestrictionSection[$iRestricted + 2][2]
        ReDim $aActionSection[$iRestricted + 1][2]
        If Not IniWriteSection($sTemporaryFile, "HotkeyRestrictions", $aRestrictionSection) Or Not IniWriteSection($sTemporaryFile, "HotkeyRestrictedActions", $aActionSection) Then
            FileDelete($sTemporaryFile)
            Return SetError($HOTKEY_REPOSITORY_ERROR_WRITE, 5, False)
        EndIf
    EndIf

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
    Local $aKeys[$iCount + 1]
    For $i = 1 To $iCount
        $aRecord = _HotkeyRepository_GetRecord($aRecords, $i)
        If Not _HotkeyModel_IsValid($aRecord) Then Return SetError(3, $i, False)
        $sNormalized = _HotkeyCodec_NormalizeHotkey($aRecord[$HOTKEY_FIELD_HOTKEY])
        $aKeys[$i] = $sNormalized
        For $j = 1 To $i - 1
            If $sNormalized = $aKeys[$j] Then Return SetError(4, $i, False)
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
            ; The INI uses {HkzEq}, while runtime records use {=}.
            If $j = $HOTKEY_FIELD_HOTKEY Then
                If _HotkeyCodec_NormalizeHotkey($aLeft[$i][$j]) <> _HotkeyCodec_NormalizeHotkey($aRight[$i][$j]) Then Return False
                ContinueLoop
            EndIf
            ; The legacy format uses the same plain value for files and folders.
            ; An unavailable folder can therefore reload as a file on this PC.
            If $j = $HOTKEY_FIELD_ACTION And $aLeft[$i][$j] <> $aRight[$i][$j] Then
                If ($aLeft[$i][$j] = $HOTKEY_ACTION_FOLDER And $aRight[$i][$j] = $HOTKEY_ACTION_FILE) Or ($aLeft[$i][$j] = $HOTKEY_ACTION_FILE And $aRight[$i][$j] = $HOTKEY_ACTION_FOLDER) Then ContinueLoop
            EndIf
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
