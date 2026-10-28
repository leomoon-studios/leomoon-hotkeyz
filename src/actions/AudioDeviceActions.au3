#include-once

#include <WinAPI.au3>

; Adapted from LeoMoon PlaybackSwitch. The policy configuration interface is
; used by Windows audio device switchers but is not a public Core Audio API.
Global Const $AUDIO_FLOW_RENDER = 0
Global Const $AUDIO_FLOW_CAPTURE = 1
Global Const $AUDIO_ROLE_CONSOLE = 0
Global Const $AUDIO_ROLE_MULTIMEDIA = 1
Global Const $AUDIO_ROLE_COMMUNICATIONS = 2
Global Const $AUDIO_ENDPOINT_ID = 0
Global Const $AUDIO_ENDPOINT_NAME = 1

Global Const $AUDIO_DEVICE_ERROR_COM = 1
Global Const $AUDIO_DEVICE_ERROR_ENDPOINTS = 2
Global Const $AUDIO_DEVICE_ERROR_DEFAULT = 3
Global Const $AUDIO_DEVICE_ERROR_POLICY = 4
Global Const $AUDIO_DEVICE_ERROR_PROPERTY = 5
Global Const $AUDIO_DEVICE_ERROR_NO_ENDPOINTS = 6
Global Const $AUDIO_DEVICE_ERROR_INVALID_FLOW = 7

Global Const $g_sAudioEnumeratorClsid = "{BCDE0395-E52F-467C-8E3D-C4579291692E}"
Global Const $g_sAudioEnumeratorIid = "{A95664D2-9614-4F35-A746-DE8DB63617E6}"
Global Const $g_sAudioEnumeratorTag = "EnumAudioEndpoints hresult(dword;dword;ptr*);" & _
        "GetDefaultAudioEndpoint hresult(dword;dword;ptr*);" & _
        "GetDevice hresult(wstr;ptr*);" & _
        "RegisterEndpointNotificationCallback hresult(ptr);" & _
        "UnregisterEndpointNotificationCallback hresult(ptr);"
Global Const $g_sAudioDeviceIid = "{D666063F-1587-4E43-81F1-B948E807363F}"
Global Const $g_sAudioDeviceTag = "Activate hresult(ptr;dword;variant*;ptr*);" & _
        "OpenPropertyStore hresult(dword;ptr*);" & _
        "GetId hresult(ptr*);" & _
        "GetState hresult(dword*);"
Global Const $g_sAudioCollectionIid = "{0BD7A1BE-7A1A-44DB-8397-CC5392387B5E}"
Global Const $g_sAudioCollectionTag = "GetCount hresult(uint*);Item hresult(uint;ptr*)"
Global Const $g_sAudioPropertyStoreIid = "{886d8eeb-8cf2-4446-8d02-cdba1dbdcf99}"
Global Const $g_sAudioPropertyStoreTag = "GetCount hresult(dword*);" & _
        "GetAt hresult(dword;ptr*);" & _
        "GetValue hresult(ptr;variant*);" & _
        "SetValue hresult(ptr;variant);" & _
        "Commit hresult();"
Global Const $g_sAudioPolicyClsid = "{870af99c-171d-4f9e-af0d-e63df40c2bc9}"
Global Const $g_sAudioPolicyIid = "{f8679f50-850a-41cf-9c72-430f290290c8}"
Global Const $g_sAudioPolicyTag = "GetMixFormat hresult(wstr;ptr*);" & _
        "GetDeviceFormat hresult(wstr;int;ptr*);" & _
        "ResetDeviceFormat hresult(wstr);" & _
        "SetDeviceFormat hresult(wstr;ptr;ptr);" & _
        "GetProcessingPeriod hresult(wstr;int;int64*;int64*);" & _
        "SetProcessingPeriod hresult(wstr;int64*);" & _
        "GetShareMode hresult(wstr;ptr);" & _
        "SetShareMode hresult(wstr;ptr);" & _
        "GetPropertyValue hresult(wstr;struct;variant*);" & _
        "SetPropertyValue hresult(wstr;struct;variant*);" & _
        "SetDefaultEndpoint hresult(wstr;int);" & _
        "SetEndpointVisibility hresult(wstr;int);"

Global $g_iAudioDeviceComError = 0

; Callback names are optional test seams. Normal hotkey dispatch uses the built-in helpers.
Func _AudioDeviceActions_Cycle($iFlow, $sEnumerate = "_AudioDeviceActions_Enumerate", $sGetDefault = "_AudioDeviceActions_GetDefaultId", $sSetDefault = "_AudioDeviceActions_SetDefaultId", $sNotify = "_AudioDeviceActions_Notify")
    If $iFlow <> $AUDIO_FLOW_RENDER And $iFlow <> $AUDIO_FLOW_CAPTURE Then Return SetError($AUDIO_DEVICE_ERROR_INVALID_FLOW, 0, "")
    Local $aEndpoints = Call($sEnumerate, $iFlow)
    Local $iError = @error, $iExtended = @extended
    If $iError Then Return SetError($iError, $iExtended, "")
    If Not IsArray($aEndpoints) Then Return SetError($AUDIO_DEVICE_ERROR_NO_ENDPOINTS, 0, "")
    If UBound($aEndpoints, 0) <> 2 Or UBound($aEndpoints, 2) <> 2 Or UBound($aEndpoints, 1) = 0 Then Return SetError($AUDIO_DEVICE_ERROR_ENDPOINTS, 0, "")
    If UBound($aEndpoints, 1) = 1 Then Return $aEndpoints[0][$AUDIO_ENDPOINT_NAME]

    Local $sCurrentId = Call($sGetDefault, $iFlow)
    $iError = @error
    $iExtended = @extended
    If $iError Then Return SetError($iError, $iExtended, "")
    Local $iNext = _AudioDeviceActions_NextIndex($aEndpoints, $sCurrentId)
    Local $sNextId = $aEndpoints[$iNext][$AUDIO_ENDPOINT_ID]
    If Not IsString($sNextId) Or $sNextId = "" Then Return SetError($AUDIO_DEVICE_ERROR_ENDPOINTS, $iNext, "")
    Local $bChanged = Call($sSetDefault, $sNextId)
    $iError = @error
    $iExtended = @extended
    If $iError Then Return SetError($iError, $iExtended, "")
    If Not $bChanged Then Return SetError($AUDIO_DEVICE_ERROR_POLICY, $iNext, "")
    Local $sName = $aEndpoints[$iNext][$AUDIO_ENDPOINT_NAME]
    Call($sNotify, $iFlow, $sName)
    Return $sName
EndFunc

Func _AudioDeviceActions_NextIndex(ByRef $aEndpoints, $sCurrentId)
    Local $i
    For $i = 0 To UBound($aEndpoints, 1) - 1
        If $aEndpoints[$i][$AUDIO_ENDPOINT_ID] = $sCurrentId Then Return Mod($i + 1, UBound($aEndpoints, 1))
    Next
    Return 0
EndFunc

Func _AudioDeviceActions_Notify($iFlow, $sName)
    Local $sTitle = "Playback Device"
    If $iFlow = $AUDIO_FLOW_CAPTURE Then $sTitle = "Recording Device"
    TrayTip($sTitle, $sName, 2, 1)
EndFunc

; Returns a two-column array, or 0 with @error=0 when no devices are active.
Func _AudioDeviceActions_Enumerate($iFlow)
    Local $oErrorHandler = ObjEvent("AutoIt.Error", "_AudioDeviceActions_ComError")
    If Not IsObj($oErrorHandler) Then Return SetError($AUDIO_DEVICE_ERROR_COM, 0, 0)
    $g_iAudioDeviceComError = 0
    Local $oEnumerator = ObjCreateInterface($g_sAudioEnumeratorClsid, $g_sAudioEnumeratorIid, $g_sAudioEnumeratorTag)
    If @error Or Not IsObj($oEnumerator) Then Return SetError($AUDIO_DEVICE_ERROR_COM, 1, 0)
    Local $pCollection = 0
    Local $iResult = $oEnumerator.EnumAudioEndpoints($iFlow, 1, $pCollection)
    If $g_iAudioDeviceComError Or $iResult <> 0 Or Not $pCollection Then Return SetError($AUDIO_DEVICE_ERROR_ENDPOINTS, $iResult, 0)
    Local $oCollection = ObjCreateInterface($pCollection, $g_sAudioCollectionIid, $g_sAudioCollectionTag)
    If @error Or Not IsObj($oCollection) Then Return SetError($AUDIO_DEVICE_ERROR_COM, 2, 0)
    Local $iCount = 0
    $iResult = $oCollection.GetCount($iCount)
    If $g_iAudioDeviceComError Or $iResult <> 0 Then Return SetError($AUDIO_DEVICE_ERROR_ENDPOINTS, $iResult, 0)
    If $iCount = 0 Then Return 0
    Local $aEndpoints[$iCount][2]
    Local $tKey = _AudioDeviceActions_FriendlyNameKey()
    If @error Then Return SetError($AUDIO_DEVICE_ERROR_PROPERTY, 1, 0)
    Local $i, $pDevice, $oDevice, $pStore, $oStore, $sId, $sName
    For $i = 0 To $iCount - 1
        $pDevice = 0
        $iResult = $oCollection.Item($i, $pDevice)
        If $g_iAudioDeviceComError Or $iResult <> 0 Or Not $pDevice Then Return SetError($AUDIO_DEVICE_ERROR_ENDPOINTS, $i, 0)
        $oDevice = ObjCreateInterface($pDevice, $g_sAudioDeviceIid, $g_sAudioDeviceTag)
        If @error Or Not IsObj($oDevice) Then Return SetError($AUDIO_DEVICE_ERROR_COM, 3, 0)
        $sId = _AudioDeviceActions_DeviceId($oDevice)
        If @error Then Return SetError($AUDIO_DEVICE_ERROR_ENDPOINTS, $i, 0)
        $pStore = 0
        $iResult = $oDevice.OpenPropertyStore(0, $pStore)
        If $g_iAudioDeviceComError Or $iResult <> 0 Or Not $pStore Then Return SetError($AUDIO_DEVICE_ERROR_PROPERTY, $i, 0)
        $oStore = ObjCreateInterface($pStore, $g_sAudioPropertyStoreIid, $g_sAudioPropertyStoreTag)
        If @error Or Not IsObj($oStore) Then Return SetError($AUDIO_DEVICE_ERROR_COM, 4, 0)
        $sName = 0
        $iResult = $oStore.GetValue(DllStructGetPtr($tKey), $sName)
        If $g_iAudioDeviceComError Or $iResult <> 0 Or Not IsString($sName) Then Return SetError($AUDIO_DEVICE_ERROR_PROPERTY, $i, 0)
        $aEndpoints[$i][$AUDIO_ENDPOINT_ID] = $sId
        $aEndpoints[$i][$AUDIO_ENDPOINT_NAME] = $sName
    Next
    Return $aEndpoints
EndFunc

Func _AudioDeviceActions_GetDefaultId($iFlow)
    Local $oErrorHandler = ObjEvent("AutoIt.Error", "_AudioDeviceActions_ComError")
    If Not IsObj($oErrorHandler) Then Return SetError($AUDIO_DEVICE_ERROR_COM, 0, "")
    $g_iAudioDeviceComError = 0
    Local $oEnumerator = ObjCreateInterface($g_sAudioEnumeratorClsid, $g_sAudioEnumeratorIid, $g_sAudioEnumeratorTag)
    If @error Or Not IsObj($oEnumerator) Then Return SetError($AUDIO_DEVICE_ERROR_COM, 1, "")
    Local $pDevice = 0
    Local $iResult = $oEnumerator.GetDefaultAudioEndpoint($iFlow, $AUDIO_ROLE_CONSOLE, $pDevice)
    If $g_iAudioDeviceComError Or $iResult <> 0 Or Not $pDevice Then Return SetError($AUDIO_DEVICE_ERROR_DEFAULT, $iResult, "")
    Local $oDevice = ObjCreateInterface($pDevice, $g_sAudioDeviceIid, $g_sAudioDeviceTag)
    If @error Or Not IsObj($oDevice) Then Return SetError($AUDIO_DEVICE_ERROR_COM, 3, "")
    Local $sId = _AudioDeviceActions_DeviceId($oDevice)
    If @error Then Return SetError($AUDIO_DEVICE_ERROR_DEFAULT, @extended, "")
    Return $sId
EndFunc

Func _AudioDeviceActions_SetDefaultId($sId)
    If Not IsString($sId) Or $sId = "" Then Return SetError($AUDIO_DEVICE_ERROR_POLICY, 0, False)
    Local $oErrorHandler = ObjEvent("AutoIt.Error", "_AudioDeviceActions_ComError")
    If Not IsObj($oErrorHandler) Then Return SetError($AUDIO_DEVICE_ERROR_COM, 0, False)
    $g_iAudioDeviceComError = 0
    Local $oPolicy = ObjCreateInterface($g_sAudioPolicyClsid, $g_sAudioPolicyIid, $g_sAudioPolicyTag)
    If @error Or Not IsObj($oPolicy) Then Return SetError($AUDIO_DEVICE_ERROR_COM, 5, False)
    Local $iRole, $iResult
    For $iRole = $AUDIO_ROLE_CONSOLE To $AUDIO_ROLE_COMMUNICATIONS
        $iResult = $oPolicy.SetDefaultEndpoint($sId, $iRole)
        If $g_iAudioDeviceComError Or $iResult <> 0 Then Return SetError($AUDIO_DEVICE_ERROR_POLICY, $iRole, False)
    Next
    Return True
EndFunc

Func _AudioDeviceActions_DeviceId($oDevice)
    Local $pId = 0
    Local $iResult = $oDevice.GetId($pId)
    If $g_iAudioDeviceComError Or $iResult <> 0 Or Not $pId Then Return SetError($AUDIO_DEVICE_ERROR_ENDPOINTS, $iResult, "")
    Local $aLength = DllCall("kernel32.dll", "int", "lstrlenW", "ptr", $pId)
    Local $iCallError = @error
    Local $sId = ""
    If Not $iCallError And IsArray($aLength) And $aLength[0] > 0 Then
        Local $tId = DllStructCreate("wchar ID[" & ($aLength[0] + 1) & "]", $pId)
        $sId = DllStructGetData($tId, "ID")
    EndIf
    _WinAPI_CoTaskMemFree($pId)
    If $sId = "" Then Return SetError($AUDIO_DEVICE_ERROR_ENDPOINTS, $iCallError, "")
    Return $sId
EndFunc

Func _AudioDeviceActions_FriendlyNameKey()
    Local $tKey = DllStructCreate("byte GUID[16];dword PID")
    Local $aResult = DllCall("propsys.dll", "long", "PSPropertyKeyFromString", "wstr", "{a45c254e-df1c-4efd-8020-67d146a850e0} 14", "ptr", DllStructGetPtr($tKey))
    If @error Or Not IsArray($aResult) Then Return SetError($AUDIO_DEVICE_ERROR_PROPERTY, 0, 0)
    If $aResult[0] <> 0 Then Return SetError($AUDIO_DEVICE_ERROR_PROPERTY, $aResult[0], 0)
    Return $tKey
EndFunc

Func _AudioDeviceActions_ComError($oError)
    $g_iAudioDeviceComError = $oError.number
EndFunc
