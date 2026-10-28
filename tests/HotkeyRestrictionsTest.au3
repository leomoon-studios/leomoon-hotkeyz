#include "..\src\core\HotkeyRepository.au3"
#include "..\src\gui\HotkeyEditorModel.au3"
#include "..\src\actions\ActionDispatcher.au3"

Opt("MustDeclareVars", 1)
Global $g_iFailures = 0, $g_iAssertions = 0
Global $sIni = @TempDir & "\hotkeyz-restrictions-" & @AutoItPID & ".ini"
Global $sBackup = $sIni & ".bak"
OnAutoItExitRegister("_RestrictionsCleanup")

Global $aLegacy = _HotkeyRepository_Load(@ScriptDir & "\fixtures\legacy-v1.8.12.ini")
_Check(IsArray($aLegacy), "legacy profile loads")
Global $i, $j, $aRecord
For $i = 1 To _HotkeyRepository_Count($aLegacy)
    $aRecord = _HotkeyRepository_GetRecord($aLegacy, $i)
    _Check(Not _HotkeyModel_HasRestrictions($aRecord), "legacy record defaults to unrestricted")
Next

Global $aValues = _HotkeyEditorModel_CreateValues("^!+#a", $HOTKEY_ACTION_TEXT, "Test " & ChrW(0x4E16) & " <USERNAME>")
$aValues[$EDITOR_VALUE_CTRL_SIDE] = $HOTKEY_SIDE_LEFT
$aValues[$EDITOR_VALUE_ALT_SIDE] = $HOTKEY_SIDE_RIGHT
$aValues[$EDITOR_VALUE_SHIFT_SIDE] = $HOTKEY_SIDE_LEFT
$aValues[$EDITOR_VALUE_WIN_SIDE] = $HOTKEY_SIDE_RIGHT
$aValues[$EDITOR_VALUE_CAPS_LOCK] = $HOTKEY_LOCK_ON
$aValues[$EDITOR_VALUE_NUM_LOCK] = $HOTKEY_LOCK_OFF
$aValues[$EDITOR_VALUE_SCROLL_LOCK] = $HOTKEY_LOCK_ON
$aRecord = _HotkeyEditorModel_ToRecord($aValues)
_Check(IsArray($aRecord), "editor model accepts mixed sides and conditions")
If Not IsArray($aRecord) Then Exit 1
$aRecord[$HOTKEY_FIELD_TARGET] = "Test " & ChrW(0x4E16) & " literal [HkzRestrictedV1] and <USERNAME>"
_Check(_HotkeyCodec_EncodeRestrictions($aRecord) = "1,2,1,2,1,2,1", "metadata codec retains all selections")
Global $aTagsForTest[1][2] = [["<USERNAME>", "tester"]]
Global $aPrepared = _ActionDispatcher_Prepare($aRecord, $aTagsForTest)
_Check(Not IsArray($aPrepared), "restricted actions fail closed before runtime filtering exists")
Global $aTable = _HotkeyRepository_CreateTable(2)
_Check(_HotkeyRepository_SetRecord($aTable, 1, $aRecord), "insert restricted record")
Global $aUnrestricted = _HotkeyModel_Create("^!b", $HOTKEY_ACTION_TEXT, "plain")
_Check(_HotkeyRepository_SetRecord($aTable, 2, $aUnrestricted), "insert unrestricted record")
_Check(_HotkeyRepository_Save($sIni, $aTable), "save new restricted profile")
Global $aLoaded = _HotkeyRepository_Load($sIni)
_Check(IsArray($aLoaded), "reload restricted profile")
If IsArray($aLoaded) Then _Check(_HotkeyRepository_TablesEqual($aTable, $aLoaded), "all fields and literal text round trip")
_Check(IniRead($sIni, "HotkeyRestrictions", "Version", "") = "1", "metadata version recorded")
_Check(StringLeft(IniRead($sIni, "Hotkeys", "^!+#a", ""), StringLen($HOTKEY_CODEC_RESTRICTED)) = $HOTKEY_CODEC_RESTRICTED, "restricted action carries compatibility guard")
Global $aOldDecoder = _HotkeyCodec_DecodeLegacy("^!+#a", IniRead($sIni, "Hotkeys", "^!+#a", ""))
_Check(Not IsArray($aOldDecoder), "old-style decoder refuses guarded action")
Global $hOriginal = FileOpen($sIni, $FO_READ + $FO_BINARY), $bBefore = FileRead($hOriginal)
FileClose($hOriginal)
$aLoaded = _HotkeyRepository_Load($sIni)
$hOriginal = FileOpen($sIni, $FO_READ + $FO_BINARY)
_Check(FileRead($hOriginal) = $bBefore, "loading does not rewrite source")
FileClose($hOriginal)
_Check(_HotkeyRepository_Save($sIni, $aTable), "second save replaces existing profile")
$hOriginal = FileOpen($sBackup, $FO_READ + $FO_BINARY)
_Check($hOriginal <> -1, "save retains backup")
If $hOriginal <> -1 Then
    _Check(FileRead($hOriginal) = $bBefore, "backup retains previous profile bytes")
    FileClose($hOriginal)
EndIf

Global $aDuplicate = _HotkeyRepository_CreateTable(2)
_HotkeyRepository_SetRecord($aDuplicate, 1, $aRecord)
$aUnrestricted[$HOTKEY_FIELD_HOTKEY] = "!^+#a"
_HotkeyRepository_SetRecord($aDuplicate, 2, $aUnrestricted)
_Check(Not _HotkeyRepository_Save($sIni, $aDuplicate), "duplicate generic combination rejected")
$aLoaded = _HotkeyRepository_Load($sIni)
_Check(IsArray($aLoaded) And _HotkeyRepository_TablesEqual($aTable, $aLoaded), "failed save preserves previous profile")

Global $aInvalid = _HotkeyModel_Create("^a", $HOTKEY_ACTION_TEXT, "test")
$aInvalid[$HOTKEY_FIELD_ALT_SIDE] = $HOTKEY_SIDE_RIGHT
_Check(Not _HotkeyModel_IsValid($aInvalid), "side without matching modifier rejected")
$aInvalid[$HOTKEY_FIELD_ALT_SIDE] = 0
$aInvalid[$HOTKEY_FIELD_CAPS_LOCK] = 3
_Check(Not _HotkeyModel_IsValid($aInvalid), "invalid lock state rejected")
$aInvalid[$HOTKEY_FIELD_CAPS_LOCK] = 0
_Check(Not _HotkeyCodec_DecodeRestrictions($aInvalid, "1,0,0,0,0,0,9"), "malformed metadata rejected")

IniWrite($sIni, "HotkeyRestrictions", "Version", "2")
$aLoaded = _HotkeyRepository_Load($sIni)
_Check(Not IsArray($aLoaded), "unknown metadata version rejected")
_Check(Not _HotkeyRepository_Save($sIni, $aTable), "unknown metadata version cannot be overwritten")
_Check(IniRead($sIni, "HotkeyRestrictions", "Version", "") = "2", "failed save preserves newer version")
IniWrite($sIni, "HotkeyRestrictions", "Version", "1")
IniWrite($sIni, "HotkeyRestrictions", "^!+#a", "1,2,1,2,1,2,9")
$aLoaded = _HotkeyRepository_Load($sIni)
_Check(Not IsArray($aLoaded), "malformed persisted restrictions rejected")
IniWrite($sIni, "HotkeyRestrictions", "^!+#a", "1,2,1,2,1,2,1")
IniWrite($sIni, "Hotkeys", "^!+#a", "[HkzSndTxt]unmarked")
$aLoaded = _HotkeyRepository_Load($sIni)
_Check(Not IsArray($aLoaded), "unmarked action with restriction metadata rejected")
IniWrite($sIni, "Hotkeys", "^!+#a", $HOTKEY_CODEC_RESTRICTED)
IniWrite($sIni, "HotkeyRestrictions", "^!z", "1,0,0,0,0,0,0")
$aLoaded = _HotkeyRepository_Load($sIni)
_Check(Not IsArray($aLoaded), "orphan restriction metadata rejected")
IniDelete($sIni, "HotkeyRestrictions", "^!z")
IniDelete($sIni, "HotkeyRestrictedActions", "^!+#a")
$aLoaded = _HotkeyRepository_Load($sIni)
_Check(Not IsArray($aLoaded), "missing restricted action rejected")

FileDelete($sIni)
Global $aEquals = _HotkeyModel_Create("^!{=}", $HOTKEY_ACTION_TEXT, "equals")
$aEquals[$HOTKEY_FIELD_CTRL_SIDE] = $HOTKEY_SIDE_RIGHT
Global $aEqualsTable = _HotkeyRepository_CreateTable(1)
_HotkeyRepository_SetRecord($aEqualsTable, 1, $aEquals)
_Check(_HotkeyRepository_Save($sIni, $aEqualsTable), "save restricted equals-key shortcut")
$aLoaded = _HotkeyRepository_Load($sIni)
_Check(IsArray($aLoaded) And _HotkeyRepository_TablesEqual($aEqualsTable, $aLoaded), "equals-key shortcut and conditions round trip")

If $g_iFailures Then
    ConsoleWrite("FAILED: " & $g_iFailures & " of " & $g_iAssertions & " assertions" & @CRLF)
    Exit 1
EndIf
ConsoleWrite("PASSED: " & $g_iAssertions & " restriction model and profile assertions" & @CRLF)
Exit 0

Func _Check($bCondition, $sMessage)
    $g_iAssertions += 1
    If $bCondition Then Return
    $g_iFailures += 1
    ConsoleWrite("FAIL: " & $sMessage & @CRLF)
EndFunc

Func _RestrictionsCleanup()
    FileDelete($sIni)
    FileDelete($sBackup)
    FileDelete($sIni & ".tmp")
EndFunc
