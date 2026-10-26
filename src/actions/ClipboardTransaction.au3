#include-once

#include <Clipboard.au3>
#include <Memory.au3>

Global $g_sClipboardSnapshotHandler = "_ClipboardTransaction_Snapshot"
Global $g_sClipboardRestoreHandler = "_ClipboardTransaction_Restore"
Global $g_sClipboardWriteHandler = "_ClipboardTransaction_WriteText"
Global $g_sClipboardReadHandler = "_ClipboardTransaction_ReadText"
Global $g_sClipboardSendHandler = "_ClipboardTransaction_Send"
Global $g_sClipboardWaitHandler = "_ClipboardTransaction_Wait"
Global $g_sClipboardSequenceHandler = "_ClipBoard_GetSequenceNumber"

Func _ClipboardTransaction_ConfigureBackend($sSnapshot, $sRestore, $sWrite, $sRead, $sSend, $sWait, $sSequence)
    $g_sClipboardSnapshotHandler = $sSnapshot
    $g_sClipboardRestoreHandler = $sRestore
    $g_sClipboardWriteHandler = $sWrite
    $g_sClipboardReadHandler = $sRead
    $g_sClipboardSendHandler = $sSend
    $g_sClipboardWaitHandler = $sWait
    $g_sClipboardSequenceHandler = $sSequence
EndFunc

Func _ClipboardTransaction_ResetBackend()
    _ClipboardTransaction_ConfigureBackend("_ClipboardTransaction_Snapshot", "_ClipboardTransaction_Restore", "_ClipboardTransaction_WriteText", "_ClipboardTransaction_ReadText", "_ClipboardTransaction_Send", "_ClipboardTransaction_Wait", "_ClipBoard_GetSequenceNumber")
EndFunc

Func _ClipboardTransaction_Paste($sText)
    Local $aSnapshot = Call($g_sClipboardSnapshotHandler)
    If @error Or Not IsArray($aSnapshot) Then Return SetError(1, 0, False)
    Local $bSuccess = False
    Local $iFailure = 0
    Do
        If Not Call($g_sClipboardWriteHandler, $sText) Then
            $iFailure = 2
            ExitLoop
        EndIf
        If Not Call($g_sClipboardSendHandler, "^v") Then
            $iFailure = 3
            ExitLoop
        EndIf
        If Not Call($g_sClipboardWaitHandler, 0, False) Then
            $iFailure = 4
            ExitLoop
        EndIf
        $bSuccess = True
    Until True
    If Not Call($g_sClipboardRestoreHandler, $aSnapshot) Then Return SetError(5, $iFailure, False)
    If Not $bSuccess Then Return SetError($iFailure, 0, False)
    Return True
EndFunc

Func _ClipboardTransaction_TransformSelection($sTransform)
    Local $aSnapshot = Call($g_sClipboardSnapshotHandler)
    If @error Or Not IsArray($aSnapshot) Then Return SetError(1, 0, False)
    Local $bSuccess = False
    Local $iFailure = 0
    Do
        Local $iSequence = Call($g_sClipboardSequenceHandler)
        If @error Then
            $iFailure = 2
            ExitLoop
        EndIf
        If Not Call($g_sClipboardSendHandler, "^c") Then
            $iFailure = 3
            ExitLoop
        EndIf
        If Not Call($g_sClipboardWaitHandler, $iSequence, True) Then
            $iFailure = 4
            ExitLoop
        EndIf
        Local $sSelected = Call($g_sClipboardReadHandler)
        If @error Then
            $iFailure = 5
            ExitLoop
        EndIf
        Local $sTransformed = _TextActions_Transform($sTransform, $sSelected)
        If @error Then
            $iFailure = 6
            ExitLoop
        EndIf
        If Not Call($g_sClipboardWriteHandler, $sTransformed) Then
            $iFailure = 7
            ExitLoop
        EndIf
        If Not Call($g_sClipboardSendHandler, "^v") Then
            $iFailure = 8
            ExitLoop
        EndIf
        If Not Call($g_sClipboardWaitHandler, 0, False) Then
            $iFailure = 9
            ExitLoop
        EndIf
        $bSuccess = True
    Until True
    If Not Call($g_sClipboardRestoreHandler, $aSnapshot) Then Return SetError(10, $iFailure, False)
    If Not $bSuccess Then Return SetError($iFailure, 0, False)
    Return True
EndFunc

Func _ClipboardTransaction_Snapshot()
    Local $aSnapshot[1][2]
    Local $iCount = 0
    Local $iFormat = 0
    While 1
        $iFormat = _ClipBoard_EnumFormats($iFormat)
        If @error Then Return SetError(1, @extended, 0)
        If $iFormat = 0 Then ExitLoop
        If Not _ClipboardTransaction_CanPreserveFormat($iFormat) Then ContinueLoop
        Local $vData = _ClipBoard_GetData($iFormat)
        If @error Then ContinueLoop
        $iCount += 1
        ReDim $aSnapshot[$iCount + 1][2]
        $aSnapshot[$iCount][0] = $iFormat
        $aSnapshot[$iCount][1] = $vData
    WEnd
    $aSnapshot[0][0] = $iCount
    Return $aSnapshot
EndFunc

Func _ClipboardTransaction_Restore(ByRef $aSnapshot)
    If Not IsArray($aSnapshot) Or UBound($aSnapshot, 2) <> 2 Then Return SetError(1, 0, False)
    If Not _ClipBoard_Open(0) Then Return SetError(2, 0, False)
    If Not _ClipBoard_Empty() Then
        _ClipBoard_Close()
        Return SetError(3, 0, False)
    EndIf
    Local $i
    For $i = 1 To $aSnapshot[0][0]
        If Not _ClipboardTransaction_SetOpenData($aSnapshot[$i][1], $aSnapshot[$i][0]) Then
            _ClipBoard_Close()
            Return SetError(4, $i, False)
        EndIf
    Next
    If Not _ClipBoard_Close() Then Return SetError(5, 0, False)
    Return True
EndFunc

Func _ClipboardTransaction_SetOpenData($vData, $iFormat)
    Local $iSize, $tData
    If IsBinary($vData) Then
        $iSize = BinaryLen($vData) + 1
    ElseIf IsString($vData) Then
        $iSize = StringLen($vData) + 1
    Else
        Return SetError(1, 0, False)
    EndIf
    Local $iAllocationSize = $iSize
    If $iFormat = $CF_UNICODETEXT Then $iAllocationSize *= 2
    Local $hMemory = _MemGlobalAlloc($iAllocationSize, $GHND)
    If $hMemory = 0 Then Return SetError(2, 0, False)
    Local $pMemory = _MemGlobalLock($hMemory)
    If $pMemory = 0 Then
        _MemGlobalFree($hMemory)
        Return SetError(3, 0, False)
    EndIf
    If $iFormat = $CF_UNICODETEXT Then
        $tData = DllStructCreate("wchar[" & $iSize & "]", $pMemory)
    ElseIf $iFormat = $CF_TEXT Or $iFormat = $CF_OEMTEXT Then
        $tData = DllStructCreate("char[" & $iSize & "]", $pMemory)
    Else
        $tData = DllStructCreate("byte[" & $iAllocationSize & "]", $pMemory)
    EndIf
    DllStructSetData($tData, 1, $vData)
    _MemGlobalUnlock($hMemory)
    If Not _ClipBoard_SetDataEx($hMemory, $iFormat) Then
        _MemGlobalFree($hMemory)
        Return SetError(4, 0, False)
    EndIf
    Return True
EndFunc

Func _ClipboardTransaction_CanPreserveFormat($iFormat)
    Switch $iFormat
        Case $CF_BITMAP, $CF_METAFILEPICT, $CF_PALETTE, $CF_ENHMETAFILE, $CF_DSPBITMAP, $CF_DSPMETAFILEPICT, $CF_DSPENHMETAFILE
            Return False
    EndSwitch
    Return True
EndFunc

Func _ClipboardTransaction_WriteText($sText)
    Local $bResult = ClipPut($sText)
    If @error Or Not $bResult Then Return SetError(1, @error, False)
    Return True
EndFunc

Func _ClipboardTransaction_ReadText()
    Local $sText = ClipGet()
    If @error Then Return SetError(1, 0, "")
    Return $sText
EndFunc

Func _ClipboardTransaction_Send($sKeys)
    Return Send($sKeys) <> 0
EndFunc

Func _ClipboardTransaction_Wait($iSequence, $bRequireChange)
    If Not $bRequireChange Then
        Sleep(100)
        Return True
    EndIf
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < 1000
        If _ClipBoard_GetSequenceNumber() <> $iSequence Then Return True
        Sleep(10)
    WEnd
    Return SetError(1, 0, False)
EndFunc
