#include-once
#include <WinAPIConv.au3>

; Windows cleans up these annotations when the associated HWND is destroyed.
Global $g_oAccessibilityProperties = 0

Func _Accessibility_Name($iControl, $sName)
    If Not IsObj($g_oAccessibilityProperties) Then
        ; SetHwndPropStr is the fifth IAccPropServices method after IUnknown.
        Local $sInterface = "Unused1 hresult();Unused2 hresult();Unused3 hresult();Unused4 hresult();SetHwndPropStr hresult(hwnd;dword;dword;struct;wstr);"
        ; On x64 Windows a 16-byte GUID passed by value uses an indirect pointer.
        If @AutoItX64 Then $sInterface = "Unused1 hresult();Unused2 hresult();Unused3 hresult();Unused4 hresult();SetHwndPropStr hresult(hwnd;dword;dword;ptr;wstr);"
        $g_oAccessibilityProperties = ObjCreateInterface("{B5F8350B-0548-48B1-A6EE-88BD00B4A5E7}", "{6E26E776-04F0-495D-80E4-3330352E3169}", $sInterface)
        If Not IsObj($g_oAccessibilityProperties) Then Return False
    EndIf
    Local $tName = _WinAPI_GUIDFromString("{608D3DF8-8128-4AA7-A428-F55E49267291}")
    Local $iResult
    If @AutoItX64 Then
        $iResult = $g_oAccessibilityProperties.SetHwndPropStr(GUICtrlGetHandle($iControl), 0xFFFFFFFC, 0, DllStructGetPtr($tName), $sName)
    Else
        $iResult = $g_oAccessibilityProperties.SetHwndPropStr(GUICtrlGetHandle($iControl), 0xFFFFFFFC, 0, $tName, $sName)
    EndIf
    Return Not @error And $iResult = 0
EndFunc
