#include "..\src\core\HotkeyRepository.au3"
#include "..\src\gui\HotkeyEditorModel.au3"
#include "..\src\actions\ActionDispatcher.au3"
#include "..\src\core\AppConstants.au3"
#include "..\src\app\HotkeyRegistry.au3"

Opt("MustDeclareVars", 1)
Global $g_iFailures = 0, $g_iAssertions = 0
Global $g_sRegisteredKeys = ""
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

Global $sRuntimeIni = $sIni & ".runtime"
Global $aRuntimeTable = _HotkeyRepository_CreateTable(2)
Global $aRuntimeRestricted = _HotkeyModel_Create("^!a", $HOTKEY_ACTION_TEXT, "restricted")
$aRuntimeRestricted[$HOTKEY_FIELD_CAPS_LOCK] = $HOTKEY_LOCK_ON
Global $aRuntimeNormal = _HotkeyModel_Create("^!b", $HOTKEY_ACTION_TEXT, "normal")
_HotkeyRepository_SetRecord($aRuntimeTable, 1, $aRuntimeRestricted)
_HotkeyRepository_SetRecord($aRuntimeTable, 2, $aRuntimeNormal)
_Check(_HotkeyRepository_Save($sRuntimeIni, $aRuntimeTable), "prepare mixed runtime profile")
_HotkeyRegistry_ConfigureHotkeyBackend("_RestrictionsMockSet")
$g_sRegisteredKeys = ""
_Check(_iniToApply($sRuntimeIni), "startup accepts profiles containing inactive restrictions")
_Check($g_sRegisteredKeys = "^!b|", "startup registers only unrestricted shortcut")
_Check(_HotkeyRepository_Count($aHotkeys) = 1, "runtime table contains only registered shortcut")
$g_sRegisteredKeys = ""
Global $aEmpty = _HotkeyRepository_CreateTable(0)
_Check(_HotkeyRegistry_ApplyBindings("", $aEmpty, "^!z", $aRuntimeTable), "apply mixed restricted and unrestricted bindings")
_Check($g_sRegisteredKeys = "^!z|^!b|", "apply never registers restricted shortcut")
_HotkeyRegistry_ResetHotkeyBackend()
FileDelete($sRuntimeIni)
FileDelete($sRuntimeIni & ".bak")

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

Func _RestrictionsMockSet($sHotkey, $sHandler)
    If $sHandler <> "" Then $g_sRegisteredKeys &= $sHotkey & "|"
    Return True
EndFunc

Func _RestrictionsCleanup()
    FileDelete($sIni)
    FileDelete($sBackup)
    FileDelete($sIni & ".tmp")
    FileDelete($sIni & ".runtime")
    FileDelete($sIni & ".runtime.bak")
    FileDelete($sIni & ".runtime.tmp")
EndFunc
