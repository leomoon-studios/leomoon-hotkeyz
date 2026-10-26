#include "..\src\core\HotkeyRepository.au3"
#include "..\src\core\AppConstants.au3"
#include "..\src\actions\ActionDispatcher.au3"
#include "..\src\app\ErrorReporter.au3"
#include "..\src\app\HotkeyRegistry.au3"
#include "..\src\gui\HotkeyEditorModel.au3"

Opt("MustDeclareVars", 1)

Global $g_iFailures = 0
Global $g_iAssertions = 0
Global $g_iClipboardRestoreCalls = 0
Global $g_iClipboardWaitCalls = 0
Global $g_bClipboardWriteFails = False
Global $g_bClipboardWaitFails = False
Global $g_sClipboardWritten = ""
Global $g_sUnavailableHotkey = ""
Global $g_aTestBindings[8][2]
Global $g_iTestRegistryDeleteResult = 2
Global $g_iTestRegistryDeleteError = -1
Global $g_iTestRegistryReadError = 0
Global $g_iTestRegistryDeleteCalls = 0
Global $g_iShellCalls = 0

_TestSpecialKeys()
_TestCodecRoundTrips()
_TestTags()
_TestLegacyFixtures()
_TestLegacyWindowActions()
_TestRepositoryRecovery()
_TestActionValidationAndDispatch()
_TestMissingTargetMessages()
_TestGeometry()
_TestWindowsFailurePaths()
_TestClipboardTransactions()
_TestTextAndCrypto()
_TestEditorModel()
_TestUnavailableHotkey()
_TestReapplyHotkeys()
_TestMaintenanceFixtures()
_TestSideEffectBackends()
_TestStartupRegistry()

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
    _AssertEqual("{NUMPADSUB}", _HotkeyCodec_EncodeKey("Numpad Subtract"), "subtract uses native AutoIt key name")
    _AssertEqual("{NUMPADMULT}", _HotkeyCodec_EncodeKey("Numpad Multiply"), "multiply uses native AutoIt key name")
    _AssertEqual("{NUMPADDIV}", _HotkeyCodec_EncodeKey("Numpad Divide"), "divide uses native AutoIt key name")
    Local $aRecovered = _HotkeyCodec_DecodeLegacy("^!{NUMPADSUBTRACT}", "[HkzWM]Transparency -")
    _AssertEqual("^!{NUMPADSUB}", $aRecovered[$HOTKEY_FIELD_HOTKEY], "load repairs saved subtract spelling")
    $aRecovered = _HotkeyCodec_DecodeLegacy("^!{NUMPADMULTIPLY}", "[HkzWM]Take Screenshot")
    _AssertEqual("^!{NUMPADMULT}", $aRecovered[$HOTKEY_FIELD_HOTKEY], "load repairs saved multiply spelling")
    _AssertEqual("^!{=}", _HotkeyCodec_ToNativeHotkey("^!{HkzEq}"), "registration uses native equals key")
    Local $aSavedHotkeys = $aHotkeys
    $aHotkeys = _HotkeyRepository_CreateTable(1)
    _HotkeyRepository_SetRecord($aHotkeys, 1, $aRecovered)
    _AssertEqual(1, _HotkeyRegistry_FindHotkey("!^{NUMPADMULT}"), "callback lookup tolerates modifier order")
    $aHotkeys = $aSavedHotkeys
EndFunc

Func _TestGeometry()
    Local $aNegativeArea = _Geometry_CreateWorkArea(-1920, -100, 0, 980)
    Local $aCurrent = _Geometry_CreateRect(-1700, 20, 800, 600)
    Local $aSnap = _Geometry_CalculateActionRect("Snap Bottom Right (2x2)", $aNegativeArea, $aCurrent)
    _AssertEqual(-960, $aSnap[$WINDOW_RECT_X], "negative-coordinate snap x")
    _AssertEqual(440, $aSnap[$WINDOW_RECT_Y], "negative-coordinate snap y")
    _AssertEqual(960, $aSnap[$WINDOW_RECT_WIDTH], "negative-coordinate snap width")
    _AssertEqual(540, $aSnap[$WINDOW_RECT_HEIGHT], "negative-coordinate snap height")

    Local $aSource = _Geometry_CreateWorkArea(0, 0, 1920, 1080)
    Local $aTarget = _Geometry_CreateWorkArea(-2560, 0, 0, 1440)
    Local $aHalf = _Geometry_CreateRect(960, 0, 960, 1080)
    Local $aMapped = _Geometry_MapRect($aSource, $aTarget, $aHalf)
    _AssertEqual(-1280, $aMapped[$WINDOW_RECT_X], "different-scale monitor transfer x")
    _AssertEqual(1280, $aMapped[$WINDOW_RECT_WIDTH], "different-scale monitor transfer width")
    _AssertEqual(1440, $aMapped[$WINDOW_RECT_HEIGHT], "different-scale monitor transfer height")
EndFunc

Func _TestLegacyWindowActions()
    Local $aLegacy = _HotkeyRepository_Load(@ScriptDir & "\fixtures\legacy-window-actions.ini")
    _AssertTrue(IsArray($aLegacy), "legacy window actions load")
    Local $i, $aRecord
    For $i = 1 To _HotkeyRepository_Count($aLegacy)
        $aRecord = _HotkeyRepository_GetRecord($aLegacy, $i)
        _AssertTrue(_ActionValidator_ValidateRecord($aRecord, False), "legacy window action passes startup validation: " & $aRecord[$HOTKEY_FIELD_TARGET])
        _AssertTrue(StringInStr("|" & _ActionCatalog_WindowLabels() & "|", "|" & $aRecord[$HOTKEY_FIELD_TARGET] & "|") > 0, "legacy action can be selected in editor")
    Next
    Local $aArea = _Geometry_CreateWorkArea(-1920, -100, 1, 981)
    Local $aCurrent = _Geometry_CreateRect(-1700, 20, 800, 600)
    Local $aResized = _Geometry_CalculateActionRect("Resize 3x2", $aArea, $aCurrent)
    _AssertEqual(-1700, $aResized[$WINDOW_RECT_X], "legacy resize preserves x")
    _AssertEqual(20, $aResized[$WINDOW_RECT_Y], "legacy resize preserves y")
    _AssertEqual(640, $aResized[$WINDOW_RECT_WIDTH], "legacy resize floors one third of work width")
    _AssertEqual(540, $aResized[$WINDOW_RECT_HEIGHT], "legacy resize floors half of work height")
    _AssertFalse(_WindowActions_IsValid("Resize 3x2 unexpected"), "legacy compatibility does not allow arbitrary action names")
EndFunc

Func _TestWindowsFailurePaths()
    Local $sCancelled = _WindowActions_NormalizeScreenshotPath("")
    Local $iCancelError = @error
    _AssertEqual("", $sCancelled, "cancelled screenshot has no path")
    _AssertTrue($iCancelError <> 0, "cancelled screenshot reports an error")
    _AssertFalse(_WindowActions_SaveScreenshot("capture.jpg", 1, "_TestCaptureFails", "_TestSaveSucceeds"), "failed screenshot capture is reported")
    _AssertFalse(_WindowActions_SaveScreenshot("capture.jpg", 1, "_TestCaptureSucceeds", "_TestSaveFails"), "failed screenshot save is reported")
    Local $sExplorer = _GetWindowsExplorerPath(0)
    Local $iExplorerError = @error
    _AssertEqual("", $sExplorer, "invalid Explorer window returns no path")
    _AssertTrue($iExplorerError <> 0, "invalid Explorer window reports an error")
    _AssertFalse(_AppError_Report("test failure", 7, 9, False), "error reporter returns failure")
    _AssertTrue(StringInStr($g_sLastApplicationError, "test failure") > 0, "error reporter records context")
EndFunc

Func _TestMissingTargetMessages()
    Local $sMissing = @TempDir & "\HotKeyz-missing-" & @AutoItPID & "-<USERNAME>"
    Local $aFile = _HotkeyModel_Create("#/", $HOTKEY_ACTION_FILE, $sMissing & "\terminal.exe")
    Local $aFolder = _HotkeyModel_Create("^+a", $HOTKEY_ACTION_FOLDER, $sMissing)
    _AssertTrue(_ActionValidator_ValidateRecord($aFile, False), "missing imported file remains valid at startup")
    _AssertTrue(_ActionValidator_ValidateRecord($aFolder, False), "missing imported folder remains valid at startup")
    _AssertFalse(_HotkeyRegistry_ExecuteRecord($aFile, False), "missing file reports a failure")
    _AssertTrue(StringInStr($g_sLastApplicationError, "target file or folder does not exist") > 0, "missing file explains the actual cause")
    _AssertTrue(StringInStr($g_sLastApplicationError, "Win + /") > 0, "missing file identifies shortcut")
    _AssertTrue(StringInStr($g_sLastApplicationError, StringReplace($sMissing, "<USERNAME>", @UserName) & "\terminal.exe") > 0, "missing file shows expanded path")
    _AssertFalse(_HotkeyRegistry_ExecuteRecord($aFolder, False), "missing folder reports a failure")
    _AssertTrue(StringInStr($g_sLastApplicationError, "Ctrl + Shift + A") > 0, "missing folder identifies shortcut")
    _AssertTrue(StringInStr($g_sLastApplicationError, "target file or folder does not exist") > 0, "missing folder explains the actual cause")
    Local $aTagsForTest[1][2] = [["<TEST>", "test"]]
    Local $aCommand = _HotkeyModel_Create("^!a", $HOTKEY_ACTION_FILE, "code")
    Local $aPrepared = _ActionDispatcher_Prepare($aCommand, $aTagsForTest)
    _AssertTrue(IsArray($aPrepared), "bare commands remain eligible for PATH lookup")
    Local $aShellFolder = _HotkeyModel_Create("^!b", $HOTKEY_ACTION_FOLDER, "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}")
    $aPrepared = _ActionDispatcher_Prepare($aShellFolder, $aTagsForTest)
    _AssertTrue(IsArray($aPrepared), "shell namespaces are not mistaken for missing paths")
EndFunc

Func _TestClipboardTransactions()
    _ClipboardTransaction_ConfigureBackend("_TestClipboardSnapshot", "_TestClipboardRestore", "_TestClipboardWrite", "_TestClipboardRead", "_TestClipboardSend", "_TestClipboardWait", "_TestClipboardSequence")
    $g_iClipboardRestoreCalls = 0
    $g_iClipboardWaitCalls = 0
    $g_bClipboardWriteFails = False
    $g_bClipboardWaitFails = False
    _AssertTrue(_ClipboardTransaction_Paste("new text"), "clipboard paste transaction succeeds")
    _AssertEqual(1, $g_iClipboardRestoreCalls, "clipboard is restored after successful paste")
    _AssertEqual(1, $g_iClipboardWaitCalls, "clipboard paste waits before restoration")

    $g_bClipboardWriteFails = True
    _AssertFalse(_ClipboardTransaction_Paste("failure"), "clipboard write failure is reported")
    _AssertEqual(2, $g_iClipboardRestoreCalls, "clipboard is restored after failed paste")

    $g_bClipboardWriteFails = False
    $g_bClipboardWaitFails = True
    _AssertFalse(_ClipboardTransaction_Paste("wait failure"), "clipboard wait failure is reported")
    _AssertEqual(3, $g_iClipboardRestoreCalls, "clipboard is restored after failed paste wait")

    $g_bClipboardWaitFails = False
    _AssertTrue(_ClipboardTransaction_TransformSelection("Upper Case Selected Text"), "selected-text transaction succeeds")
    _AssertEqual("SELECTED TEXT", $g_sClipboardWritten, "selected text is transformed before paste")
    _AssertEqual(4, $g_iClipboardRestoreCalls, "clipboard is restored after selected-text transaction")
    _AssertTrue(_ClipboardTransaction_CanPreserveFormat(50000), "registered non-text clipboard format is preservable")
    _AssertFalse(_ClipboardTransaction_CanPreserveFormat($CF_BITMAP), "handle-based bitmap format is explicitly excluded")
    _ClipboardTransaction_ResetBackend()
EndFunc

Func _TestTextAndCrypto()
    Local $sUnicode = "caf" & ChrW(0x00E9) & " " & ChrW(0x4E16) & ChrW(0x754C)
    Local $sEncoded = _Base64Encode($sUnicode)
    _AssertFalse(@error, "UTF-8 Base64 encoding succeeds")
    _AssertEqual($sUnicode, _Base64Decode($sEncoded), "non-ASCII Base64 round trip")
    Local $sInvalid = _Base64Decode("not base64!")
    Local $iInvalidError = @error
    _AssertEqual("", $sInvalid, "invalid Base64 returns no decoded value")
    _AssertTrue($iInvalidError <> 0, "invalid Base64 reports an error")
    Local $sInvalidUtf8 = _Base64Decode("/w==")
    Local $iInvalidUtf8Error = @error
    _AssertEqual("", $sInvalidUtf8, "invalid UTF-8 Base64 returns no decoded value")
    _AssertTrue($iInvalidUtf8Error <> 0, "invalid UTF-8 Base64 reports an error")

    Local $sUuid = uuid()
    _AssertTrue(StringRegExp($sUuid, "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$") = 1, "UUID has v4 version and RFC variant bits")
    Local $sLetters = _generator("<RAND_LETTERS>")
    Local $sNumbers = _generator("<RAND_NUMBERS>")
    Local $sMixed = _generator("<RAND_LETTERS_NUMBERS>")
    Local $sPpp = _generator("<RAND_PPP>")
    _AssertTrue(StringRegExp($sLetters, "^[A-Za-z]{20}$") = 1, "letters password constraint")
    _AssertTrue(StringRegExp($sNumbers, "^[0-9]{20}$") = 1, "numbers password constraint")
    _AssertTrue(StringRegExp($sMixed, "^[2-9A-Za-z]{20}$") = 1, "mixed password constraint")
    _AssertEqual(20, StringLen($sPpp), "PPP password length constraint")
    _AssertTrue(StringRegExp($sPpp, "^[!#%+2-9:=?@A-HJ-NP-ZA-Za-z]{20}$") = 1, "PPP password character constraint")
    _AssertFalse(StringRegExp($sPpp, "[IOQl]") = 1, "PPP password excludes ambiguous characters")
EndFunc

Func _TestEditorModel()
    Local $aEmpty = _HotkeyRepository_CreateTable(0)
    Local $aUrlValues = _HotkeyEditorModel_CreateValues("!^a", $HOTKEY_ACTION_URL, "https://example.com")
    Local $aUrl = _HotkeyEditorModel_ToRecord($aUrlValues)
    _AssertTrue(IsArray($aUrl), "editor model creates a valid add record")
    _AssertEqual("^!a", $aUrl[$HOTKEY_FIELD_HOTKEY], "editor model canonicalizes modifier order")
    Local $aAdded = _HotkeyEditorModel_Upsert($aEmpty, $aUrl)
    _AssertEqual(1, _HotkeyRepository_Count($aAdded), "editor model adds a record")

    Local $aTextValues = _HotkeyEditorModel_CreateValues("^!b", $HOTKEY_ACTION_TEXT, "replacement")
    Local $aText = _HotkeyEditorModel_ToRecord($aTextValues)
    Local $aEdited = _HotkeyEditorModel_Upsert($aAdded, $aText, 1)
    _AssertEqual(1, _HotkeyRepository_Count($aEdited), "editor model edits without adding a row")
    Local $aEditedRecord = _HotkeyRepository_GetRecord($aEdited, 1)
    _AssertEqual("replacement", $aEditedRecord[$HOTKEY_FIELD_TARGET], "editor model replaces the selected row")
    Local $aCancelled = _HotkeyEditorModel_Cancel($aAdded)
    _AssertTrue(_HotkeyRepository_TablesEqual($aAdded, $aCancelled), "cancel leaves the original editor table unchanged")

    Local $aDuplicate = _HotkeyEditorModel_Upsert($aEdited, $aText)
    _AssertFalse(IsArray($aDuplicate), "duplicate editor hotkey is rejected")
    Local $aDeleted = _HotkeyEditorModel_Delete($aEdited, 1)
    Local $iDeleteSelection = @extended
    _AssertEqual(0, _HotkeyRepository_Count($aDeleted), "editor model deletes the selected row")
    _AssertEqual(0, $iDeleteSelection, "deleting the final row leaves no invalid selection")
    _AssertFalse(IsArray(_HotkeyEditorModel_Delete($aDeleted, 1)), "delete from an empty list is guarded")

    Local $aBadNumberValues = _HotkeyEditorModel_CreateValues("^!c", $HOTKEY_ACTION_WINDOW, $ACTION_CATALOG_CUSTOM_WINDOW, "", 0, True, "1-2", "3")
    _AssertFalse(IsArray(_HotkeyEditorModel_ToRecord($aBadNumberValues)), "invalid custom coordinate is rejected")
    Local $aBadSizeValues = _HotkeyEditorModel_CreateValues("^!c", $HOTKEY_ACTION_WINDOW, $ACTION_CATALOG_CUSTOM_WINDOW, "", 0, False, "", "", True, "0", "600")
    _AssertFalse(IsArray(_HotkeyEditorModel_ToRecord($aBadSizeValues)), "nonpositive custom size is rejected")
    Local $aBadUrlValues = _HotkeyEditorModel_CreateValues("^!u", $HOTKEY_ACTION_URL, "javascript:alert(1)")
    _AssertFalse(IsArray(_HotkeyEditorModel_ToRecord($aBadUrlValues)), "invalid editor URL is rejected")
    _AssertFalse(_HotkeyEditorModel_ValidateToggle("!^b", $aEdited), "main toggle cannot duplicate an action hotkey")
    _AssertTrue(_HotkeyEditorModel_ValidateToggle("^!z", $aEdited), "distinct modified main toggle is valid")
    _AssertFalse(_HotkeyEditorModel_ValidateToggle("^", $aEdited), "modifier without a key is invalid")
    _AssertFalse(_HotkeyEditorModel_ShouldCloseSettings(False, True), "save failure keeps settings open")
    _AssertFalse(_HotkeyEditorModel_ShouldCloseSettings(True, False), "startup decision failure keeps settings open")
    _AssertTrue(_HotkeyEditorModel_ShouldCloseSettings(True, True), "successful save and startup decision close settings")
    _AssertTrue(_HotkeyEditorModel_StartupEnabled(1), "checked startup state enables startup")
    _AssertFalse(_HotkeyEditorModel_StartupEnabled(4), "unchecked startup state disables startup")
    _AssertTrue(_WindowActions_IsValid("Set Process Priority to High"), "canonical priority label reaches the dispatcher")
    _AssertFalse(StringInStr(_ActionCatalog_WindowLabels(), "Hight") > 0, "window action labels omit the legacy typo")
EndFunc

Func _TestUnavailableHotkey()
    Local $aEmpty = _HotkeyRepository_CreateTable(0)
    Local $aValues = _HotkeyEditorModel_CreateValues("^!x", $HOTKEY_ACTION_TEXT, "test")
    Local $aRecord = _HotkeyEditorModel_ToRecord($aValues)
    Local $aNew = _HotkeyEditorModel_Upsert($aEmpty, $aRecord)
    $g_sUnavailableHotkey = "^!x"
    _HotkeyRegistry_ConfigureHotkeyBackend("_TestHotkeySet")
    _AssertFalse(_HotkeyRegistry_ApplyBindings("^!z", $aEmpty, "^!y", $aNew), "unavailable action hotkey aborts registration")
    _HotkeyRegistry_ResetHotkeyBackend()
EndFunc

Func _TestReapplyHotkeys()
    Local $aOld = _HotkeyRepository_CreateTable(2)
    Local $aFirst = _HotkeyModel_Create("^!a", $HOTKEY_ACTION_TEXT, "first")
    Local $aSecond = _HotkeyModel_Create("^!b", $HOTKEY_ACTION_TEXT, "second")
    _HotkeyRepository_SetRecord($aOld, 1, $aFirst)
    _HotkeyRepository_SetRecord($aOld, 2, $aSecond)
    Local $aNew = _HotkeyRepository_CreateTable(2)
    ; Reuse an old action key for the toggle and the old toggle for an action.
    $aFirst[$HOTKEY_FIELD_HOTKEY] = "^!z"
    $aSecond[$HOTKEY_FIELD_HOTKEY] = "^!c"
    _HotkeyRepository_SetRecord($aNew, 1, $aFirst)
    _HotkeyRepository_SetRecord($aNew, 2, $aSecond)
    _HotkeyRegistry_ConfigureHotkeyBackend("_TestBindingBackend")

    _TestResetBindings()
    _HotkeyRegistry_RestoreBindings("^!z", $aOld)
    _AssertTrue(_HotkeyRegistry_ApplyBindings("^!z", $aOld, "^!a", $aNew), "release all old keys before swapping toggle and action shortcuts")
    _AssertEqual("_toggle", _TestBindingHandler("^!a"), "old action key becomes toggle")
    _AssertEqual("HotKeyPressed", _TestBindingHandler("^!z"), "old toggle key becomes action")
    _AssertEqual("", _TestBindingHandler("^!b"), "removed action key is released")

    _TestResetBindings()
    _HotkeyRegistry_SetTable($aOld, "HotKeyPressed")
    _AssertTrue(_HotkeyRegistry_ApplyBindings("^!z", $aOld, "^!a", $aNew), "save works when old toggle was never registered")
    _AssertEqual("HotKeyPressed", _TestBindingHandler("^!c"), "new action registered after missing toggle cleanup")

    _TestResetBindings()
    _HotkeyRegistry_TrySet("^!z", "_toggle")
    _AssertTrue(_HotkeyRegistry_ApplyBindings("^!z", $aOld, "^!a", $aNew), "save works when action hotkeys were disabled")
    _AssertEqual("_toggle", _TestBindingHandler("^!a"), "new toggle registered after disabled action cleanup")
    _AssertEqual("HotKeyPressed", _TestBindingHandler("^!c"), "new action registered after disabled action cleanup")

    _TestResetBindings()
    _HotkeyRegistry_RestoreBindings("^!z", $aOld)
    _HotkeyRegistry_TrySet("^!a")
    _AssertTrue(_HotkeyRegistry_ApplyBindings("^!z", $aOld, "^!a", $aNew), "cleanup continues past an already released action")
    _AssertEqual("", _TestBindingHandler("^!b"), "later old actions are still released")

    _TestResetBindings()
    _HotkeyRegistry_RestoreBindings("^!z", $aOld)
    $g_sUnavailableHotkey = "^!c"
    Local $bApplied = _HotkeyRegistry_ApplyBindings("^!z", $aOld, "^!a", $aNew)
    Local $iFailedRow = @extended
    _AssertFalse($bApplied, "real action conflict rejects changes")
    _AssertEqual(2, $iFailedRow, "conflict identifies the failed action row")
    _AssertEqual("_toggle", _TestBindingHandler("^!z"), "failed save restores old toggle")
    _AssertEqual("HotKeyPressed", _TestBindingHandler("^!a"), "failed save restores first old action")
    _AssertEqual("HotKeyPressed", _TestBindingHandler("^!b"), "failed save restores second old action")
    _AssertEqual("", _TestBindingHandler("^!c"), "failed save leaves conflicting action unregistered")

    _TestResetBindings()
    _HotkeyRegistry_RestoreBindings("^!z", $aOld)
    $g_sUnavailableHotkey = "^!a"
    _AssertFalse(_HotkeyRegistry_ApplyBindings("^!z", $aOld, "^!a", $aNew), "real toggle conflict rejects changes")
    _AssertEqual("_toggle", _TestBindingHandler("^!z"), "toggle conflict restores old toggle")
    _AssertEqual("HotKeyPressed", _TestBindingHandler("^!b"), "rollback continues past an unavailable old action")

    _TestResetBindings()
    $g_sUnavailableHotkey = "^!z"
    _AssertFalse(_HotkeyRegistry_RestoreBindings("^!z", $aOld), "restore reports unavailable old toggle")
    _AssertEqual("HotKeyPressed", _TestBindingHandler("^!a"), "restore continues after unavailable old toggle")
    _AssertEqual("HotKeyPressed", _TestBindingHandler("^!b"), "restore attempts every old action")
    _HotkeyRegistry_ResetHotkeyBackend()
    _TestResetBindings()
EndFunc

Func _TestResetBindings()
    Local $aEmpty[8][2]
    $g_aTestBindings = $aEmpty
    $g_sUnavailableHotkey = ""
EndFunc

Func _TestBindingHandler($sHotkey)
    Local $i
    For $i = 0 To UBound($g_aTestBindings) - 1
        If $g_aTestBindings[$i][0] = $sHotkey Then Return $g_aTestBindings[$i][1]
    Next
    Return ""
EndFunc

Func _TestBindingBackend($sHotkey, $sHandler)
    Local $i
    If $sHandler <> "" And $sHotkey = $g_sUnavailableHotkey Then Return False
    For $i = 0 To UBound($g_aTestBindings) - 1
        If $g_aTestBindings[$i][0] <> $sHotkey Then ContinueLoop
        If $sHandler = "" Then
            ; Match AutoIt: releasing a shortcut we do not own returns 0.
            If $g_aTestBindings[$i][1] = "" Then Return False
        ElseIf $g_aTestBindings[$i][1] <> "" Then
            ; Require release before rebinding to exercise the save ordering.
            Return False
        EndIf
        $g_aTestBindings[$i][1] = $sHandler
        Return True
    Next
    If $sHandler = "" Then Return False
    For $i = 0 To UBound($g_aTestBindings) - 1
        If $g_aTestBindings[$i][0] <> "" Then ContinueLoop
        $g_aTestBindings[$i][0] = $sHotkey
        $g_aTestBindings[$i][1] = $sHandler
        Return True
    Next
    Return False
EndFunc

Func _TestMaintenanceFixtures()
    Local $aEmpty = _HotkeyRepository_Load(@ScriptDir & "\fixtures\empty.ini")
    _AssertFalse(@error, "empty fixture loads")
    _AssertEqual(0, _HotkeyRepository_Count($aEmpty), "empty fixture has no hotkeys")
    Local $aValid = _HotkeyRepository_Load(@ScriptDir & "\fixtures\valid.ini")
    _AssertFalse(@error, "valid fixture loads")
    _AssertEqual(3, _HotkeyRepository_Count($aValid), "valid fixture entry count")
    Local $aUnicode = _HotkeyRepository_Load(@ScriptDir & "\fixtures\unicode.ini")
    _AssertFalse(@error, "Unicode fixture loads")
    Local $aUnicodeRecord = _HotkeyRepository_GetRecord($aUnicode, 1)
    _AssertTrue(StringInStr($aUnicodeRecord[$HOTKEY_FIELD_TARGET], ChrW(0x4E16) & ChrW(0x754C)) > 0, "Unicode fixture preserves non-ASCII text")
    _AssertEqual("ABC", _TextActions_Transform("Upper Case Selected Text", "abc"), "uppercase text transform")
    _AssertEqual("cba", _TextActions_Transform("Reverse Selected Text", "abc"), "reverse text transform")
EndFunc

Func _TestSideEffectBackends()
    $g_iShellCalls = 0
    _ProcessActions_ConfigureShellBackend("_TestShellExecute")
    _AssertFalse(_ProcessActions_ShellExecute("missing.exe"), "shell execution failure is testable without launching a process")
    _AssertEqual(1, $g_iShellCalls, "shell test double receives the request")
    _ProcessActions_ResetShellBackend()

    _HotkeyRegistry_ConfigureRegistryBackend("_TestRegistryRead", "_TestRegistryWrite", "_TestRegistryDelete")
    _AssertTrue(_HotkeyRegistry_IsStartupEnabled(), "registry read test double controls startup state")
    _AssertFalse(_HotkeyRegistry_SetStartupEnabled(True), "registry write failure is testable without persistent changes")
    _AssertFalse(_HotkeyRegistry_SetStartupEnabled(False), "registry delete failure is testable without persistent changes")
    _HotkeyRegistry_ResetRegistryBackend()

    _WindowActions_ConfigureBackends("_TestMonitorEnum", "_TestMonitorInfo", "_TestComCreate", "_TestLayeredAttributes", "_TestPathFromUrl")
    Local $aMonitors = _monitors()
    _AssertFalse(IsArray($aMonitors), "monitor enumeration failure is testable")
    Local $aMonitorArea = _getMonitorArea(1)
    _AssertFalse(IsArray($aMonitorArea), "monitor information failure is testable")
    _AssertFalse(IsObj(_WindowActions_CreateComObject("Shell.Application")), "COM creation failure is testable")
    Local $iTransparency
    _AssertFalse(_WinGetTrans(1, $iTransparency), "DLL call failure is testable")
    _WindowActions_ResetBackends()
EndFunc

Func _TestShellExecute($sTarget, $sParameters, $sWorkingDirectory, $sVerb, $iShowFlag)
    #forceref $sTarget, $sParameters, $sWorkingDirectory, $sVerb, $iShowFlag
    $g_iShellCalls += 1
    Return False
EndFunc

Func _TestRegistryRead($sKey, $sValue)
    #forceref $sKey, $sValue
    Return SetError($g_iTestRegistryReadError, 0, "configured")
EndFunc

Func _TestRegistryWrite($sKey, $sValue, $sType, $sData)
    #forceref $sKey, $sValue, $sType, $sData
    Return False
EndFunc

Func _TestRegistryDelete($sKey, $sValue)
    #forceref $sKey, $sValue
    $g_iTestRegistryDeleteCalls += 1
    Return SetError($g_iTestRegistryDeleteError, 0, $g_iTestRegistryDeleteResult)
EndFunc

Func _TestStartupRegistry()
    ; Read only: verify the native wrapper preserves the missing-value error.
    Local $sMissingValue = "HotKeyz-Test-Missing-" & @AutoItPID & "-" & TimerInit()
    _HotkeyRegistry_RegRead($APP_STARTUP_REGISTRY_KEY, $sMissingValue)
    Local $iReadError = @error
    _AssertTrue($iReadError <> 0, "native registry wrapper preserves missing-value error")

    _HotkeyRegistry_ConfigureRegistryBackend("_TestRegistryRead", "_TestRegistryWrite", "_TestRegistryDelete")
    $g_iTestRegistryReadError = -1
    $g_iTestRegistryDeleteCalls = 0
    _AssertTrue(_HotkeyRegistry_SetStartupEnabled(False), "missing startup value needs no deletion")
    _AssertTrue(_HotkeyRegistry_SetStartupEnabled(False), "repeated save of missing startup value succeeds")
    _AssertEqual(0, $g_iTestRegistryDeleteCalls, "absent startup value never requests registry write access")
    $g_iTestRegistryReadError = 0
    $g_iTestRegistryDeleteResult = 0
    $g_iTestRegistryDeleteError = 0
    _AssertTrue(_HotkeyRegistry_SetStartupEnabled(False), "unchecked startup saves when entry is already absent")
    _AssertTrue(_HotkeyRegistry_SetStartupEnabled(False), "repeated unchecked startup saves succeed")
    $g_iTestRegistryDeleteResult = 1
    _AssertTrue(_HotkeyRegistry_SetStartupEnabled(False), "unchecked startup removes an existing entry")
    $g_iTestRegistryDeleteResult = 2
    $g_iTestRegistryDeleteError = -1
    Local $bResult = _HotkeyRegistry_SetStartupEnabled(False)
    Local $iError = @error, $iDetail = @extended
    _AssertFalse($bResult, "native RegDelete failure code 2 is rejected")
    _AssertEqual(2, $iError, "startup delete failure reports operation")
    _AssertEqual(-1, $iDetail, "startup delete failure retains native error detail")
    $g_iTestRegistryDeleteError = 0
    _AssertFalse(_HotkeyRegistry_SetStartupEnabled(False), "delete failure is rejected even without an error flag")
    $g_iTestRegistryDeleteError = -1
    _HotkeyRegistry_ResetRegistryBackend()
EndFunc

Func _TestMonitorEnum()
    Return SetError(1, 0, 0)
EndFunc

Func _TestMonitorInfo($hMonitor)
    #forceref $hMonitor
    Return SetError(1, 0, 0)
EndFunc

Func _TestComCreate($sProgramId)
    #forceref $sProgramId
    Return 0
EndFunc

Func _TestLayeredAttributes($hWnd, $iColor, $iTransparency)
    #forceref $hWnd, $iColor, $iTransparency
    Return 0
EndFunc

Func _TestPathFromUrl($sUrl)
    #forceref $sUrl
    Return 0
EndFunc

Func _TestHotkeySet($sHotkey, $sHandler)
    If $sHandler <> "" And $sHotkey = $g_sUnavailableHotkey Then Return False
    Return True
EndFunc

Func _TestCaptureFails($sUnused, $hWnd)
    #forceref $sUnused, $hWnd
    Return 0
EndFunc

Func _TestCaptureSucceeds($sUnused, $hWnd)
    #forceref $sUnused, $hWnd
    Return 1
EndFunc

Func _TestSaveFails($sPath, $hImage)
    #forceref $sPath, $hImage
    Return False
EndFunc

Func _TestSaveSucceeds($sPath, $hImage)
    #forceref $sPath, $hImage
    Return True
EndFunc

Func _TestClipboardSnapshot()
    Local $aSnapshot[3][2]
    $aSnapshot[0][0] = 2
    $aSnapshot[1][0] = $CF_UNICODETEXT
    $aSnapshot[1][1] = "original text"
    $aSnapshot[2][0] = 50000
    $aSnapshot[2][1] = Binary("0x010203")
    Return $aSnapshot
EndFunc

Func _TestClipboardRestore(ByRef $aSnapshot)
    $g_iClipboardRestoreCalls += 1
    Return UBound($aSnapshot, 1) = 3 And $aSnapshot[2][1] = Binary("0x010203")
EndFunc

Func _TestClipboardWrite($sText)
    If $g_bClipboardWriteFails Then Return False
    $g_sClipboardWritten = $sText
    Return True
EndFunc

Func _TestClipboardRead()
    Return "selected text"
EndFunc

Func _TestClipboardSend($sKeys)
    Return $sKeys = "^c" Or $sKeys = "^v"
EndFunc

Func _TestClipboardWait($iSequence, $bRequireChange)
    #forceref $iSequence, $bRequireChange
    $g_iClipboardWaitCalls += 1
    Return Not $g_bClipboardWaitFails
EndFunc

Func _TestClipboardSequence()
    Return 100
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
