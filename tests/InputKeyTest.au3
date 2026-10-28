#include "..\src\core\InputKey.au3"
Opt("MustDeclareVars", 1)
Global $g_iCount = 0, $g_iFailures = 0
_Check("^!+#a", 0x41, 15)
_Check("^{F9}", 0x78, 1)
_Check("!{NUMPAD0}", 0x60, 2)
_Check("+{NUMPAD9}", 0x69, 4)
_Check("#{NUMPADSUB}", 0x6D, 8)
_Check("^{PGDN}", 0x22, 1)
Global $aResult = _InputKey_Compile("^{UNKNOWN}")
_Assert(@error <> 0 And Not IsArray($aResult), "unknown key rejected")
$aResult = _InputKey_Compile("a")
_Assert(@error <> 0 And Not IsArray($aResult), "missing modifier rejected")
$aResult = _InputKey_Compile("^{HkzEq}")
_Assert(IsArray($aResult) And $aResult[0] > 0, "equals mapped on current layout")
If $g_iFailures Then Exit 1
ConsoleWrite("PASSED: " & $g_iCount & " key compilation assertions" & @CRLF)
Func _Check($sHotkey, $iVk, $iMask)
    Local $aKey = _InputKey_Compile($sHotkey)
    _Assert(IsArray($aKey), $sHotkey & " compiles")
    If IsArray($aKey) Then _Assert($aKey[0] = $iVk And $aKey[1] = $iMask, $sHotkey & " mapping")
EndFunc
Func _Assert($bOk, $sMessage)
    $g_iCount += 1
    If Not $bOk Then
        $g_iFailures += 1
        ConsoleWrite("FAIL: " & $sMessage & @CRLF)
    EndIf
EndFunc
