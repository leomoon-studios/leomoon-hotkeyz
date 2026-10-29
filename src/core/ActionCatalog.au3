#include-once
#include "OpticalDriveModel.au3"

Global Const $ACTION_CATALOG_CUSTOM_WINDOW = "Custom Move and/or Resize"
Global Const $ACTION_CATALOG_WINDOW_ACTIONS = "Close|Minimize|Terminate|Transparency +|Transparency -|Toggle On Top|Take Screenshot|Set Process Priority to Low|Set Process Priority to Below Normal|Set Process Priority to Normal|Set Process Priority to Above Normal|Set Process Priority to High|Set Process Priority to Realtime|Move Center|Move Top Left|Move Top Mid|Move Top Right|Move Bottom Left|Move Bottom Mid|Move Bottom Right|Move to Next Monitor|Move to Previous Monitor|Snap Fullscreen|Snap Top (1x2)|Snap Bottom (1x2)|Snap Left (2x1)|Snap Right (2x1)|Snap Left (3x1)|Snap Mid (3x1)|Snap Right (3x1)|Snap Top Left (2x2)|Snap Top Right (2x2)|Snap Bottom Left (2x2)|Snap Bottom Right (2x2)|Snap Top Left (3x2)|Snap Top Mid (3x2)|Snap Top Right (3x2)|Snap Bottom Left (3x2)|Snap Bottom Mid (3x2)|Snap Bottom Right (3x2)|Toggle Ghost (Advanced)|Generate Random Password (PPP)|Generate Random Password (Letters)|Generate Random Password (Numbers)|Generate Random Password (Letters and Numbers)|Generate Random UUID|Upper Case Selected Text|Lower Case Selected Text|Title Case Selected Text|Reverse Selected Text|MD5 Selected Text|SHA1 Selected Text|SHA-256 Selected Text|SHA-512 Selected Text|Base64 Encode Selected Text|Base64 Decode Selected Text"
Global Const $ACTION_CATALOG_LEGACY_HIGH = "Set Process Priority to Hight"

Func _ActionCatalog_WindowLabels()
    Return $ACTION_CATALOG_WINDOW_ACTIONS & "|Resize 3x2|Hide|" & $ACTION_CATALOG_CUSTOM_WINDOW
EndFunc

Func _ActionCatalog_IsWindowAction($sAction)
    ; These actions were supported by v1.8.12, including imported profiles.
    If $sAction = "Resize 3x2" Or $sAction = "Hide" Then Return True
    Return StringInStr("|" & $ACTION_CATALOG_WINDOW_ACTIONS & "|", "|" & $sAction & "|", 1) > 0 Or $sAction = $ACTION_CATALOG_LEGACY_HIGH
EndFunc

Global $clsid[8][2]
$clsid[0][0] = 'Libraries'
$clsid[0][1] = '::{031E4825-7B94-4DC3-B131-E946B44C8DD5}'
$clsid[1][0] = 'Libraries\Documents'
$clsid[1][1] = '::{031E4825-7B94-4DC3-B131-E946B44C8DD5}\Documents.library-ms'
$clsid[2][0] = 'Libraries\Music'
$clsid[2][1] = '::{031E4825-7B94-4DC3-B131-E946B44C8DD5}\Music.library-ms'
$clsid[3][0] = 'Libraries\Pictures'
$clsid[3][1] = '::{031E4825-7B94-4DC3-B131-E946B44C8DD5}\Pictures.library-ms'
$clsid[4][0] = 'Libraries\Videos'
$clsid[4][1] = '::{031E4825-7B94-4DC3-B131-E946B44C8DD5}\Videos.library-ms'
$clsid[5][0] = 'My Computer'
$clsid[5][1] = '::{20D04FE0-3AEA-1069-A2D8-08002B30309D}'
$clsid[6][0] = 'My Documents'
$clsid[6][1] = '::{450D8FBA-AD25-11D0-98A8-0800361B1103}'
$clsid[7][0] = 'Network'
$clsid[7][1] = '::{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}'
Global $sPaths[27][2]
$sPaths[0][0] = 'Control Panel (Category View)'
$sPaths[0][1] = '::{26EE0668-A00A-44D7-9371-BEB064C98683}'
$sPaths[1][0] = 'Control Panel (Icon View)'
$sPaths[1][1] = '::{21EC2020-3AEA-1069-A2DD-08002B30309D}'
$sPaths[2][0] = 'Windows Settings'
$sPaths[2][1] = 'explorer.exe [Parameters] ms-settings:'
$sPaths[3][0] = 'Fonts Folder'
$sPaths[3][1] = '%Windir%\fonts'
$sPaths[4][0] = 'Network Places'
$sPaths[4][1] = '::{208D2C60-3AEA-1069-A2D7-08002B30309D}'
$sPaths[5][0] = 'Network Connections'
$sPaths[5][1] = '::{7007ACC7-3202-11D1-AAD2-00805FC1270E}'
$sPaths[6][0] = 'Printers And Faxes'
$sPaths[6][1] = '::{2227A280-3AEA-1069-A2DE-08002B30309D}'
$sPaths[7][0] = 'Recycle Bin'
$sPaths[7][1] = '::{645FF040-5081-101B-9F08-00AA002F954E}'
$sPaths[8][0] = 'Empty Recycle Bin'
$sPaths[8][1] = '[HkzExe]Empty Recycle Bin'
$sPaths[9][0] = 'Volume Up'
$sPaths[9][1] = '[HkzSysSnd]Volume Up'
$sPaths[10][0] = 'Volume Down'
$sPaths[10][1] = '[HkzSysSnd]Volume Down'
$sPaths[11][0] = 'Volume Mute'
$sPaths[11][1] = '[HkzSysSnd]Volume Mute'
$sPaths[12][0] = 'Media Play/Pause'
$sPaths[12][1] = '[HkzSysSnd]Media Play Pause'
$sPaths[13][0] = 'Media Next'
$sPaths[13][1] = '[HkzSysSnd]Media Next'
$sPaths[14][0] = 'Media Previous'
$sPaths[14][1] = '[HkzSysSnd]Media Prev'
$sPaths[15][0] = 'Media Stop'
$sPaths[15][1] = '[HkzSysSnd]Media Stop'
$sPaths[16][0] = 'Lock'
$sPaths[16][1] = '[HkzExe]Lock'
$sPaths[17][0] = 'Log Off'
$sPaths[17][1] = '[HkzExe]Log Off'
$sPaths[18][0] = 'Restart'
$sPaths[18][1] = '[HkzExe]Restart'
$sPaths[19][0] = 'Shutdown'
$sPaths[19][1] = '[HkzExe]Shutdown'
$sPaths[20][0] = 'Turn Off Monitors'
$sPaths[20][1] = '[HkzExe]Turn Off Monitors'
$sPaths[21][0] = 'Turn Off Monitors And Lock'
$sPaths[21][1] = '[HkzExe]Turn Off Monitors And Lock'
$sPaths[22][0] = 'Start Screensaver'
$sPaths[22][1] = '[HkzExe]Start Screensaver'
$sPaths[23][0] = 'Start Screensaver And Lock'
$sPaths[23][1] = '[HkzExe]Start Screensaver And Lock'
$sPaths[24][0] = 'Empty Clipboard'
$sPaths[24][1] = '[HkzExe]Empty Clipboard'
$sPaths[25][0] = 'Cycle Playback Device'
$sPaths[25][1] = '[HkzExe]Cycle Playback Device'
$sPaths[26][0] = 'Cycle Recording Device'
$sPaths[26][1] = '[HkzExe]Cycle Recording Device'

Func _ActionCatalog_SpecialLabels()
    Local $sLabels = "", $i
    For $i = 0 To UBound($sPaths, 1) - 1
        If $i Then $sLabels &= "|"
        $sLabels &= $sPaths[$i][0]
    Next
    Return $sLabels & "|" & $OPTICAL_ACTION_OPEN & "|" & $OPTICAL_ACTION_CLOSE & "|" & $OPTICAL_ACTION_TOGGLE
EndFunc
