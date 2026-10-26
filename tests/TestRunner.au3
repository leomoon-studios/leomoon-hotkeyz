#include "..\src\core\HotkeyRepository.au3"

Opt("MustDeclareVars", 1)

Global $g_iFailures = 0
Global $g_iAssertions = 0

_TestSpecialKeys()
_TestCodecRoundTrips()
_TestTags()
_TestLegacyFixtures()
_TestRepositoryRecovery()

If $g_iFailures Then
    ConsoleWrite("FAILED: " & $g_iFailures & " of " & $g_iAssertions & " assertions" & @CRLF)
    Exit 1
EndIf
ConsoleWrite("PASSED: " & $g_iAssertions & " assertions" & @CRLF)
Exit 0

Func _TestSpecialKeys()
    Local $aKeys = StringSplit("`|1|=|Space|Backspace|Enter|Up|Down|Left|Right|Escape|F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|Print Screen key|Pause key|Insert|Delete|Home|End|Page Up|Page Down|Numpad 1|Numpad 2|Numpad 3|Numpad 4|Numpad 5|Numpad 6|Numpad 7|Numpad 8|Numpad 9|Numpad 0|Numpad Dot|Numpad Divide|Numpad Multiply|Numpad Subtract|Numpad Add", "|")
    Local $i
    For $i = 1 To $aKeys[0]
        _AssertEqual($aKeys[$i], _HotkeyCodec_DecodeKey(_HotkeyCodec_EncodeKey($aKeys[$i])), "special key round trip: " & $aKeys[$i])
    Next
    _AssertEqual("^!{HkzEq}", _HotkeyCodec_EncodeHotkey("Ctrl + Alt + ="), "equals-sign hotkey encoding")
    _AssertEqual("Ctrl + Alt + =", _HotkeyCodec_DecodeHotkey("^!{HkzEq}"), "equals-sign hotkey decoding")
EndFunc

Func _TestCodecRoundTrips()
    Local $aCases[8][3] = [ _
        [$HOTKEY_ACTION_FILE, "C:\Program Files\Tool\tool.exe", "--query=a=b"], _
        [$HOTKEY_ACTION_FOLDER, "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}", ""], _
        [$HOTKEY_ACTION_URL, "https://example.com/search?q=hotkeyz", ""], _
        [$HOTKEY_ACTION_TEXT, "First line" & @LF & "Second line = value", ""], _
        [$HOTKEY_ACTION_WINDOW, "Snap Left (2x1)", ""], _
        [$HOTKEY_ACTION_COMMAND, "echo value=one", ""], _
        [$HOTKEY_ACTION_SYSTEM, "Lock", ""], _
        [$HOTKEY_ACTION_MEDIA, "Volume Up", ""]]
    Local $i, $iOptions, $sEncoded, $aOriginal, $aDecoded
    For $i = 0 To UBound($aCases, 1) - 1
        $aOriginal = _HotkeyModel_Create("^!a", $aCases[$i][0], $aCases[$i][1], $aCases[$i][2], $HOTKEY_OPTION_ALL)
        $sEncoded = _HotkeyCodec_EncodeLegacy($aOriginal)
        _AssertFalse(@error, "encode action: " & $aCases[$i][0])
        $aDecoded = _HotkeyCodec_DecodeLegacy("^!a", $sEncoded, $aCases[$i][0])
        _AssertFalse(@error, "decode action: " & $aCases[$i][0])
        _AssertRecordEqual($aOriginal, $aDecoded, "action round trip: " & $aCases[$i][0])
    Next
    For $iOptions = $HOTKEY_OPTION_NONE To $HOTKEY_OPTION_ALL
        $aOriginal = _HotkeyModel_Create("^!b", $HOTKEY_ACTION_FILE, "C:\tool.exe", "", $iOptions)
        $aDecoded = _HotkeyCodec_DecodeLegacy("^!b", _HotkeyCodec_EncodeLegacy($aOriginal), $HOTKEY_ACTION_FILE)
        _AssertEqual($iOptions, $aDecoded[$HOTKEY_FIELD_OPTIONS], "option round trip: " & $iOptions)
    Next
EndFunc

Func _TestTags()
    Local $aTestTags[2][2] = [["<YYYY-MM-DD>", "2026-10-26"], ["<USER>", "tester"]]
    _AssertEqual("Date 2026-10-26 for tester", _HotkeyCodec_ExpandTags("Date <YYYY-MM-DD> for <USER>", $aTestTags), "date tag expansion")
EndFunc

Func _TestLegacyFixtures()
    Local $aLegacy = _HotkeyRepository_Load(@ScriptDir & "\fixtures\legacy-v1.8.12.ini")
    _AssertFalse(@error, "load version 1.8.12 fixture")
    _AssertEqual(8, _HotkeyRepository_Count($aLegacy), "legacy fixture entry count")
    _AssertEqual($HOTKEY_ACTION_FILE, $aLegacy[1][$HOTKEY_FIELD_ACTION], "legacy file action")
    _AssertEqual("--mode=safe", $aLegacy[1][$HOTKEY_FIELD_PARAMETERS], "legacy parameter marker")
    _AssertEqual($HOTKEY_OPTION_ALL, $aLegacy[1][$HOTKEY_FIELD_OPTIONS], "legacy options")
    _AssertEqual($HOTKEY_ACTION_FOLDER, $aLegacy[2][$HOTKEY_FIELD_ACTION], "legacy folder action")
    _AssertEqual($HOTKEY_ACTION_URL, $aLegacy[3][$HOTKEY_FIELD_ACTION], "legacy URL action")
    _AssertEqual($HOTKEY_ACTION_TEXT, $aLegacy[4][$HOTKEY_FIELD_ACTION], "legacy text action")
    _AssertTrue(StringInStr($aLegacy[4][$HOTKEY_FIELD_TARGET], @LF) > 0, "legacy newline marker")
    _AssertEqual($HOTKEY_ACTION_WINDOW, $aLegacy[5][$HOTKEY_FIELD_ACTION], "legacy window action")
    _AssertEqual($HOTKEY_ACTION_COMMAND, $aLegacy[6][$HOTKEY_FIELD_ACTION], "legacy command action")
    _AssertEqual($HOTKEY_ACTION_SYSTEM, $aLegacy[7][$HOTKEY_FIELD_ACTION], "legacy system action")
    _AssertEqual($HOTKEY_ACTION_MEDIA, $aLegacy[8][$HOTKEY_FIELD_ACTION], "legacy media action")

    Local $aMalformed = _HotkeyRepository_Load(@ScriptDir & "\fixtures\malformed.ini")
    Local $iMalformedError = @error
    _AssertFalse(IsArray($aMalformed), "reject malformed legacy marker")
    _AssertEqual($HOTKEY_REPOSITORY_ERROR_INVALID, $iMalformedError, "malformed error code")

    Local $aDuplicate = _HotkeyRepository_Load(@ScriptDir & "\fixtures\duplicate.ini")
    Local $iDuplicateError = @error
    _AssertFalse(IsArray($aDuplicate), "reject duplicate hotkeys")
    _AssertEqual($HOTKEY_REPOSITORY_ERROR_DUPLICATE, $iDuplicateError, "duplicate error code")
EndFunc

Func _TestRepositoryRecovery()
    Local $sTestFile = @TempDir & "\hotkeyz-step2-" & @AutoItPID & ".ini"
    Local $sBackupFile = $sTestFile & ".bak"
    Local $sTemporaryFile = $sTestFile & ".tmp"
    FileDelete($sTestFile)
    FileDelete($sBackupFile)
    FileDelete($sTemporaryFile)
    _AssertTrue(FileCopy(@ScriptDir & "\fixtures\legacy-v1.8.12.ini", $sTestFile, 1), "prepare migration file")
    Local $aLegacy = _HotkeyRepository_Load($sTestFile)
    _AssertTrue(_HotkeyRepository_Save($sTestFile, $aLegacy), "atomic legacy migration save")
    _AssertTrue(FileExists($sBackupFile), "recoverable backup created")
    Local $aReloaded = _HotkeyRepository_Load($sTestFile)
    _AssertTrue(_HotkeyRepository_TablesEqual($aLegacy, $aReloaded), "saved records reload identically")

    Local $sBeforeFailedSave = FileRead($sTestFile)
    Local $aInvalid = _HotkeyRepository_CreateTable(2)
    Local $aFirst = _HotkeyModel_Create("^!a", $HOTKEY_ACTION_FILE, "C:\first.exe")
    Local $aSecond = _HotkeyModel_Create("!^a", $HOTKEY_ACTION_FILE, "C:\second.exe")
    _HotkeyRepository_SetRecord($aInvalid, 1, $aFirst)
    _HotkeyRepository_SetRecord($aInvalid, 2, $aSecond)
    _AssertFalse(_HotkeyRepository_Save($sTestFile, $aInvalid), "invalid table is not saved")
    _AssertEqual($sBeforeFailedSave, FileRead($sTestFile), "failed save preserves live INI")
    _AssertFalse(FileExists($sTemporaryFile), "failed validation leaves no temporary file")

    FileDelete($sTestFile)
    FileDelete($sBackupFile)
    FileDelete($sTemporaryFile)
EndFunc

Func _AssertRecordEqual(ByRef $aExpected, ByRef $aActual, $sName)
    Local $i
    _AssertTrue(IsArray($aActual), $sName & " returns a record")
    If Not IsArray($aActual) Then Return
    For $i = 0 To $HOTKEY_FIELD_COUNT - 1
        _AssertEqual($aExpected[$i], $aActual[$i], $sName & " field " & $i)
    Next
EndFunc

Func _AssertEqual($vExpected, $vActual, $sName)
    $g_iAssertions += 1
    If $vExpected = $vActual Then Return
    $g_iFailures += 1
    ConsoleWrite("FAIL: " & $sName & " expected [" & $vExpected & "] actual [" & $vActual & "]" & @CRLF)
EndFunc

Func _AssertTrue($bCondition, $sName)
    $g_iAssertions += 1
    If $bCondition Then Return
    $g_iFailures += 1
    ConsoleWrite("FAIL: " & $sName & @CRLF)
EndFunc

Func _AssertFalse($bCondition, $sName)
    _AssertTrue(Not $bCondition, $sName)
EndFunc
