#include "..\src\core\HotkeyRepository.au3"
#include "..\src\actions\ActionDispatcher.au3"

Opt("MustDeclareVars", 1)

Global $g_iFailures = 0
Global $g_iAssertions = 0

_TestSpecialKeys()
_TestCodecRoundTrips()
_TestTags()
_TestLegacyFixtures()
_TestRepositoryRecovery()
_TestActionValidationAndDispatch()

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

Func _TestActionValidationAndDispatch()
    Local $aSystemActions[10][2] = [ _
        ["Empty Recycle Bin", $SYSTEM_ACTION_EMPTY_RECYCLE_BIN], _
        ["Lock", $SYSTEM_ACTION_LOCK], _
        ["Log Off", $SYSTEM_ACTION_LOG_OFF], _
        ["Restart", $SYSTEM_ACTION_RESTART], _
        ["Shutdown", $SYSTEM_ACTION_SHUTDOWN], _
        ["Turn Off Monitors", $SYSTEM_ACTION_TURN_OFF_MONITORS], _
        ["Turn Off Monitors And Lock", $SYSTEM_ACTION_TURN_OFF_MONITORS_AND_LOCK], _
        ["Start Screensaver", $SYSTEM_ACTION_START_SCREENSAVER], _
        ["Start Screensaver And Lock", $SYSTEM_ACTION_START_SCREENSAVER_AND_LOCK], _
        ["Empty Clipboard", $SYSTEM_ACTION_EMPTY_CLIPBOARD]]
    Local $i
    For $i = 0 To UBound($aSystemActions, 1) - 1
        _AssertEqual($aSystemActions[$i][1], _SystemActions_GetId($aSystemActions[$i][0]), "allowed system action has fixed handler: " & $aSystemActions[$i][0])
    Next
    _AssertEqual($SYSTEM_ACTION_NONE, _SystemActions_GetId("RunAnything"), "unknown system action has no handler")
    Local $sSystemSource = FileRead(@ScriptDir & "\..\src\actions\SystemActions.au3")
    _AssertFalse(StringRegExp($sSystemSource, "(?m)^\s*Execute\(") = 1, "system action module has no dynamic Execute call")

    Local $aTamperedTable = _HotkeyRepository_Load(@ScriptDir & "\fixtures\tampered-system.ini")
    _AssertFalse(@error, "tampered fixture remains parseable legacy data")
    Local $aTampered = _HotkeyRepository_GetRecord($aTamperedTable, 1)
    _AssertFalse(_ActionValidator_ValidateRecord($aTampered, False), "tampered system identifier is rejected")
    Local $aNoTags[1][2] = [["<NONE>", ""]]
    Local $aPreparedTampered = _ActionDispatcher_Prepare($aTampered, $aNoTags)
    _AssertFalse(IsArray($aPreparedTampered), "tampered system identifier cannot reach dispatch")

    Local $aActions[8][2] = [ _
        [$HOTKEY_ACTION_FILE, $ACTION_ROUTE_FILE], _
        [$HOTKEY_ACTION_FOLDER, $ACTION_ROUTE_FOLDER], _
        [$HOTKEY_ACTION_URL, $ACTION_ROUTE_URL], _
        [$HOTKEY_ACTION_TEXT, $ACTION_ROUTE_TEXT], _
        [$HOTKEY_ACTION_WINDOW, $ACTION_ROUTE_WINDOW], _
        [$HOTKEY_ACTION_COMMAND, $ACTION_ROUTE_COMMAND], _
        [$HOTKEY_ACTION_SYSTEM, $ACTION_ROUTE_SYSTEM], _
        [$HOTKEY_ACTION_MEDIA, $ACTION_ROUTE_MEDIA]]
    For $i = 0 To UBound($aActions, 1) - 1
        _AssertEqual($aActions[$i][1], _ActionDispatcher_GetRoute($aActions[$i][0]), "explicit route for action: " & $aActions[$i][0])
    Next
    _AssertEqual($ACTION_ROUTE_NONE, _ActionDispatcher_GetRoute("tampered"), "unknown action has no route")

    Local $sSpacedPath = @TempDir & "\HotKeyz Step 4 " & @AutoItPID & ".exe"
    Local $hSpacedFile = FileOpen($sSpacedPath, 2)
    _AssertTrue($hSpacedFile <> -1, "create path-with-spaces fixture")
    If $hSpacedFile <> -1 Then FileClose($hSpacedFile)
    Local $aFile = _HotkeyModel_Create("^!p", $HOTKEY_ACTION_FILE, $sSpacedPath, '--name "value with spaces"')
    _AssertTrue(_ActionValidator_ValidateRecord($aFile, True), "existing executable path with spaces is valid")
    Local $aPreparedFile = _ActionDispatcher_Prepare($aFile, $aNoTags)
    _AssertTrue(IsArray($aPreparedFile), "path with spaces reaches its fixed route")
    If IsArray($aPreparedFile) Then
        _AssertEqual($sSpacedPath, $aPreparedFile[$HOTKEY_FIELD_TARGET], "path with spaces is preserved")
        _AssertEqual('--name "value with spaces"', $aPreparedFile[$HOTKEY_FIELD_PARAMETERS], "file parameters are preserved exactly")
    EndIf
    FileDelete($sSpacedPath)

    _AssertEqual('"C:\Program Files\Tool App\tool.exe"', _ProcessActions_QuoteArgument("C:\Program Files\Tool App\tool.exe"), "argument quoting preserves spaces")
    _AssertEqual('/d /c echo "hello world" && tool /x', _ProcessActions_BuildCommandArguments('echo "hello world" && tool /x'), "advanced command arguments are exact")
    _AssertEqual("Advanced Command", _HotkeyModel_ActionLabel($HOTKEY_ACTION_COMMAND), "command action is explicitly labeled advanced")
    _AssertTrue(_WindowActions_IsValid("Move to -20,30 & Resize to 800x600"), "valid custom geometry")
    _AssertFalse(_WindowActions_IsValid("Move to 1,2 & Resize to -1x600"), "invalid custom geometry")

    Local $aBadUrl = _HotkeyModel_Create("^!u", $HOTKEY_ACTION_URL, "javascript:alert(1)")
    _AssertFalse(_ActionValidator_ValidateRecord($aBadUrl, False), "invalid URL scheme is rejected")
    Local $aBadParameters = _HotkeyModel_Create("^!n", $HOTKEY_ACTION_FILE, "tool.exe", "first" & @LF & "second")
    _AssertFalse(_ActionValidator_ValidateRecord($aBadParameters, False), "newline in parameters is rejected")
    Local $aMarker = _HotkeyModel_Create("^!m", $HOTKEY_ACTION_FILE, "tool[HkzExe].exe")
    _AssertFalse(_ActionValidator_ValidateRecord($aMarker, False), "embedded legacy marker is rejected")
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
