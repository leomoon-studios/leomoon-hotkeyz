;~ #NoTrayIcon
;~ #RequireAdmin

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_Icon_Add=resources\main.ico
#AutoIt3Wrapper_Res_Icon_Add=resources\disabled.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

;#pragma compile(UPX, False)
;#pragma compile(x64, False)
#pragma compile(Out, ..\build\LeoMoon HotKeyz.exe)
#pragma compile(Icon, resources\main.ico)
#pragma compile(Compression, 9)
#pragma compile(Comments, This program is freeware.)
#pragma compile(ProductName, LeoMoon HotKeyz)
#pragma compile(FileDescription, LeoMoon HotKeyz)
#pragma compile(FileVersion, 1.8.5.0)
#pragma compile(LegalCopyright, Amin Babaeipanah)
#pragma compile(CompanyName, LeoMoon Studios Inc.)
#pragma compile(LegalTrademarks, LeoMoon Studios Inc.)
#pragma compile(ProductVersion, 1.8.5.0)

#include <Math.au3>
#include <String.au3>
#include <Constants.au3>
#include <StaticConstants.au3>
#include <Misc.au3>
#include <MsgBoxConstants.au3>
#include <WinAPISys.au3>
#include <resources\ExtMsgBox.au3>
#include <Date.au3>
#include <Process.au3>
#include <WinAPIFiles.au3>
#include <ScreenCapture.au3>
#include <WinAPIGdi.au3>
#include <Clipboard.au3>
#include <Inet.au3>
;gui includes
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiComboBox.au3>
#include <GuiListView.au3>
#include <ListViewConstants.au3>

;TODO
;   Add new keys:
;       {LALT}
;       {RALT}
;       {LCTRL}
;       {RCTRL}
;       {LSHIFT}
;       {RSHIFT}
;       {LWIN}
;       {RWIN}
;   Add conditions:
;       Caps Lock state
;       Num Lock state
;       Scroll Lock state
;   Add only one instance checkbox [HkzOptOne]

;global vars
Global $title = 'LeoMoon HotKeyz'
Global $ver = '1.8.5'
Global $enabled = False
Global $winVis = False
Global $aHotkeys
Global $ini = @ScriptDir&'\'&$title&'.ini'
;global gui vars
Global $mainGui, $saveBtn, $startupCbox, $cancelBtn, $ctrlCbox, $altCbox, $shiftCbox, $winCbox, $keyDown, $ListView1
Global $editGui, $ctrlEditCbox, $altEditCbox, $shiftEditCbox, $winEditCbox, $keyEditDown, $okEditBtn, $cancelEditBtn, $specialRdo, $specialDown, $adminCbox, $oneCbox
Global $windowRdo, $windowDown, $moveCbox, $xLbl, $movexInp, $yLbl, $moveyInp, $resizeCbox, $wLbl, $resizewInp, $hLbl, $resizehInp
Global $folderRdo, $folderInp, $folderBrowseBtn
Global $fileRdo, $cmdCbox, $fileInp, $fileBrowseBtn, $fileParamLbl, $fileParamInp
Global $urlRdo, $urlDown, $urlInp
Global $txtRdo, $txtEdit
Global $clsid[8][2]
;window management vars
Global $hWnd, $wpos[3], $csiz
Global $xf = 0
Global $yf = 0
Global $isTop = False
Global $isGhost = False

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
Global $sPaths[24][2]
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
$sPaths[21][0] = 'Start Screensaver'
$sPaths[21][1] = '[HkzExe]Start Screensaver'
$sPaths[22][0] = 'Start Screensaver And Lock'
$sPaths[22][1] = '[HkzExe]Start Screensaver And Lock'
$sPaths[23][0] = 'Empty Clipboard'
$sPaths[23][1] = '[HkzExe]Empty Clipboard'

If @OSArch <> 'X86' Then _WinAPI_Wow64EnableWow64FsRedirection(False)

AutoItSetOption("ExpandEnvStrings", 1)
Opt('TrayMenuMode',3)
Opt("TrayOnEventMode",1)
Opt('TrayAutoPause',0)
Opt("GUIOnEventMode", 1)
Opt("GUICloseOnESC", 0)

_ExtMsgBoxSet(0, 0, -1, -1, 9, "Tahoma")

If _Singleton($title, 1) == 0 Then
	_ExtMsgBox(48, 'OK', 'Oops!', $title&' is currently running.'&@CRLF, 0)
	Exit
EndIf

_iniCheck($ini)

TraySetClick(8)

;setting up menu
TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE, '_toggle')
$aboutTray = TrayCreateItem($title&' '&$ver)
TrayItemSetState(-1,$TRAY_DISABLE)
TrayCreateItem('')
$enableTray = TrayCreateItem('Enable '&$title)
TrayItemSetOnEvent(-1, "_toggle")
TrayItemSetState(-1,$TRAY_CHECKED)
TrayCreateItem("")
$settingsTray = TrayCreateItem('Settings...')
TrayItemSetOnEvent(-1, "_mainGui")
TrayCreateItem('')
$leomoonSiteTray = TrayCreateItem("Visit LeoMoon Studios website")
TrayItemSetOnEvent(-1, "_web")
TrayCreateItem('')
$exitTray = TrayCreateItem('Exit')
TrayItemSetOnEvent(-1, "_exit")
_readHotkey($ini, 'Options', 'Main', $enableTray, 'Enable LeoMoon HotKeyz', '_toggle', '^#,') ;apply main hotkey
_iniToApply($ini)
;~ TraySetState()
TraySetToolTip($title&" is enabled.")

While 1
    Sleep(100)
WEnd

;##########################################################
;########## FUNCTIONS #####################################
;##########################################################
Func _mainGui()
    ;~ $mainGui = GUICreate("Hotkey Settings", 386, 242, -1, -1) ;close and minimize
    ;~ $mainGui = GUICreate("Hotkey Settings", 386, 242, -1, -1, BitOR($WS_SYSMENU,$WS_POPUP)) ;frame only
    If $winVis == False Then
        $mainGui = GUICreate($title&" Settings", 682, 666, -1, -1, $WS_SYSMENU)
        GUISetFont(9, 400, 0, "Tahoma")
        $optionsGrp = GUICtrlCreateGroup("Startup", 8, 8, 658, 57)
        $startupCbox = GUICtrlCreateCheckbox("Start with Windows", 17, 32, 289, 17)
        GUICtrlCreateGroup("", -99, -99, 1, 1)
        $hotkeyGrp = GUICtrlCreateGroup("HotKeyz main hotkey", 8, 72, 658, 57)
        $ctrlCbox = GUICtrlCreateCheckbox("Ctrl", 17, 96, 97, 17)
        $altCbox = GUICtrlCreateCheckbox("Alt", 136, 96, 97, 17)
        $shiftCbox = GUICtrlCreateCheckbox("Shift", 256, 96, 97, 17)
        $winCbox = GUICtrlCreateCheckbox("Win", 376, 96, 97, 17)
        $keyDown = GUICtrlCreateCombo("", 497, 94, 159, 25, BitOR($GUI_SS_DEFAULT_COMBO,$CBS_SIMPLE))
        GUICtrlSetData(-1, "Escape|F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|`|1|2|3|4|5|6|7|8|9|0|-|=|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|[|]|\|;|"&Chr(39)&"|,|.|/|Space|Backspace|Up|Down|Left|Right|Print Screen key|Pause key|Insert|Delete|Home|End|Page Up|Page Down|Numpad 1|Numpad 2|Numpad 3|Numpad 4|Numpad 5|Numpad 6|Numpad 7|Numpad 8|Numpad 9|Numpad 0|Numpad Dot|Numpad Divide|Numpad Multiply|Numpad Subtract|Numpad Add")
        GUICtrlCreateGroup("", -99, -99, 1, 1)
        $customHokeysGrp = GUICtrlCreateGroup("Edit hotkeys", 8, 136, 658, 450)
        $addBtn = GUICtrlCreateButton("Add New", 16, 160, 209, 33)
        $editBtn = GUICtrlCreateButton("Edit Selected", 232, 160, 209, 33)
        $delBtn = GUICtrlCreateButton("Delete Selected", 448, 160, 209, 33)
        $ListView1 = GUICtrlCreateListView("", 17, 201, 639, 375, BitOR($GUI_SS_DEFAULT_LISTVIEW,$WS_HSCROLL,$WS_VSCROLL), BitOR($WS_EX_CLIENTEDGE,$LVS_EX_FULLROWSELECT))
        GUICtrlCreateGroup("", -99, -99, 1, 1)
        $cancelBtn = GUICtrlCreateButton("Cancel", 449, 592, 209, 33)
        $saveBtn = GUICtrlCreateButton("Save", 16, 592, 209, 33)
        ;edit ui
        GUISetIcon(@ScriptFullPath, 201)
        GUICtrlSetOnEvent($ListView1, '_sort')
        GUICtrlSetOnEvent($addBtn, "_addBtn")
        GUICtrlSetOnEvent($editBtn, "_editBtn")
        GUICtrlSetOnEvent($delBtn, "_delBtn")
        GUICtrlSetOnEvent($cancelBtn, "_guiDel")
        GUICtrlSetOnEvent($saveBtn, '_saveBtn')
        GUISetOnEvent($GUI_EVENT_CLOSE, "_guiDel", $mainGui)
        _GUICtrlListView_AddColumn($ListView1, 'Type')
        _GUICtrlListView_AddColumn($ListView1, 'Hotkey')
        _GUICtrlListView_AddColumn($ListView1, 'Item')
        _GUICtrlListView_AddColumn($ListView1, 'Options')
        _iniToGui($ini) ;set gui from ini file
        GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
        _GUICtrlListView_RegisterSortCallBack($ListView1)
        GUISetState(@SW_SHOW)
        WinActivate($mainGui)
        $winVis = True
    Else
        WinActivate($mainGui)
    EndIf
EndFunc

Func WM_NOTIFY($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg, $iwParam
    Local $hWndFrom, $iIDFrom, $iCode, $tNMHDR, $hWndListView, $tInfo
    $hWndListView = $ListView1
    If Not IsHWnd($ListView1) Then $hWndListView = GUICtrlGetHandle($ListView1)
    $tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
    $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
    $iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
    $iCode = DllStructGetData($tNMHDR, "Code")
    Switch $hWndFrom
    Case $hWndListView
        If $iCode = $NM_DBLCLK Then
            _editBtn()
            ;~ ConsoleWrite(_GUICtrlListView_GetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 1)&@LF)
            ;~ ConsoleWrite(_GUICtrlListView_GetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 2)&@LF)
        EndIf
    EndSwitch
    Return $GUI_RUNDEFMSG
EndFunc

Func _editGui($name, $buttonName)
    ;edit gui
    $editGui = GUICreate($name, 418, 706, -1, -1, $WS_EX_TOOLWINDOW, $WS_EX_MDICHILD, $mainGui)
    GUISetFont(9, 400, 0, "Tahoma")
    $actionEditGrp = GUICtrlCreateGroup("Action", 8, 8, 395, 554)
    $fileRdo = GUICtrlCreateRadio("Run a program or open a file", 17, 32, 185, 17)
    $fileInp = GUICtrlCreateInput("", 17, 58, 279, 22)
    $fileBrowseBtn = GUICtrlCreateButton("Browse File", 304, 56, 89, 25)
    $fileParamLbl = GUICtrlCreateLabel("Parameters (Optional)", 16, 92, 124, 18)
    $fileParamInp = GUICtrlCreateInput("", 145, 88, 247, 22)
    $adminCbox = GUICtrlCreateCheckbox("Run as admin", 17, 121, 113, 17)
    $oneCbox = GUICtrlCreateCheckbox("Singleton", 152, 121, 113, 17)
    $cmdCbox = GUICtrlCreateCheckbox("Batch command", 281, 120, 113, 17)
    $folderRdo = GUICtrlCreateRadio("Open a folder", 17, 152, 369, 17)
    $folderInp = GUICtrlCreateInput("", 17, 178, 271, 22)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $folderBrowseBtn = GUICtrlCreateButton("Browse Folder", 296, 176, 89, 25)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $specialRdo = GUICtrlCreateRadio("Run a system action", 17, 216, 369, 17)
    $specialDown = GUICtrlCreateCombo("", 17, 242, 367, 25, BitOR($CBS_DROPDOWNLIST,$WS_VSCROLL))
    GUICtrlSetData(-1, "Control Panel (Category View)|Control Panel (Icon View)|Windows Settings|Fonts Folder|Network Places|Network Connections|Printers and Faxes|Recycle Bin|Empty Recycle Bin|Empty Clipboard|Volume Up|Volume Down|Volume Mute|Media Play/Pause|Media Next|Media Previous|Media Stop|Turn Off Monitors|Start Screensaver|Start Screensaver And Lock|Lock|Log Off|Restart|Shutdown")
    GUICtrlSetState(-1, $GUI_DISABLE)
    $windowRdo = GUICtrlCreateRadio("Run actions on active window", 16, 280, 369, 17)
    $windowDown = GUICtrlCreateCombo("", 17, 306, 367, 25, BitOR($CBS_DROPDOWNLIST,$WS_VSCROLL))
    GUICtrlSetData(-1, "Close|Minimize|Terminate|Transparency +|Transparency -|Toggle On Top|Take Screenshot|Move Center|Move Top Left|Move Top Mid|Move Top Right|Move Bottom Left|Move Bottom Mid|Move Bottom Right|Move to Next Monitor|Move to Previous Monitor|Snap Fullscreen|Snap Top (1x2)|Snap Bottom (1x2)|Snap Left (2x1)|Snap Right (2x1)|Snap Left (3x1)|Snap Mid (3x1)|Snap Right (3x1)|Snap Top Left (2x2)|Snap Top Right (2x2)|Snap Bottom Left (2x2)|Snap Bottom Right (2x2)|Snap Top Left (3x2)|Snap Top Mid (3x2)|Snap Top Right (3x2)|Snap Bottom Left (3x2)|Snap Bottom Mid (3x2)|Snap Bottom Right (3x2)|Set Process Priority to Low|Set Process Priority to Below Normal|Set Process Priority to Normal|Set Process Priority to Above Normal|Set Process Priority to Hight|Set Process Priority to Realtime|Toggle Ghost (Advanced)|Custom Move and/or Resize")
    GUICtrlSetState(-1, $GUI_DISABLE)
    $moveCbox = GUICtrlCreateCheckbox("Move active window", 17, 336, 177, 17)
    GUICtrlSetState(-1, $GUI_CHECKED)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $xLbl = GUICtrlCreateLabel("X:", 18, 362, 15, 18)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $movexInp = GUICtrlCreateInput("0", 41, 360, 55, 22, $ES_NUMBER)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $yLbl = GUICtrlCreateLabel("Y:", 106, 362, 16, 18)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $moveyInp = GUICtrlCreateInput("0", 129, 360, 55, 22, $ES_NUMBER)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $resizeCbox = GUICtrlCreateCheckbox("Resize active window", 217, 336, 169, 17)
    GUICtrlSetState(-1, $GUI_CHECKED)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $wLbl = GUICtrlCreateLabel("W:", 218, 362, 20, 18)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $resizewInp = GUICtrlCreateInput("800", 241, 360, 55, 22, $ES_NUMBER)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $hLbl = GUICtrlCreateLabel("H:", 306, 362, 16, 18)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $resizehInp = GUICtrlCreateInput("600", 329, 360, 55, 22, $ES_NUMBER)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $urlRdo = GUICtrlCreateRadio("Open a URL (URL will open with the default browser)", 17, 400, 369, 17)
    $urlDown = GUICtrlCreateCombo("", 17, 426, 79, 25, BitOR($CBS_DROPDOWNLIST,$CBS_AUTOHSCROLL))
    GUICtrlSetData(-1, "https://|http://|ftp://", "https://")
    GUICtrlSetState(-1, $GUI_DISABLE)
    $urlInp = GUICtrlCreateInput("leomoon.com", 105, 426, 279, 22)
    GUICtrlSetState(-1, $GUI_DISABLE)
    $txtRdo = GUICtrlCreateRadio("Paste text into active window", 17, 464, 353, 17)
    $txtEdit = GUICtrlCreateEdit("", 17, 489, 367, 63, BitOR($ES_AUTOVSCROLL,$ES_WANTRETURN,$WS_VSCROLL))
    GUICtrlSetState(-1, $GUI_DISABLE)
    GUICtrlCreateGroup("", -99, -99, 1, 1)
    $hotkeyEditGrp = GUICtrlCreateGroup("Assign a hotkey", 8, 568, 395, 58)
    $ctrlEditCbox = GUICtrlCreateCheckbox("Ctrl", 17, 592, 57, 17)
    $altEditCbox = GUICtrlCreateCheckbox("Alt", 80, 592, 57, 17)
    $shiftEditCbox = GUICtrlCreateCheckbox("Shift", 144, 592, 57, 17)
    $winEditCbox = GUICtrlCreateCheckbox("Win", 208, 592, 57, 17)
    $keyEditDown = GUICtrlCreateCombo("", 273, 590, 119, 25, BitOR($GUI_SS_DEFAULT_COMBO,$CBS_SIMPLE))
    GUICtrlSetData(-1, "Escape|F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|`|1|2|3|4|5|6|7|8|9|0|-|=|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|[|]|\|;|"&Chr(39)&"|,|.|/|Space|Backspace|Up|Down|Left|Right|Print Screen key|Pause key|Insert|Delete|Home|End|Page Up|Page Down|Numpad 1|Numpad 2|Numpad 3|Numpad 4|Numpad 5|Numpad 6|Numpad 7|Numpad 8|Numpad 9|Numpad 0|Numpad Dot|Numpad Divide|Numpad Multiply|Numpad Subtract|Numpad Add")
    GUICtrlCreateGroup("", -99, -99, 1, 1)
    $cancelEditBtn = GUICtrlCreateButton("Cancel", 209, 632, 193, 33)
    $okEditBtn = GUICtrlCreateButton("OK", 8, 632, 193, 33)
    ;other settings
    GUISetIcon(@ScriptFullPath, 201)
    GUICtrlSetOnEvent($folderRdo, "_folderRdo")
    GUICtrlSetOnEvent($cmdCbox, "_cmdCbox")
    GUICtrlSetTip($adminCbox, 'Run program as administrator.', 'Run as admin', 1)
    GUICtrlSetTip($oneCbox, 'Run only one instance.'&@CR& _
                            ''&@CR& _
                            'This gets the program file name and runs the program only if'&@CR& _
                            'there are no process running with that name.', 'Singleton', 1)
    GUICtrlSetTip($cmdCbox, 'Enter batch command in the input field and it will get executed in a hidden command prompt.'&@CR& _
                            ''&@CR& _
                            'Examples:'&@CR& _
                            'net stop "Service Name" && net start "Service Name"'&@CR& _
                            'RunDll32.exe shell32.dll,Control_RunDLL mmsys.cpl,,0'&@CR& _
                            'START "" "C:\Program Files (x86)\VMware\VMware Workstation\vmrun" -T ws start "C:\VMs\Virtual.vmx"', 'For Advanced Users', 1)
    GUICtrlSetOnEvent($folderBrowseBtn, "_folderBrowse")
    GUICtrlSetOnEvent($fileRdo, "_fileRdo")
    GUICtrlSetOnEvent($fileBrowseBtn, "_fileBrowse")
    GUICtrlSetOnEvent($specialRdo, "_specialRdo")
    _GUICtrlComboBox_SetCurSel($specialDown, 0)
    GUICtrlSetOnEvent($windowRdo, "_windowRdo")
    GUICtrlSetOnEvent($windowDown, "_windowDown")
    _GUICtrlComboBox_SetCurSel($windowDown, 0)
    GUICtrlSetOnEvent($moveCbox, "_moveCbox")
    GUICtrlSetOnEvent($resizeCbox, "_resizeCbox")
    GUICtrlSetOnEvent($urlRdo, "_urlRdo")
    GUICtrlSetOnEvent($txtRdo, "_txtRdo")
    GUICtrlSetTip($txtEdit, "<HOUR> will paste the current hour."&@LF& _
                "<MINUTE> will paste the current minute."&@LF& _
                "<SECOND> will paste the current second."&@LF& _
                "<YEAR> will paste the current 4 digit year."&@LF& _
                "<MONTHNAME> will paste the name of the current month."&@LF& _
                "<MONTHNUMBER> will paste the number of the current month."&@LF& _
                "<DAYNAME> will paste the name of the current day."&@LF& _
                "<DAYNUMBER> will paste the current day of the month.", "Predefined Tags", 1)
    GUICtrlSetOnEvent($cancelEditBtn, "_hideChild")
    ;center child window
    $mpos = WinGetPos($mainGui)
    $cpos = WinGetPos($editGui)
    WinMove($editGui, '', $mpos[0]+($mpos[2]/2)-($cpos[2]/2), $mpos[1]+($mpos[3]/2)-($cpos[3]/2))
    Local $aAccelKeys[1][2] = [["{ESC}", $cancelEditBtn]]
    GUISetAccelerators($aAccelKeys)
    WinActivate($editGui)
EndFunc

Func HotKeyPressed()
    For $x = 1 To UBound($aHotkeys)-1
        If @HotKeyPressed == StringReplace($aHotkeys[$x][0], '{HkzEq}', '{=}') Then
            ;~ ConsoleWrite($hkzparam)
            $hkzoptadmin = ''
            $hkzoptone = False
            $hkzcmd = $aHotkeys[$x][1]
            $hkzcmd = StringReplace($hkzcmd, '[HkzEq]', '=') ;replace HkzEq with real equal sign before applying hotkeys
            If StringInStr($hkzcmd, '[HkzOptAdmin]') Then
                $hkzoptadmin = 'runas'
                $hkzcmd = StringReplace($hkzcmd, '[HkzOptAdmin]', '')
            EndIf
            If StringInStr($hkzcmd, '[HkzOptOne]') Then
                $hkzoptone = True
                $hkzcmd = StringReplace($hkzcmd, '[HkzOptOne]', '')
            EndIf
            If StringInStr($hkzcmd, '[HkzSysSnd]') Then ;execute special volume and media tasks
                If _security($sPaths, StringReplace($hkzcmd, '[HkzSysSnd]', '')) Then Send('{'&StringUpper(StringReplace(StringReplace($hkzcmd, '[HkzSysSnd]', ''), ' ', '_'))&'}')
            ElseIf StringInStr($hkzcmd, '[HkzCmd]') Then ;run special dos commands
                ;~ _RunDos(StringReplace($hkzcmd, '[HkzCmd]', '')) ;dont use _rundos. it waits until process if finished!
                ShellExecute(@ComSpec, " /k "&StringReplace($hkzcmd, '[HkzCmd]', ''), '', $hkzoptadmin, @SW_HIDE)
            ElseIf StringInStr($hkzcmd, '[HkzExe]') Then ;execute commands as is
                If _security($sPaths, StringReplace($hkzcmd, '[HkzExe]', '')) Then Execute('_'&StringReplace(StringReplace($hkzcmd, '[HkzExe]', ''), ' ', '')&'()')
            ElseIf StringInStr($hkzcmd, '[HkzWM]') Then ;window manager
                ;parse cmd: x,y,width,height,center,opacity,top
                $hkzcmd = StringStripWS(StringReplace($hkzcmd, '[HkzWM]', ''),7)
                $hWnd = WinGetHandle("[ACTIVE]")
                If _isReal($hWnd) Then ;if is a real window
                    ;pos, size
                    Local $anim = 1
                    Local $area = _getMonitorArea(_WinAPI_MonitorFromWindow($hWnd))
                    Local $areaWidth = _Max($area[0], $area[1]) - _Min($area[0], $area[1])
                    Local $areaHeight = _Max($area[2], $area[3]) - _Min($area[2], $area[3])
                    ;define
                    Select
                        Case StringInStr($hkzcmd, 'Move to ') Or StringInStr($hkzcmd, 'Resize to ') And Not StringInStr($hkzcmd, 'Monitor')
                            If StringInStr($hkzcmd, ' & ') Then
                                $moveresize = StringSplit(StringReplace(StringReplace($hkzcmd, 'Move to ', ''), 'Resize to ', ''), ' & ', 1)
                                $move = StringSplit($moveresize[1], ',')
                                $resize = StringSplit($moveresize[2], 'x')
                                If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                                _typeCheck($hWnd)
                                If IsArray($move) And $move[0] == 2 And IsArray($resize) And $resize[0] == 2 Then WinMove($hWnd, '', $move[1], $move[2], $resize[1]+$xf, $resize[2]+$yf, $anim)
                            ElseIf StringInStr($hkzcmd, ',') Then
                                $move = StringSplit(StringReplace($hkzcmd, 'Move to ', ''), ',')
                                If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                                _typeCheck($hWnd)
                                If IsArray($move) And $move[0] == 2 Then WinMove($hWnd, '', $move[1], $move[2], Default, Default, $anim)
                            ElseIf StringInStr($hkzcmd, 'x') Then
                                $resize = StringSplit(StringReplace($hkzcmd, 'Resize to ', ''), 'x')
                                If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                                _typeCheck($hWnd)
                                If IsArray($resize) And $resize[0] == 2 Then WinMove($hWnd, '', Default, Default, $resize[1]+$xf, $resize[2]+$yf, $anim)
                            EndIf
                        Case $hkzcmd == 'Move to Next Monitor'
                            _moveToMonitor($hWnd, _monitors(), True)
                        Case $hkzcmd == 'Move to Previous Monitor'
                            _moveToMonitor($hWnd, _monitors(), False)
                        Case $hkzcmd == 'Move Center'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', (($area[0]+($areaWidth/2))-($wpos[2]/2)), ((($areaHeight/2)+$area[2])-($wpos[3]/2)+($yf/2)), Default, Default, $anim)
                        Case $hkzcmd == 'Move Top Left'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2], Default, Default, $anim)
                        Case $hkzcmd == 'Move Top Mid'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', (($areaWidth/2)+$area[0])-($wpos[2]/2), $area[2], Default, Default, $anim)
                        Case $hkzcmd == 'Move Top Right'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[1]-$wpos[2]+($xf/2), $area[2], Default, Default, $anim)
                        Case $hkzcmd == 'Move Bottom Left'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), ($area[2]+$areaHeight)-$wpos[3]+($yf), Default, Default, $anim)
                        Case $hkzcmd == 'Move Bottom Mid'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', (($areaWidth/2)+$area[0])-($wpos[2]/2), ($area[2]+$areaHeight)-$wpos[3]+($yf), Default, Default, $anim)
                        Case $hkzcmd == 'Move Bottom Right'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[1]-$wpos[2]+($xf/2), ($area[2]+$areaHeight)-$wpos[3]+($yf), Default, Default, $anim)
                        Case $hkzcmd == 'Snap Fullscreen'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2], $areaWidth+$xf, $areaHeight+$yf, $anim)
                        Case $hkzcmd == 'Snap Top (1x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2], $areaWidth+$xf, ($areaHeight/2)+$yf, $anim)
                        Case $hkzcmd == 'Snap Bottom (1x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2]+($areaHeight/2), $areaWidth+$xf, ($areaHeight/2)+$yf, $anim)
                        Case $hkzcmd == 'Snap Left (2x1)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2], ($areaWidth/2)+$xf, $areaHeight+$yf, $anim)
                        Case $hkzcmd == 'Snap Right (2x1)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', ($area[0]+($areaWidth/2))-($xf/2), $area[2], ($areaWidth/2)+$xf, $areaHeight+$yf, $anim)
                        Case $hkzcmd == 'Snap Left (3x1)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2], ($areaWidth/3)+$xf, $areaHeight+$yf, $anim)
                        Case $hkzcmd == 'Snap Mid (3x1)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', Default, Default, ($areaWidth/3)+$xf, $areaHeight+$yf, $anim)
                            $wpos = WinGetPos($hWnd)
                            WinMove($hWnd, '', (($areaWidth/2)+$area[0])-($wpos[2]/2), $area[2], Default, Default, $anim)
                        Case $hkzcmd == 'Snap Right (3x1)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', Default, Default, ($areaWidth/3)+$xf, $areaHeight+$yf, $anim)
                            $wpos = WinGetPos($hWnd)
                            WinMove($hWnd, '', $area[1]-$wpos[2]+($xf/2), $area[2], Default, Default, $anim)
                        Case $hkzcmd == 'Snap Top Left (2x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2], ($areaWidth/2)+$xf, ($areaHeight/2)+$yf, $anim)
                        Case $hkzcmd == 'Snap Top Right (2x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', ($area[0]+($areaWidth/2))-($xf/2), $area[2], ($areaWidth/2)+$xf, ($areaHeight/2)+$yf, $anim)
                        Case $hkzcmd == 'Snap Bottom Left (2x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $areaHeight/2, ($areaWidth/2)+$xf, ($areaHeight/2)+$yf, $anim)
                        Case $hkzcmd == 'Snap Bottom Right (2x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', ($area[0]+($areaWidth/2))-($xf/2), $areaHeight/2, ($areaWidth/2)+$xf, ($areaHeight/2)+$yf, $anim)
                        Case $hkzcmd == 'Snap Top Left (3x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), $area[2], ($areaWidth/3)+$xf, ($areaHeight/2)+$yf, $anim)
                        Case $hkzcmd == 'Snap Top Mid (3x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', Default, Default, ($areaWidth/3)+$xf, ($areaHeight/2)+$yf, $anim)
                            $wpos = WinGetPos($hWnd)
                            WinMove($hWnd, '', (($areaWidth/2)+$area[0])-($wpos[2]/2), $area[2], Default, Default, $anim)
                        Case $hkzcmd == 'Snap Top Right (3x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', Default, Default, ($areaWidth/3)+$xf, ($areaHeight/2)+$yf, $anim)
                            $wpos = WinGetPos($hWnd)
                            WinMove($hWnd, '', $area[1]-$wpos[2]+($xf/2), $area[2], Default, Default, $anim)
                        Case $hkzcmd == 'Snap Bottom Left (3x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', Default, Default, ($areaWidth/3)+$xf, ($areaHeight/2)+$yf, $anim)
                            $wpos = WinGetPos($hWnd)
                            WinMove($hWnd, '', $area[0]-($xf/2), ($area[2]+$areaHeight)-$wpos[3]+($yf), Default, Default, $anim)
                        Case $hkzcmd == 'Snap Bottom Mid (3x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', Default, Default, ($areaWidth/3)+$xf, ($areaHeight/2)+$yf, $anim)
                            $wpos = WinGetPos($hWnd)
                            WinMove($hWnd, '', (($areaWidth/2)+$area[0])-($wpos[2]/2), ($area[2]+$areaHeight)-$wpos[3]+($yf), Default, Default, $anim)
                        Case $hkzcmd == 'Snap Bottom Right (3x2)'
                            If BitAND(WinGetState($hWnd), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            WinMove($hWnd, '', Default, Default, ($areaWidth/3)+$xf, ($areaHeight/2)+$yf, $anim)
                            $wpos = WinGetPos($hWnd)
                            WinMove($hWnd, '', $area[1]-$wpos[2]+($xf/2), ($area[2]+$areaHeight)-$wpos[3]+($yf), Default, Default, $anim)
                        Case $hkzcmd == 'Set Process Priority to Low'
                            _setPriority($hWnd, 0)
                        Case $hkzcmd == 'Set Process Priority to Below Normal'
                            _setPriority($hWnd, 1)
                        Case $hkzcmd == 'Set Process Priority to Normal'
                            _setPriority($hWnd, 2)
                        Case $hkzcmd == 'Set Process Priority to Above Normal'
                            _setPriority($hWnd, 3)
                        Case $hkzcmd == 'Set Process Priority to Hight'
                            _setPriority($hWnd, 4)
                        Case $hkzcmd == 'Set Process Priority to Realtime'
                            _setPriority($hWnd, 5)
                        Case $hkzcmd == 'Close'
                            WinClose($hWnd)
                        Case $hkzcmd == 'Minimize'
                            WinSetState($hWnd, '', @SW_MINIMIZE)
                        Case $hkzcmd == 'Terminate'
                            WinKill($hWnd)
                        Case $hkzcmd == 'Transparency +'
                            _transPlus($hWnd)
                        Case $hkzcmd == 'Transparency -'
                            _transMinus($hWnd)
                        Case $hkzcmd == 'Toggle On Top'
                            _topToggle($hWnd)
                        Case $hkzcmd == 'Take Screenshot'
                            _shot($hWnd)
                        Case $hkzcmd == 'Toggle Ghost (Advanced)'
                            _ghostToggle($hWnd)
                        Case $hkzcmd == 'Resize 3x2'
                            If BitAND(WinGetState(WinGetHandle($hWnd)), 32) Then WinSetState($hWnd, '', @SW_RESTORE)
                            _typeCheck($hWnd)
                            ;flooring to eliminate .33
                            WinMove($hWnd, '', Default, Default, Floor(($areaWidth/3)+$xf), Floor(($areaHeight/2)+$yf), $anim)
                        Case $hkzcmd == 'Hide'
                            WinSetState($hWnd, '', @SW_HIDE)
                    EndSelect
                    ;~ WinActivate($hWnd)
                EndIf
            ElseIf StringInStr($hkzcmd, '[HkzSndTxt]') Then ;paste text to active window
                Local $oldClip = ClipGet()
                $hkzcmd = StringReplace($hkzcmd, '[HkzSndTxt]', '')
                $hkzcmd = StringReplace($hkzcmd, '<HOUR>', @HOUR)
                $hkzcmd = StringReplace($hkzcmd, '<MINUTE>', @MIN)
                $hkzcmd = StringReplace($hkzcmd, '<SECOND>', @SEC)
                $hkzcmd = StringReplace($hkzcmd, '<YEAR>', @YEAR)
                $hkzcmd = StringReplace($hkzcmd, '<MONTHNAME>', _DateToMonth(@MON, 2))
                $hkzcmd = StringReplace($hkzcmd, '<MONTHNUMBER>', @MON)
                $hkzcmd = StringReplace($hkzcmd, '<DAYNAME>', _DateDayOfWeek(@WDAY))
                $hkzcmd = StringReplace($hkzcmd, '<DAYNUMBER>', @MDAY)
                $hkzcmd = StringReplace($hkzcmd, '<COMPUTERNAME>', @ComputerName)
                $hkzcmd = StringReplace($hkzcmd, '<USERNAME>', @UserName)
                $hkzcmd = StringReplace($hkzcmd, '<WANIP>', _GetIP())
                $hkzcmd = StringReplace($hkzcmd, '[HkzNL]', @LF)
                ClipPut($hkzcmd) ;insert text
                Send('^v')
                ClipPut($oldClip)
            Else ;execute program or file
                Local $hkzparam = ''
                If StringInStr($hkzcmd, '[HkzParam]') Then
                    $hkzsplit = StringSplit($hkzcmd, '[HkzParam]', 1)
                    If IsArray($hkzsplit) Then
                        $hkzcmd = $hkzsplit[1]
                        If $hkzsplit[0] == 2 Then $hkzparam = StringStripWS($hkzsplit[2], 7)
                    EndIf
                EndIf
                $hkzcmd = StringReplace($hkzcmd, '<USERNAME>', @UserName)
                If ($hkzoptone And Not ProcessExists(StringRegExpReplace($hkzcmd, "^.*\\", ""))) Or Not $hkzoptone Then
                    If $hkzparam <> '' Then
                        If StringInStr($hkzparam, '<GetActiveWindowsExplorerPath>') Then
                            Local $paramPath = _GetWindowsExplorerPath(WinGetHandle("[ACTIVE]"))
                            $hkzparam = StringReplace($hkzparam, '<GetActiveWindowsExplorerPath>', $paramPath)
                            If FileExists($paramPath) Then ;check if Windows explorer path is real
                                ShellExecute($hkzcmd, $hkzparam, '', $hkzoptadmin, @SW_HIDE) ;program with <GetActiveWindowsExplorerPath> parameter
                            Else
                                ShellExecute($hkzcmd, '', '', $hkzoptadmin) ;program with failed <GetActiveWindowsExplorerPath> parameter
                            EndIf
                        Else
                            ShellExecute($hkzcmd, $hkzparam, '', $hkzoptadmin, @SW_HIDE) ;program with parameters
                        EndIf
                    Else
                        ShellExecute($hkzcmd, '', '', $hkzoptadmin) ;regular program with no parameters
                    EndIf
                ;~ ElseIf $hkzoptone And ProcessExists(StringRegExpReplace($hkzcmd, "^.*\\", "")) Then ;tell program already running
                    ;~ _ExtMsgBox(48, 'OK', 'LeoMoon HotKeyz Singleton!', 'This'&'"'&$hkzcmd&'" is already running.'&@CRLF, 0)
                EndIf
            EndIf
        EndIf
	Next
EndFunc

Func _security($arr, $str)
    For $i = 0 To Ubound($arr, 1)-1
        If $arr[$i][0] == $str Then
            Return True
            ExitLoop
        EndIf
    Next
EndFunc

Func _StartScreensaver()
    ;~ _WinAPI_Wow64EnableWow64FsRedirection(False)
    Run('ssText3d.scr /s')
    ;~ _WinAPI_Wow64EnableWow64FsRedirection(True)
EndFunc

Func _StartScreensaverAndLock()
    ;~ _WinAPI_Wow64EnableWow64FsRedirection(False)
    ;~ _RunDos('start /wait ssText3d.scr /s & rundll32 user32.dll,LockWorkStation')
    RunWait('ssText3d.scr /s')
    ;~ _WinAPI_Wow64EnableWow64FsRedirection(True)
    _Lock()
EndFunc

Func _EmptyClipboard()
    _ClipBoard_Open(WinGetHandle("[ACTIVE]"))
    _ClipBoard_Empty()
    _ClipBoard_Close()
    ClipPut('')
    ;~ ConsoleWrite('DONE'&@LF)
EndFunc

Func _Lock()
    ShellExecute('Rundll32.exe', 'User32.dll,LockWorkStation', '', '', @SW_HIDE)
EndFunc

Func _LogOff()
    Shutdown(0)
EndFunc

Func _Restart()
    Shutdown(2)
EndFunc

Func _Shutdown()
    Shutdown(1)
EndFunc

Func _EmptyRecycleBin()
    FileRecycleEmpty()
EndFunc

Func _TurnOffMonitors($OnOff = 0)
    Sleep(500)
    ;turns off the monitor by default, but as it happens, monitor comes back on upon user input - keyboard or mouse
    Local $opt = Opt("WinTitleMatchMode", 4)
    Local $opt
    Local $hWnd
    Local $Param
    Local $SC_MonitorPower
    Local $WM_SYSCommand
    If $OnOff = 0 Then
        $Param = 2
    Else
        $Param = -1
    EndIf
    $hWnd = WinGetHandle("classname=Progman")
    $WM_SYSCommand = 274
    $SC_MonitorPower = 61808
    DllCall("user32.dll", "int", "SendMessage", "hwnd", $hWnd, _
            "int", $WM_SYSCommand, "int", $SC_MonitorPower, "int", $Param)
    Opt("WinTitleMatchMode", $opt)
EndFunc

Func _shot($hWnd)
	WinActivate($hWnd)
    ;~ $hWnd = WinGetHandle("[ACTIVE]")
	$img = _ScreenCapture_CaptureWnd('', $hWnd)
	Local Const $sMessage = "Choose a filename."
	Local $sFileSaveDialog = FileSaveDialog($sMessage, "::{450D8FBA-AD25-11D0-98A8-0800361B1103}", "Image as JPG (*.jpg)", $FD_PATHMUSTEXIST)
	If @error Then
		;~ _ExtMsgBox(48, 'OK', 'Oops!', 'No file was saved.'&@CRLF, 0)
	Else
		Local $sFileName = StringTrimLeft($sFileSaveDialog, StringInStr($sFileSaveDialog, "\", $STR_NOCASESENSEBASIC, -1))
		Local $iExtension = StringInStr($sFileName, ".", $STR_NOCASESENSEBASIC)
		If $iExtension Then
			If Not (StringTrimLeft($sFileName, $iExtension - 1) = ".jpg") Then $sFileSaveDialog &= ".jpg"
		Else
			$sFileSaveDialog &= ".jpg"
		EndIf
	EndIf
	;~ Sleep(500)
    _ScreenCapture_SaveImage($sFileSaveDialog, $img)
EndFunc

Func _toggle()
	;$enabled = Not $enabled
	If $enabled == False Then ;disable it
        For $i = 1 To $aHotkeys[0][0]
            HotKeySet(StringReplace($aHotkeys[$i][0], '{HkzEq}', '{=}'))
        Next
		$enabled = True
		TraySetIcon(@ScriptFullPath, 202)
		TrayItemSetState($enableTray, $TRAY_UNCHECKED)
		TraySetToolTip($title&" is disabled.")
	Else
        For $i = 1 To $aHotkeys[0][0]
            HotKeySet(StringReplace($aHotkeys[$i][0], '{HkzEq}', '{=}'), "HotKeyPressed")
        Next
		$enabled = False
		TraySetIcon(@ScriptFullPath, 201)
		TrayItemSetState($enableTray, $TRAY_CHECKED)
		TraySetToolTip($title&" is enabled.")
	EndIf
EndFunc

Func _iniCheck($iniFile)
    If Not FileExists($iniFile) Then
        IniWrite($iniFile, 'Options', 'Main', '^#,')
        IniWrite($iniFile, 'Hotkeys', '^+n', 'C:\Windows\System32\notepad.exe')
        IniWrite($iniFile, 'Hotkeys', '^+i', 'C:\Program Files (x86)\Internet Explorer\iexplore.exe')
        IniWrite($iniFile, 'Hotkeys', '^+8', 'https://leomoon.com/development-fund/')
        IniWrite($iniFile, 'Hotkeys', '^+9', 'C:\Program Files (x86)\Internet Explorer\iexplore.exe[HkzParam]https://leomoon.com')
        IniWrite($iniFile, 'Hotkeys', '^!c', '::{20d04fe0-3aea-1069-a2d8-08002b30309d}')
        IniWrite($iniFile, 'Hotkeys', '^!u', 'C:\Users\%USERNAME%')
        IniWrite($iniFile, 'Hotkeys', '^!p', '::{26EE0668-A00A-44D7-9371-BEB064C98683}')
        IniWrite($iniFile, 'Hotkeys', '^!{PGDN}', '[HkzWM]Minimize')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPADADD}', '[HkzWM]Transparency +')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPADSUB}', '[HkzWM]Transparency -')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD0}', '[HkzWM]Toggle On Top')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPADMULT}', '[HkzWM]Take Screenshot')
        IniWrite($iniFile, 'Hotkeys', '^!{UP}', '[HkzWM]Snap Fullscreen')
        IniWrite($iniFile, 'Hotkeys', '^!{LEFT}', '[HkzWM]Snap Left (2x1)')
        IniWrite($iniFile, 'Hotkeys', '^!{RIGHT}', '[HkzWM]Snap Right (2x1)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD7}', '[HkzWM]Snap Top Left (3x2)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD8}', '[HkzWM]Snap Top Mid (3x2)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD9}', '[HkzWM]Snap Top Right (3x2)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD4}', '[HkzWM]Snap Left (3x1)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD5}', '[HkzWM]Snap Mid (3x1)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD6}', '[HkzWM]Snap Right (3x1)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD1}', '[HkzWM]Snap Bottom Left (3x2)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD2}', '[HkzWM]Snap Bottom Mid (3x2)')
        IniWrite($iniFile, 'Hotkeys', '^!{NUMPAD3}', '[HkzWM]Snap Bottom Right (3x2)')
        IniWrite($iniFile, 'Hotkeys', '!+{RIGHT}', '[HkzWM]Move to Next Monitor')
        IniWrite($iniFile, 'Hotkeys', '!+{LEFT}', '[HkzWM]Move to Previous Monitor')
        IniWrite($iniFile, 'Hotkeys', '^!0', '[HkzSndTxt]Today is <DAYNAME>[HkzNL]Current time is: <HOUR>:<MINUTE>:<SECOND>[HkzNL]Current date is <MONTHNUMBER>\<DAYNUMBER>\<YEAR>')
    EndIf
    ;double check
    If Not FileExists($iniFile) Then
        _ExtMsgBox(48, 'OK', 'Oops!', $title&' was unable to write settings file at this location:'&@CRLF&'"'&@ScriptDir&'"'&@CRLF, 0)
        Exit
    EndIf
EndFunc

Func _readHotkey($iniFile, $section, $key, $trayItem, $text, $function, $default)
    ;inifile to read
    ;section of the ini
    ;key of the ini
    ;trayitem id to append the new hotkey
    ;trayitem text to append the new hotkey
    ;function to set hotkey
    $appHotkey = IniRead($iniFile, $section, $key, '')
    If $appHotkey == '' Then ;default hotkey if key not found in ini file
        IniWrite($iniFile, $section, $key, $default)
        TrayItemSetText($trayItem, $text&@TAB&_decodeHotkey($default))
    Else
        HotKeySet($appHotkey, $function)
        TrayItemSetText($trayItem, $text&@TAB&_decodeHotkey($appHotkey))
    EndIf
EndFunc

Func _iniToApply($iniFile)
    $aHotkeys = IniReadSection($ini, "Hotkeys")
    If IsArray($aHotkeys) Then
        For $i = 1 To $aHotkeys[0][0]
            ;~ ConsoleWrite($aHotkeys[$i][1]&' ### '&StringReplace($aHotkeys[$i][0], '{HkzEq}', '{=}')&@LF)
            HotKeySet(StringReplace($aHotkeys[$i][0], '{HkzEq}', '{=}'), "HotKeyPressed")
        Next
    Endif
EndFunc

Func _iniToGui($iniFile) ;just reads ini and sets the gui
    ;read main hotkey
    Local $appHotkey = IniRead($iniFile, 'Options', 'Main', '')
    Local $k = StringUpper(StringReplace(StringReplace(StringReplace(StringReplace($appHotkey,'^',''),'!',''),'+',''),'#',''))
    $k = _decodeKey($k)
    If StringInStr($appHotkey,'^') Then
        GUICtrlSetState($ctrlCbox, $GUI_CHECKED)
    Else
        GUICtrlSetState($ctrlCbox, $GUI_UNCHECKED)
    EndIf
    If StringInStr($appHotkey,'!') Then
        GUICtrlSetState($altCbox, $GUI_CHECKED)
    Else
        GUICtrlSetState($altCbox, $GUI_UNCHECKED)
    EndIf
    If StringInStr($appHotkey,'+') Then
        GUICtrlSetState($shiftCbox, $GUI_CHECKED)
    Else
        GUICtrlSetState($shiftCbox, $GUI_UNCHECKED)
    EndIf
    If StringInStr($appHotkey,'#') Then
        GUICtrlSetState($winCbox, $GUI_CHECKED)
    Else
        GUICtrlSetState($winCbox, $GUI_UNCHECKED)
    EndIf
    _GUICtrlComboBox_SelectString($keyDown, $k)
    ;rest of settings
    If RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", $title) == '' Then
        GUICtrlSetState($startupCbox, $GUI_UNCHECKED)
    Else
        GUICtrlSetState($startupCbox, $GUI_CHECKED)
    EndIf
    Local $aArray = IniReadSection($iniFile, "Hotkeys")
	If Not @error Then
        For $i = 1 To $aArray[0][0]
            Local $opts = ''
            Local $special = False
            Local $sPath = False
            For $c = 0 To UBound($clsid, 1)-1
                If _strCompare($aArray[$i][1], $clsid[$c][1]) Then
                    $aArray[$i][1] = $clsid[$c][0]
                    $sPath = True
                    ExitLoop
                EndIf
            Next
            For $s = 0 To UBound($sPaths, 1)-1
                If _strCompare($aArray[$i][1], $sPaths[$s][1]) Then
                    $aArray[$i][1] = $sPaths[$s][0]
                    $special = True
                    ExitLoop
                EndIf
            Next
            If StringInStr($aArray[$i][1], '[HkzSndTxt]') Then
                $type = 'Text'
            ElseIf StringInStr($aArray[$i][1], '[HkzWM]') Then
                $type = 'Window'
            ElseIf StringInStr($aArray[$i][1], '[HkzCmd]') Then
                $type = 'Command'
            ElseIf StringInStr($aArray[$i][1], 'https://') Or StringInStr($aArray[$i][1], 'http://') Or StringInStr($aArray[$i][1], 'ftp://') And Not StringInStr($aArray[$i][1], '[HkzParam]') Then
                $type = 'URL'
            ElseIf $special Or StringInStr($aArray[$i][1], '[HkzExe]') Then
                $type = 'System'
            ElseIf StringInStr(FileGetAttrib(StringReplace($aArray[$i][1], '<USERNAME>', @UserName)), 'D') Or $sPath Then
                $type = 'Folder'
            Else
                $type = 'File'
            EndIf
            If StringInStr($aArray[$i][1], '[HkzOptAdmin]') Then $opts &= 'Admin'
            If StringInStr($aArray[$i][1], '[HkzOptOne]') Then
                If $opts == 'Admin' Then $opts &= ', '
                $opts &= 'Singleton'
            EndIf
            ;~ ConsoleWrite($type&'|'&_decodeHotkey($aArray[$i][0])&'|'&$aArray[$i][1]&@LF)
            ;cleanups
            $aArray[$i][1] = StringReplace($aArray[$i][1], '[HkzEq]', '=')
            $aArray[$i][1] = StringReplace($aArray[$i][1], '[HkzSysSnd]', '')
            $aArray[$i][1] = StringReplace($aArray[$i][1], '[HkzSndTxt]', '')
            $aArray[$i][1] = StringReplace($aArray[$i][1], '[HkzExe]', '')
            $aArray[$i][1] = StringReplace($aArray[$i][1], '[HkzWM]', '')
            $aArray[$i][1] = StringReplace($aArray[$i][1], '[HkzOptAdmin]', '')
            $aArray[$i][1] = StringReplace($aArray[$i][1], '[HkzOptOne]', '')
            $aArray[$i][1] = StringReplace($aArray[$i][1], '[HkzCmd]', '')
            $aArray[$i][1] = StringReplace($aArray[$i][1], '[HkzParam]', ' [Parameters] ')
            $aArray[$i][1] = StringReplace($aArray[$i][1], '[HkzNL]', '[New Line]')
			GUICtrlCreateListViewItem($type&'|'&_decodeHotkey($aArray[$i][0])&'|'&$aArray[$i][1]&'|'&$opts, $ListView1)
        Next
    EndIf
    ;~ GUICtrlSendMsg($ListView1, $LVM_SETCOLUMNWIDTH, 1, -1)
    ;~ GUICtrlSendMsg($ListView1, $LVM_SETCOLUMNWIDTH, 2, -1)
    ;resize columns
    _GUICtrlListView_SetColumnWidth($ListView1, 0, $LVSCW_AUTOSIZE_USEHEADER)
    _GUICtrlListView_SetColumnWidth($ListView1, 1, $LVSCW_AUTOSIZE_USEHEADER)
    If IsArray($aArray) Then
        _GUICtrlListView_SetColumnWidth($ListView1, 0, _GUICtrlListView_GetColumnWidth($ListView1, 0)+10)
        _GUICtrlListView_SetColumnWidth($ListView1, 1, _GUICtrlListView_GetColumnWidth($ListView1, 1)+10)
        _GUICtrlListView_SetColumnWidth($ListView1, 3, _GUICtrlListView_GetColumnWidth($ListView1, 3)+10)
    Else
        _GUICtrlListView_SetColumnWidth($ListView1, 1, 160)
    EndIf
    _GUICtrlListView_SetColumnWidth($ListView1, 2, ControlGetPos($mainGui, '', $ListView1)[2]-(_GUICtrlListView_GetColumnWidth($ListView1, 0)+_GUICtrlListView_GetColumnWidth($ListView1, 1)+_GUICtrlListView_GetColumnWidth($ListView1, 3)+25))
    _GUICtrlListView_SetItemSelected($ListView1, 0) ;select first item
EndFunc

Func _guiToIni($iniFile) ;reads gui and saves to ini and sets global hotkey only
    ;main hotkey
    Local $oldHotkey = IniRead($iniFile, 'Options', 'Main', '') ;get old hotkey
    Local $appHotkey = ''
    If BitAND(GUICtrlRead($ctrlCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '^'
    If BitAND(GUICtrlRead($altCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '!'
    If BitAND(GUICtrlRead($shiftCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '+'
    If BitAND(GUICtrlRead($winCbox), $GUI_CHECKED) == 1 Then $appHotkey &= '#'
    $appHotkey &= _encodeKey(GUICtrlRead($keyDown))
    IniWrite($iniFile, 'Options', 'Main', $appHotkey) ;write the new hotkey
    HotKeySet($oldHotkey) ;unset old hotkey
    HotKeySet($appHotkey, '_toggle') ;set new hotkey
    $txt = _decodeHotkey($appHotkey) ;decode hotkey to text
    TrayItemSetText($enableTray, 'Enable LeoMoon HotKeyz'&@TAB&$txt) ;change menu entry to new hotkey
    ;rest of settings
    ;unset old hotkeys
    If IsArray($aHotkeys) Then
        For $i = 1 To $aHotkeys[0][0]
            HotKeySet($aHotkeys[$i][0])
        Next
    EndIf
    ;delete all hotkeys
    IniDelete($iniFile, 'Hotkeys')
    ;save new hotkeys
    For $x = 0 To _GUICtrlListView_GetItemCount($ListView1) - 1
        ;~ ConsoleWrite(_GUICtrlListView_GetItemText($ListView1, $x, 1)&', '&_GUICtrlListView_GetItemText($ListView1, $x, 2)&@LF)
        Local $path = _GUICtrlListView_GetItemText($ListView1, $x, 2)
        ;~ Local $type = _GUICtrlListView_GetItemText($ListView1, $x, 0)
        ;define clsid list
        For $c = 0 To UBound($clsid, 1)-1
            If _strCompare($path, $clsid[$c][0]) Then
                $path = $clsid[$c][1]
                ExitLoop
            EndIf
        Next
        For $s = 0 To UBound($sPaths, 1)-1
            If _strCompare($path, $sPaths[$s][0]) Then
                $path = $sPaths[$s][1]
                ExitLoop
            EndIf
        Next
        ;reversals
        $path = StringReplace($path, '=', '[HkzEq]')
        If _GUICtrlListView_GetItemText($ListView1, $x, 0) == 'Text' Then $path = '[HkzSndTxt]'&$path
        If _GUICtrlListView_GetItemText($ListView1, $x, 0) == 'Window' Then $path = '[HkzWM]'&$path
        If StringInStr(_GUICtrlListView_GetItemText($ListView1, $x, 0), 'Command') Then $path = '[HkzCmd]'&$path
        If StringInStr(_GUICtrlListView_GetItemText($ListView1, $x, 3), 'Admin') Then $path = $path&'[HkzOptAdmin]'
        If StringInStr(_GUICtrlListView_GetItemText($ListView1, $x, 3), 'Singleton') Then $path = $path&'[HkzOptOne]'
        $path = StringReplace($path, ' [Parameters] ', '[HkzParam]')
        $path = StringReplace($path, '[New Line]', '[HkzNL]')
        IniWrite($iniFile, 'Hotkeys', _encodeHotkey(_GUICtrlListView_GetItemText($ListView1, $x, 1)), $path)
        ;~ ConsoleWrite($path&' '&_GUICtrlListView_GetItemText($ListView1, $x, 0)&@LF)
    Next
EndFunc

Func _decodeHotkey($hotkey)
    Local $decode = ''
    If StringInStr($hotkey,'^') Then $decode &= 'Ctrl + '
    If StringInStr($hotkey,'!') Then $decode &= 'Alt + '
    If StringInStr($hotkey,'+') Then $decode &= 'Shift + '
    If StringInStr($hotkey,'#') Then $decode &= 'Win + '
    $decode &= _decodeKey(StringReplace(StringReplace(StringReplace(StringReplace($hotkey,'^',''),'!',''),'+',''),'#','')) ;get the last key
    Return($decode)
EndFunc

Func _encodeHotkey($hotkey)
    Local $encode = ''
    If StringInStr($hotkey,'Ctrl + ') Then $encode &= '^'
    If StringInStr($hotkey,'Alt + ') Then $encode &= '!'
    If StringInStr($hotkey,'Shift + ') Then $encode &= '+'
    If StringInStr($hotkey,'Win + ') Then $encode &= '#'
    $encode &= _encodeKey(StringReplace(StringReplace(StringReplace(StringReplace($hotkey,'Ctrl + ',''),'Alt + ',''),'Shift + ',''),'Win + ','')) ;get the last key
    Return($encode)
EndFunc

Func _fileRdo()
    If GUICtrlRead($fileRdo) == 1 Then
        GUICtrlSetState($fileInp, $GUI_ENABLE)
        GUICtrlSetState($fileBrowseBtn, $GUI_ENABLE)
        GUICtrlSetState($fileParamLbl, $GUI_ENABLE)
        GUICtrlSetState($fileParamInp, $GUI_ENABLE)
        GUICtrlSetState($adminCbox, $GUI_ENABLE)
        GUICtrlSetState($oneCbox, $GUI_ENABLE)
        GUICtrlSetState($cmdCbox, $GUI_ENABLE)
        _cmdCbox()
        GUICtrlSetState($folderInp, $GUI_DISABLE)
        GUICtrlSetState($folderBrowseBtn, $GUI_DISABLE)
        GUICtrlSetState($specialDown, $GUI_DISABLE)
        GUICtrlSetState($windowDown, $GUI_DISABLE)
        _windowDown()
        GUICtrlSetState($urlDown, $GUI_DISABLE)
        GUICtrlSetState($urlInp, $GUI_DISABLE)
        GUICtrlSetState($txtEdit, $GUI_DISABLE)
    EndIf
EndFunc

Func _cmdCbox()
    If GUICtrlRead($cmdCbox) == $GUI_CHECKED Then
        GUICtrlSetState($fileParamInp, $GUI_DISABLE)
        GUICtrlSetState($fileBrowseBtn, $GUI_DISABLE)
        GUICtrlSetState($oneCbox, $GUI_UNCHECKED)
        GUICtrlSetState($oneCbox, $GUI_DISABLE)
        GUICtrlSetData($fileRdo, 'Run a Batch command')
    Else
        GUICtrlSetState($fileParamInp, $GUI_ENABLE)
        GUICtrlSetState($fileBrowseBtn, $GUI_ENABLE)
        GUICtrlSetState($oneCbox, $GUI_ENABLE)
        GUICtrlSetData($fileRdo, 'Run a program or open a file')
    EndIf
EndFunc

Func _folderRdo()
    If GUICtrlRead($folderRdo) == 1 Then
        GUICtrlSetState($fileInp, $GUI_DISABLE)
        GUICtrlSetState($fileBrowseBtn, $GUI_DISABLE)
        GUICtrlSetState($fileParamLbl, $GUI_DISABLE)
        GUICtrlSetState($fileParamInp, $GUI_DISABLE)
        GUICtrlSetState($adminCbox, $GUI_DISABLE)
        GUICtrlSetState($oneCbox, $GUI_DISABLE)
        GUICtrlSetState($cmdCbox, $GUI_DISABLE)
        GUICtrlSetState($folderInp, $GUI_ENABLE)
        GUICtrlSetState($folderBrowseBtn, $GUI_ENABLE)
        GUICtrlSetState($specialDown, $GUI_DISABLE)
        GUICtrlSetState($windowDown, $GUI_DISABLE)
        _windowDown()
        GUICtrlSetState($urlDown, $GUI_DISABLE)
        GUICtrlSetState($urlInp, $GUI_DISABLE)
        GUICtrlSetState($txtEdit, $GUI_DISABLE)
    EndIf
EndFunc

Func _specialRdo()
    If GUICtrlRead($specialRdo) == 1 Then
        GUICtrlSetState($fileInp, $GUI_DISABLE)
        GUICtrlSetState($fileBrowseBtn, $GUI_DISABLE)
        GUICtrlSetState($fileParamLbl, $GUI_DISABLE)
        GUICtrlSetState($fileParamInp, $GUI_DISABLE)
        GUICtrlSetState($adminCbox, $GUI_DISABLE)
        GUICtrlSetState($oneCbox, $GUI_DISABLE)
        GUICtrlSetState($cmdCbox, $GUI_DISABLE)
        GUICtrlSetState($folderInp, $GUI_DISABLE)
        GUICtrlSetState($folderBrowseBtn, $GUI_DISABLE)
        GUICtrlSetState($specialDown, $GUI_ENABLE)
        GUICtrlSetState($windowDown, $GUI_DISABLE)
        _windowDown()
        GUICtrlSetState($urlDown, $GUI_DISABLE)
        GUICtrlSetState($urlInp, $GUI_DISABLE)
        GUICtrlSetState($txtEdit, $GUI_DISABLE)
    EndIf
EndFunc

Func _windowRdo()
    If GUICtrlRead($windowRdo) == 1 Then
        GUICtrlSetState($fileInp, $GUI_DISABLE)
        GUICtrlSetState($fileBrowseBtn, $GUI_DISABLE)
        GUICtrlSetState($fileParamLbl, $GUI_DISABLE)
        GUICtrlSetState($fileParamInp, $GUI_DISABLE)
        GUICtrlSetState($adminCbox, $GUI_DISABLE)
        GUICtrlSetState($oneCbox, $GUI_DISABLE)
        GUICtrlSetState($cmdCbox, $GUI_DISABLE)
        GUICtrlSetState($folderInp, $GUI_DISABLE)
        GUICtrlSetState($folderBrowseBtn, $GUI_DISABLE)
        GUICtrlSetState($specialDown, $GUI_DISABLE)
        GUICtrlSetState($windowDown, $GUI_ENABLE)
        _windowDown()
        GUICtrlSetState($urlDown, $GUI_DISABLE)
        GUICtrlSetState($urlInp, $GUI_DISABLE)
        GUICtrlSetState($txtEdit, $GUI_DISABLE)
    EndIf
EndFunc

Func _windowDown()
    If GUICtrlRead($windowDown) == 'Custom Move and/or Resize' And BitAND(GUICtrlGetState($windowDown), $GUI_ENABLE) Then
        GUICtrlSetState($moveCbox, $GUI_ENABLE)
        _moveCbox()
        GUICtrlSetState($resizeCbox, $GUI_ENABLE)
        _resizeCbox()
    Else
        GUICtrlSetState($moveCbox, $GUI_DISABLE)
        _moveCbox()
        GUICtrlSetState($resizeCbox, $GUI_DISABLE)
        _resizeCbox()
    EndIf
EndFunc

Func _moveCbox()
    If GUICtrlRead($moveCbox) == $GUI_CHECKED And BitAND(GUICtrlGetState($moveCbox), $GUI_ENABLE) And GUICtrlRead($windowDown) == 'Custom Move and/or Resize' Then
        GUICtrlSetState($xLbl, $GUI_ENABLE)
        GUICtrlSetState($movexInp, $GUI_ENABLE)
        GUICtrlSetState($yLbl, $GUI_ENABLE)
        GUICtrlSetState($moveyInp, $GUI_ENABLE)
    Else
        GUICtrlSetState($xLbl, $GUI_DISABLE)
        GUICtrlSetState($movexInp, $GUI_DISABLE)
        GUICtrlSetState($yLbl, $GUI_DISABLE)
        GUICtrlSetState($moveyInp, $GUI_DISABLE)
    EndIf
EndFunc

Func _resizeCbox()
    If GUICtrlRead($resizeCbox) == $GUI_CHECKED And BitAND(GUICtrlGetState($resizeCbox), $GUI_ENABLE) And GUICtrlRead($windowDown) == 'Custom Move and/or Resize' Then
        GUICtrlSetState($wLbl, $GUI_ENABLE)
        GUICtrlSetState($resizewInp, $GUI_ENABLE)
        GUICtrlSetState($hLbl, $GUI_ENABLE)
        GUICtrlSetState($resizehInp, $GUI_ENABLE)
    Else
        GUICtrlSetState($wLbl, $GUI_DISABLE)
        GUICtrlSetState($resizewInp, $GUI_DISABLE)
        GUICtrlSetState($hLbl, $GUI_DISABLE)
        GUICtrlSetState($resizehInp, $GUI_DISABLE)
    EndIf
EndFunc

Func _urlRdo()
    If GUICtrlRead($urlRdo) == 1 Then
        GUICtrlSetState($cmdCbox, $GUI_DISABLE)
        GUICtrlSetState($fileInp, $GUI_DISABLE)
        GUICtrlSetState($fileBrowseBtn, $GUI_DISABLE)
        GUICtrlSetState($fileParamLbl, $GUI_DISABLE)
        GUICtrlSetState($fileParamInp, $GUI_DISABLE)
        GUICtrlSetState($folderInp, $GUI_DISABLE)
        GUICtrlSetState($folderBrowseBtn, $GUI_DISABLE)
        GUICtrlSetState($specialDown, $GUI_DISABLE)
        GUICtrlSetState($windowDown, $GUI_DISABLE)
        _windowDown()
        GUICtrlSetState($urlDown, $GUI_ENABLE)
        GUICtrlSetState($urlInp, $GUI_ENABLE)
        GUICtrlSetState($txtEdit, $GUI_DISABLE)
    EndIf
EndFunc

Func _txtRdo()
    If GUICtrlRead($txtRdo) == 1 Then
        GUICtrlSetState($cmdCbox, $GUI_DISABLE)
        GUICtrlSetState($fileInp, $GUI_DISABLE)
        GUICtrlSetState($fileBrowseBtn, $GUI_DISABLE)
        GUICtrlSetState($fileParamLbl, $GUI_DISABLE)
        GUICtrlSetState($fileParamInp, $GUI_DISABLE)
        GUICtrlSetState($folderInp, $GUI_DISABLE)
        GUICtrlSetState($folderBrowseBtn, $GUI_DISABLE)
        GUICtrlSetState($specialDown, $GUI_DISABLE)
        GUICtrlSetState($windowDown, $GUI_DISABLE)
        _windowDown()
        GUICtrlSetState($urlDown, $GUI_DISABLE)
        GUICtrlSetState($urlInp, $GUI_DISABLE)
        GUICtrlSetState($txtEdit, $GUI_ENABLE)
    EndIf
EndFunc

Func _delBtn()
    If MsgBox(48+4, 'Confirmation', 'Delete the selected hotkey?', 0, $mainGui) == 6 Then
        _GUICtrlListView_DeleteItemsSelected($ListView1)
        _GUICtrlListView_SetItemSelected($ListView1, 1)
        _GUICtrlListView_SetItemFocused($ListView1, 1)
    EndIf
EndFunc

Func _web()
    ShellExecute('http://leomoon.com', '', '', '', @SW_HIDE)
EndFunc

Func _addBtn()
    _editGui('Add Hotkey', 'OK')
    GUICtrlSetState($fileRdo, $GUI_CHECKED)
    _fileRdo()
    GUICtrlSetOnEvent($okEditBtn, "_add")
    GUISetState(@SW_DISABLE, $mainGui)
    GUISetState(@SW_SHOW, $editGui)
EndFunc

Func _add()
    If GUICtrlRead($fileRdo) == 1 And GUICtrlRead($fileInp) == '' Then
        GUISetState(@SW_DISABLE, $editGui)
        If MsgBox(48, 'Oops!', 'Please select a file.', 0, $editGui) == 1 Then
            GUISetState(@SW_ENABLE, $editGui)
            WinActivate($editGui)
        EndIf
    ElseIf GUICtrlRead($folderRdo) == 1 And GUICtrlRead($folderInp) == '' Then
        GUISetState(@SW_DISABLE, $editGui)
        If MsgBox(48, 'Oops!', 'Please select a folder.', 0, $editGui) == 1 Then
            GUISetState(@SW_ENABLE, $editGui)
            WinActivate($editGui)
        EndIf
    ElseIf GUICtrlRead($specialRdo) == 1 And GUICtrlRead($specialDown) == '' Then
        GUISetState(@SW_DISABLE, $editGui)
        If MsgBox(48, 'Oops!', 'Please select an option.', 0, $editGui) == 1 Then
            GUISetState(@SW_ENABLE, $editGui)
            WinActivate($editGui)
        EndIf
    ElseIf (GUICtrlRead($windowRdo) == 1 And GUICtrlRead($windowDown) == 'Custom Move and/or Resize') And _
        (GUICtrlRead($moveCbox) == $GUI_UNCHECKED And GUICtrlRead($resizeCbox) == $GUI_UNCHECKED) Or _
        (GUICtrlRead($moveCbox) == $GUI_CHECKED And (GUICtrlRead($movexInp) == '' Or GUICtrlRead($moveyInp) == '')) Or _
        (GUICtrlRead($resizeCbox) == $GUI_CHECKED And (GUICtrlRead($resizewInp) == '' Or GUICtrlRead($resizehInp) == '')) Then
        GUISetState(@SW_DISABLE, $editGui)
        If MsgBox(48, 'Oops!', 'Please select a predefined window action or enter a custom location and/or size.', 0, $editGui) == 1 Then
            GUISetState(@SW_ENABLE, $editGui)
            WinActivate($editGui)
        EndIf
    ElseIf GUICtrlRead($urlRdo) == 1 And GUICtrlRead($urlInp) == '' Then
        GUISetState(@SW_DISABLE, $editGui)
        If MsgBox(48, 'Oops!', 'Please enter a URL.', 0, $editGui) == 1 Then
            GUISetState(@SW_ENABLE, $editGui)
            WinActivate($editGui)
        EndIf
    ElseIf BitAND(GUICtrlRead($ctrlEditCbox), $GUI_CHECKED) == 0 And _
        BitAND(GUICtrlRead($altEditCbox), $GUI_CHECKED) == 0 And _
        BitAND(GUICtrlRead($shiftEditCbox), $GUI_CHECKED) == 0 And _
        BitAND(GUICtrlRead($winEditCbox), $GUI_CHECKED) == 0 Or _
        GUICtrlRead($keyEditDown) == '' Then
            GUISetState(@SW_DISABLE, $editGui)
            If MsgBox(48, 'Oops!', 'Please assign a hotkey.', 0, $editGui) == 1 Then
                GUISetState(@SW_ENABLE, $editGui)
                WinActivate($editGui)
            EndIf
    Else
        Local $childRead = ''
        Local $error = False
        Local $opts = ''
        If GUICtrlRead($adminCbox) == 1 Then $opts &= 'Admin'
        If GUICtrlRead($oneCbox) == 1 Then
            If $opts == 'Admin' Then $opts &= ', '
            $opts &= 'Singleton'
        EndIf
        If BitAND(GUICtrlRead($ctrlEditCbox), $GUI_CHECKED) == 1 Then $childRead &= 'Ctrl + '
        If BitAND(GUICtrlRead($altEditCbox), $GUI_CHECKED) == 1 Then $childRead &= 'Alt + '
        If BitAND(GUICtrlRead($shiftEditCbox), $GUI_CHECKED) == 1 Then $childRead &= 'Shift + '
        If BitAND(GUICtrlRead($winEditCbox), $GUI_CHECKED) == 1 Then $childRead &= 'Win + '
        $childRead &= _decodeKey(GUICtrlRead($keyEditDown))
        For $x = 0 To _GUICtrlListView_GetItemCount($ListView1) - 1
            If $childRead == _GUICtrlListView_GetItemText($ListView1, $x, 1) Then
                $error = True
                ExitLoop
            EndIf
        Next
        If $error Or $childRead == _returnToggleHotkey() Then
            GUISetState(@SW_DISABLE, $editGui)
            If MsgBox(48, 'Oops!', 'Hotkey alreay assigned. Please choose another hotkey.', 0, $editGui) == 1 Then
                $error = False
                GUISetState(@SW_ENABLE, $editGui)
                WinActivate($editGui)
            EndIf
        Else
            If GUICtrlRead($fileRdo) == 1 Then
                $fileParam = GUICtrlRead($fileInp)
                If GUICtrlRead($cmdCbox) == $GUI_CHECKED Then
                    GUICtrlCreateListViewItem('Command'&'|'&$childRead&'|'&$fileParam&'|'&$opts, $ListView1)
                Else
                    If GUICtrlRead($fileParamInp) <> '' Then $fileParam = $fileParam&' [Parameters] '&GUICtrlRead($fileParamInp)
                    GUICtrlCreateListViewItem('File'&'|'&$childRead&'|'&$fileParam&'|'&$opts, $ListView1)
                EndIf
            ElseIf GUICtrlRead($folderRdo) == 1 Then
                GUICtrlCreateListViewItem('Folder|'&$childRead&'|'&GUICtrlRead($folderInp), $ListView1)
            ElseIf GUICtrlRead($specialRdo) == 1 Then
                GUICtrlCreateListViewItem('System|'&$childRead&'|'&GUICtrlRead($specialDown), $ListView1)
            ElseIf GUICtrlRead($windowRdo) == 1 Then
                If GUICtrlRead($windowDown) == 'Custom Move and/or Resize' Then
                    Local $m = ''
                    Local $r = ''
                    If GUICtrlRead($moveCbox) == $GUI_CHECKED Then $m = 'Move to '&GUICtrlRead($movexInp)&','&GUICtrlRead($moveyInp)
                    If GUICtrlRead($resizeCbox) == $GUI_CHECKED Then $r = 'Resize to '&GUICtrlRead($resizewInp)&'x'&GUICtrlRead($resizehInp)
                    If $m <> '' and $r <> '' Then
                        $m = $m&' & '&$r
                    Else
                        $m = $m&$r
                    EndIf
                    GUICtrlCreateListViewItem('Window|'&$childRead&'|'&$m, $ListView1)
                Else
                    GUICtrlCreateListViewItem('Window|'&$childRead&'|'&GUICtrlRead($windowDown), $ListView1)
                EndIf
            ElseIf GUICtrlRead($urlRdo) == 1 Then
                GUICtrlCreateListViewItem('URL|'&$childRead&'|'&GUICtrlRead($urlDown)&GUICtrlRead($urlInp), $ListView1)
            ElseIf GUICtrlRead($txtRdo) == 1 Then
                $hkztxt = StringReplace(GUICtrlRead($txtEdit), @CRLF, '[New Line]')
                GUICtrlCreateListViewItem('Text|'&$childRead&'|'&$hkztxt, $ListView1)
            EndIf
            _hideChild()
        EndIf
    EndIf
EndFunc

Func _editBtn()
    $hotkey = _GUICtrlListView_GetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 1)
    $path = _GUICtrlListView_GetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 2)
    Local $match = False
    Local $special = False
    Local $window = False
    Local $url = False
    Local $sndTxt = False
    Local $k = _decodeKey(StringReplace(StringReplace(StringReplace(StringReplace($hotkey,'Ctrl + ',''),'Alt + ',''),'Shift + ',''),'Win + ',''))
    ;define clsid list
    For $c = 0 To UBound($clsid, 1)-1
        If _strCompare($path, $clsid[$c][0]) Then
            $match = True
            ExitLoop
        EndIf
    Next
    For $s = 0 To UBound($sPaths, 1)-1
        ;~ ConsoleWrite($path&' - '&$sPaths[$s][0]&@LF)
        If _strCompare($path, $sPaths[$s][0]) Then
            $special = True
            ExitLoop
        EndIf
    Next
    _editGui('Edit Hotkey', 'OK')
    If StringInStr(_GUICtrlListView_GetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 3), 'Admin') Then GUICtrlSetState($adminCbox, $GUI_CHECKED)
    If StringInStr(_GUICtrlListView_GetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 3), 'Singleton') Then GUICtrlSetState($oneCbox, $GUI_CHECKED)
    If $special Then
        GUICtrlSetState($specialRdo, $GUI_CHECKED)
        _GUICtrlComboBox_SelectString($specialDown, $sPaths[$s][0])
        _specialRdo()
    ElseIf $match Then
        GUICtrlSetState($folderRdo, $GUI_CHECKED)
        GUICtrlSetData($folderInp, $path)
        _folderRdo()
    ElseIf StringInStr(FileGetAttrib(StringReplace($path, '<USERNAME>', @UserName)), 'D') Then
        GUICtrlSetState($folderRdo, $GUI_CHECKED)
        GUICtrlSetData($folderInp, $path)
        _folderRdo()
    ElseIf _GUICtrlListView_GetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 0) == 'Window' Then
        GUICtrlSetState($windowRdo, $GUI_CHECKED)
        If StringInStr($path, 'Move to ') Or StringInStr($path, 'Resize to ') Then
            _GUICtrlComboBox_SelectString($windowDown, 'Custom Move and/or Resize')
            If StringInStr($path, 'Move to ') Then
                GUICtrlSetState($moveCbox, $GUI_CHECKED)
            Else
                GUICtrlSetState($moveCbox, $GUI_UNCHECKED)
            EndIf
            _moveCbox()
            If StringInStr($path, 'Resize to ') Then
                GUICtrlSetState($resizeCbox, $GUI_CHECKED)
            Else
                GUICtrlSetState($resizeCbox, $GUI_UNCHECKED)
            EndIf
            _resizeCbox()
            If StringInStr($path, ' & ') Then
                $moveresize = StringSplit(StringReplace(StringReplace($path, 'Move to ', ''), 'Resize to ', ''), ' & ', 1)
                $move = StringSplit($moveresize[1], ',')
                $resize = StringSplit($moveresize[2], 'x')
                If IsArray($move) And $move[0] == 2 And IsArray($resize) And $resize[0] == 2 Then
                    GUICtrlSetData($movexInp, $move[1])
                    GUICtrlSetData($moveyInp, $move[2])
                    GUICtrlSetData($resizewInp, $resize[1])
                    GUICtrlSetData($resizehInp, $resize[2])
                EndIf
            ElseIf StringInStr($path, ',') Then
                $move = StringSplit(StringReplace($path, 'Move to ', ''), ',')
                If IsArray($move) And $move[0] == 2 Then
                    GUICtrlSetData($movexInp, $move[1])
                    GUICtrlSetData($moveyInp, $move[2])
                EndIf
            ElseIf StringInStr($path, 'x') Then
                $resize = StringSplit(StringReplace($path, 'Resize to ', ''), 'x')
                If IsArray($resize) And $resize[0] == 2 Then
                    GUICtrlSetData($resizewInp, $resize[1])
                    GUICtrlSetData($resizehInp, $resize[2])
                EndIf
            EndIf
        Else
            _GUICtrlComboBox_SelectString($windowDown, $path)
        EndIf
        _windowRdo()
        _windowDown()
    ElseIf StringInStr($path, 'https://') Or StringInStr($path, 'http://') Or StringInStr($path, 'ftp://') And Not StringInStr($path, '[Parameters]') Then
        GUICtrlSetState($urlRdo, $GUI_CHECKED)
        If StringInStr($path, 'https://') Then
            _GUICtrlComboBox_SelectString($urlDown, 'https://')
        ElseIf StringInStr($path, 'http://') Then
            _GUICtrlComboBox_SelectString($urlDown, 'http://')
        ElseIf StringInStr($path, 'ftp://') Then
            _GUICtrlComboBox_SelectString($urlDown, 'ftp://')
        EndIf
        GUICtrlSetData($urlInp, StringReplace(StringReplace(StringReplace($path, 'https://', ''), 'http://', ''), 'ftp://', ''))
        _urlRdo()
    ElseIf _GUICtrlListView_GetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 0) == 'Text' Then
        GUICtrlSetState($txtRdo, $GUI_CHECKED)
        GUICtrlSetData($txtEdit, StringReplace($path, '[New Line]', @CRLF))
        _txtRdo()
    ElseIf StringInStr(_GUICtrlListView_GetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 0), 'Command') Then
        GUICtrlSetState($fileRdo, $GUI_CHECKED)
        GUICtrlSetState($cmdCbox, $GUI_CHECKED)
        GUICtrlSetData($fileInp, StringReplace($path, '[HkzCmd]', ''))
        _cmdCbox()
    Else
        ;split $path with [Parameters]
        If StringInStr($path, ' [Parameters] ') Then
            $hkzsplit = StringSplit($path, ' [Parameters] ', 1)
            $path = $hkzsplit[1]
            If $hkzsplit[0] == 2 Then GUICtrlSetData($fileParamInp,$hkzsplit[2])
        EndIf
        GUICtrlSetState($fileRdo, $GUI_CHECKED)
        GUICtrlSetData($fileInp, $path)
        _fileRdo()
    EndIf
    If StringInStr($hotkey,'Ctrl') Then GUICtrlSetState($ctrlEditCbox, $GUI_CHECKED)
    If StringInStr($hotkey,'Alt') Then GUICtrlSetState($altEditCbox, $GUI_CHECKED)
    If StringInStr($hotkey,'Shift') Then GUICtrlSetState($shiftEditCbox, $GUI_CHECKED)
    If StringInStr($hotkey,'Win') Then GUICtrlSetState($winEditCbox, $GUI_CHECKED)
    _GUICtrlComboBox_SelectString($keyEditDown, $k)
    GUICtrlSetOnEvent($okEditBtn, "_edit")
    GUISetState(@SW_DISABLE, $mainGui)
    GUISetState(@SW_SHOW, $editGui)
EndFunc

Func _edit()
    If GUICtrlRead($fileRdo) == 1 And GUICtrlRead($fileInp) == '' Then
        GUISetState(@SW_DISABLE, $editGui)
        If MsgBox(48, 'Oops!', 'Please select a file.', 0, $editGui) == 1 Then
            GUISetState(@SW_ENABLE, $editGui)
            WinActivate($editGui)
        EndIf
    ElseIf GUICtrlRead($folderRdo) == 1 And GUICtrlRead($folderInp) == '' Then
        GUISetState(@SW_DISABLE, $editGui)
        If MsgBox(48, 'Oops!', 'Please select a folder.', 0, $editGui) == 1 Then
            GUISetState(@SW_ENABLE, $editGui)
            WinActivate($editGui)
        EndIf
    ElseIf GUICtrlRead($specialRdo) == 1 And GUICtrlRead($specialDown) == '' Then
        GUISetState(@SW_DISABLE, $editGui)
        If MsgBox(48, 'Oops!', 'Please select an option.', 0, $editGui) == 1 Then
            GUISetState(@SW_ENABLE, $editGui)
            WinActivate($editGui)
        EndIf
    ElseIf (GUICtrlRead($windowRdo) == 1 And GUICtrlRead($windowDown) == 'Custom Move and/or Resize') And _
            (GUICtrlRead($moveCbox) == $GUI_UNCHECKED And GUICtrlRead($resizeCbox) == $GUI_UNCHECKED) Or _
            (GUICtrlRead($moveCbox) == $GUI_CHECKED And (GUICtrlRead($movexInp) == '' Or GUICtrlRead($moveyInp) == '')) Or _
            (GUICtrlRead($resizeCbox) == $GUI_CHECKED And (GUICtrlRead($resizewInp) == '' Or GUICtrlRead($resizehInp) == '')) Then
            GUISetState(@SW_DISABLE, $editGui)
            If MsgBox(48, 'Oops!', 'Please select a predefined window action or enter a custom location and/or size.', 0, $editGui) == 1 Then
                GUISetState(@SW_ENABLE, $editGui)
                WinActivate($editGui)
            EndIf
    ElseIf GUICtrlRead($urlRdo) == 1 And GUICtrlRead($urlInp) == '' Then
        GUISetState(@SW_DISABLE, $editGui)
        If MsgBox(48, 'Oops!', 'Please enter a URL.', 0, $editGui) == 1 Then
            GUISetState(@SW_ENABLE, $editGui)
            WinActivate($editGui)
        EndIf
    ElseIf BitAND(GUICtrlRead($ctrlEditCbox), $GUI_CHECKED) == 0 And _
        BitAND(GUICtrlRead($altEditCbox), $GUI_CHECKED) == 0 And _
        BitAND(GUICtrlRead($shiftEditCbox), $GUI_CHECKED) == 0 And _
        BitAND(GUICtrlRead($winEditCbox), $GUI_CHECKED) == 0 Or _
        GUICtrlRead($keyEditDown) == '' Then
            GUISetState(@SW_DISABLE, $editGui)
            If MsgBox(48, 'Oops!', 'Please assign a hotkey.', 0, $editGui) == 1 Then
                GUISetState(@SW_ENABLE, $editGui)
                WinActivate($editGui)
            EndIf
    Else
        Local $childRead = ''
        Local $error = False
        Local $opts = ''
        If GUICtrlRead($adminCbox) == 1 Then $opts &= 'Admin'
        If GUICtrlRead($oneCbox) == 1 Then
            If $opts == 'Admin' Then $opts &= ', '
            $opts &= 'Singleton'
        EndIf
        If BitAND(GUICtrlRead($ctrlEditCbox), $GUI_CHECKED) == 1 Then $childRead &= 'Ctrl + '
        If BitAND(GUICtrlRead($altEditCbox), $GUI_CHECKED) == 1 Then $childRead &= 'Alt + '
        If BitAND(GUICtrlRead($shiftEditCbox), $GUI_CHECKED) == 1 Then $childRead &= 'Shift + '
        If BitAND(GUICtrlRead($winEditCbox), $GUI_CHECKED) == 1 Then $childRead &= 'Win + '
        $childRead &= GUICtrlRead($keyEditDown)
        For $x = 0 To _GUICtrlListView_GetItemCount($ListView1) - 1
            If $x <> Number(_GUICtrlListView_GetSelectedIndices($ListView1)) And $childRead == _GUICtrlListView_GetItemText($ListView1, $x, 1) Then
                $error = True
                ExitLoop
            EndIf
        Next
        If $error Or $childRead == _returnToggleHotkey() Then
            GUISetState(@SW_DISABLE, $editGui)
            If MsgBox(48, 'Oops!', 'Hotkey alreay assigned. Please choose another hotkey.', 0, $editGui) == 1 Then
                $error = False
                GUISetState(@SW_ENABLE, $editGui)
                WinActivate($editGui)
            EndIf
        Else
            _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), $childRead, 1)
            If GUICtrlRead($fileRdo) == 1 Then
                $fileParam = GUICtrlRead($fileInp)
                If GUICtrlRead($cmdCbox) == $GUI_CHECKED Then
                    _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), $fileParam, 2)
                    _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 'Command', 0)
                Else
                    If GUICtrlRead($fileParamInp) <> '' Then $fileParam = $fileParam&' [Parameters] '&GUICtrlRead($fileParamInp)
                    _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), $fileParam, 2)
                    _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 'File', 0)
                EndIf
            ElseIf GUICtrlRead($folderRdo) == 1 Then
                _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), GUICtrlRead($folderInp), 2)
                _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 'Folder', 0)
            ElseIf GUICtrlRead($specialRdo) == 1 Then
                _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), GUICtrlRead($specialDown), 2)
                _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 'System', 0)
            ElseIf GUICtrlRead($windowRdo) == 1 Then
                _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 'Window', 0)
                If GUICtrlRead($windowDown) == 'Custom Move and/or Resize' Then
                    Local $m = ''
                    Local $r = ''
                    If GUICtrlRead($moveCbox) == $GUI_CHECKED Then $m = 'Move to '&GUICtrlRead($movexInp)&','&GUICtrlRead($moveyInp)
                    If GUICtrlRead($resizeCbox) == $GUI_CHECKED Then $r = 'Resize to '&GUICtrlRead($resizewInp)&'x'&GUICtrlRead($resizehInp)
                    If $m <> '' and $r <> '' Then
                        $m = $m&' & '&$r
                    Else
                        $m = $m&$r
                    EndIf
                    _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), $m, 2)
                Else
                    _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), GUICtrlRead($windowDown), 2)
                EndIf
            ElseIf GUICtrlRead($urlRdo) == 1 Then
                GUICtrlSetData($urlInp, StringReplace(StringReplace(StringReplace(GUICtrlRead($urlInp), 'https://', ''), 'http://', ''), 'ftp://', ''))
                _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), GUICtrlRead($urlDown)&GUICtrlRead($urlInp), 2)
                _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 'URL', 0)
            ElseIf GUICtrlRead($txtRdo) == 1 Then
                $hkztxt = StringReplace(GUICtrlRead($txtEdit), @CRLF, '[New Line]')
                _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), $hkztxt, 2)
                _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), 'Text', 0)
            EndIf
            _GUICtrlListView_SetItemText($ListView1, Number(_GUICtrlListView_GetSelectedIndices($ListView1)), $opts, 3)
            _hideChild()
        EndIf
    EndIf
EndFunc

Func _saveBtn()
    _guiToIni($ini)
    _iniToApply($ini)
    If BitAND(GUICtrlRead($startupCbox), $GUI_CHECKED) == 1 Then
        RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", $title, "REG_SZ", '"'&@ScriptFullPath&'"')
    Else
        RegDelete("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", $title)
    EndIf
    GUIDelete($mainGui)
    $winVis = False
EndFunc

Func _guiDel()
    GUIDelete($mainGui)
    $winVis = False
EndFunc

Func _hideChild()
    GUISetState(@SW_ENABLE, $mainGui)
    GUIDelete($editGui)
    WinActivate($mainGui)
EndFunc

Func _fileBrowse()
    Local $sFile = FileOpenDialog('Select a file...', '', "All (*.*)", $FD_FILEMUSTEXIST, '', $editGui)
    If @error Then
        ;do nothing
    Else
        GUICtrlSetData($fileInp, $sFile)
    EndIf
EndFunc

Func _folderBrowse()
    Local $sFolder = FileSelectFolder('Select a folder...', "", Default, '', $editGui)
	If @error Then
		;do nothing
    Else
        ;define clsid list
        For $c = 0 To UBound($clsid, 1)-1
            If _strCompare($sFolder, $clsid[$c][1]) Then
                $sFolder = $clsid[$c][0]
                ExitLoop
            EndIf
        Next
		GUICtrlSetData($folderInp, $sFolder)
	EndIf
EndFunc

Func _exit()
    Exit
EndFunc

Func _encodeKey($k)
    If StringLen($k) > 1 Then
        If $k == 'Escape' Then $k = 'ESCAPE'
        If $k == 'Print Screen key' Then $k = 'PRINTSCREEN'
        If $k == 'Pause key' Then $k = 'PAUSE'
        If $k == 'Page Up' Then $k = 'PGUP'
        If $k == 'Page Down' Then $k = 'PGDN'
        If $k == 'Numpad 1' Then $k = 'NUMPAD1'
        If $k == 'Numpad 2' Then $k = 'NUMPAD2'
        If $k == 'Numpad 3' Then $k = 'NUMPAD3'
        If $k == 'Numpad 4' Then $k = 'NUMPAD4'
        If $k == 'Numpad 5' Then $k = 'NUMPAD5'
        If $k == 'Numpad 6' Then $k = 'NUMPAD6'
        If $k == 'Numpad 7' Then $k = 'NUMPAD7'
        If $k == 'Numpad 8' Then $k = 'NUMPAD8'
        If $k == 'Numpad 9' Then $k = 'NUMPAD9'
        If $k == 'Numpad 0' Then $k = 'NUMPAD0'
        If $k == 'Numpad Dot' Then $k = 'NUMPADDOT'
        If $k == 'Numpad Divide' Then $k = 'NUMPADDIV'
        If $k == 'Numpad Multiply' Then $k = 'NUMPADMULT'
        If $k == 'Numpad Subtract' Then $k = 'NUMPADSUB'
        If $k == 'Numpad Add' Then $k = 'NUMPADADD'
        $k = '{'&StringUpper($k)&'}'
    ElseIf $k == '=' Then
        $k = '{HkzEq}'
    Else
        $k = StringLower($k)
    EndIf
    ;~ ConsoleWrite('encode: '&$k&@LF)
    Return $k
EndFunc

Func _decodeKey($k)
    If StringLen($k) > 1 Then
        If $k == '{ESCAPE}' Then $k = 'Escape'
        If $k == '{PRINTSCREEN}' Then $k = 'Print Screen key'
        If $k == '{PAUSE}' Then $k = 'Pause key'
        If $k == '{PGUP}' Then $k = 'Page Up'
        If $k == '{PGDN}' Then $k = 'Page Down'
        If $k == '{NUMPAD1}' Then $k = 'Numpad 1'
        If $k == '{NUMPAD2}' Then $k = 'Numpad 2'
        If $k == '{NUMPAD3}' Then $k = 'Numpad 3'
        If $k == '{NUMPAD4}' Then $k = 'Numpad 4'
        If $k == '{NUMPAD5}' Then $k = 'Numpad 5'
        If $k == '{NUMPAD6}' Then $k = 'Numpad 6'
        If $k == '{NUMPAD7}' Then $k = 'Numpad 7'
        If $k == '{NUMPAD8}' Then $k = 'Numpad 8'
        If $k == '{NUMPAD9}' Then $k = 'Numpad 9'
        If $k == '{NUMPAD0}' Then $k = 'Numpad 0'
        If $k == '{NUMPADDOT}' Then $k = 'Numpad Dot'
        If $k == '{NUMPADDIV}' Then $k = 'Numpad Divide'
        If $k == '{NUMPADMULT}' Then $k = 'Numpad Multiply'
        If $k == '{NUMPADSUB}' Then $k = 'Numpad Subtract'
        If $k == '{NUMPADADD}' Then $k = 'Numpad Add'
        If $k == '{HkzEq}' Then $k = '='
        $k = _StringTitleCase($k)
    Else
        $k = StringUpper($k)
    EndIf
    $k = StringReplace(StringReplace($k, '{', ''), '}', '')
    ;~ ConsoleWrite('decode: '&$k&@LF)
    Return $k
EndFunc

Func _returnToggleHotkey()
    Local $appHotkey = ''
    If BitAND(GUICtrlRead($ctrlCbox), $GUI_CHECKED) == 1 Then $appHotkey &= 'Ctrl + '
    If BitAND(GUICtrlRead($altCbox), $GUI_CHECKED) == 1 Then $appHotkey &= 'Alt + '
    If BitAND(GUICtrlRead($shiftCbox), $GUI_CHECKED) == 1 Then $appHotkey &= 'Shift + '
    If BitAND(GUICtrlRead($winCbox), $GUI_CHECKED) == 1 Then $appHotkey &= 'Win + '
    $appHotkey &= GUICtrlRead($keyDown)
    Return($appHotkey)
EndFunc

Func _strCompare($string1, $string2)
    If StringCompare($string1, $string2) == 0 Then
        Return True
    Else
        Return False
    EndIf
EndFunc

Func _sort()
    _GUICtrlListView_SortItems($ListView1, GUICtrlGetState($ListView1))
EndFunc

Func _WinGetTrans($hWnd, ByRef $Transparency, $asColorRef = False)
    $i_transcolor = -1
    $Transparency = -1
    Local $aResult = DllCall("user32.dll", "bool", "GetLayeredWindowAttributes", "hwnd", $hWnd, "dword*", $i_transcolor, "byte*", $Transparency, "dword*", 0)
    If @error Then Return SetError(@error, @extended, 0)
    If Not $asColorRef Then
        $aResult[2] = Int(BinaryMid($aResult[2], 3, 1) & BinaryMid($aResult[2], 2, 1) & BinaryMid($aResult[2], 1, 1))
    EndIf
    $i_transcolor = $aResult[2]
    $Transparency = $aResult[3]
    Return $aResult[4]
EndFunc

Func _transPlus($hWnd)
    Local $o = 17 ;0 to 255
    Local $iInfo, $iTransparency
    $iInfo = _WinGetTrans($hWnd, $iTransparency)
    If Not @error Then
        If $iTransparency > $o Then
            WinSetTrans($hWnd, '', $iTransparency-$o)
        Else
            WinSetTrans($hWnd, '', 0)
        EndIf
    EndIf
EndFunc

Func _transMinus($hWnd)
	Local $o = 17 ;0 to 255
    Local $iInfo, $iTransparency
    $iInfo = _WinGetTrans($hWnd, $iTransparency)
    If Not @error Then
        If $iTransparency + $o > 255 Then
            WinSetTrans($hWnd, '', 255)
        Else
            WinSetTrans($hWnd, '', $iTransparency+$o)
        EndIf
    EndIf
EndFunc

Func _ghostToggle($hWnd)
    If BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE), $WS_EX_TRANSPARENT) Then
        _WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE), BitNOT($WS_EX_TRANSPARENT)))
    Else
	    _WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, BitOR(_WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE), $WS_EX_TRANSPARENT))
	EndIf
EndFunc

Func _typeCheck($hWnd)
    $wpos = WinGetPos($hWnd)
    $csiz = WinGetClientSize($hWnd)
    ;~ ConsoleWrite($csiz[0]&' '&$wpos[2]&@LF)
    ;~ ConsoleWrite($csiz[1]&' '&$wpos[3]&@LF)
    If @OSVersion == 'WIN_10' Then
        If $csiz[0] <> $wpos[2] And $wpos[2] - $csiz[0] > 15 And @OSVersion == 'WIN_10' Then
            $xf = 14
            $yf = 7
        Else
            $xf = 0
            $yf = 0
        EndIf
    Else
        $xf = 0
        $yf = 0
    EndIf
EndFunc

Func _isReal($hWnd)
    $vWinStyle = _WinAPI_GetWindowLong($hWnd, $GWL_STYLE)
    If BitAND(WinGetState($hWnd), 4) = 4 _
        And WinGetTitle($hWnd) <> '' _
        And WinGetTitle($hWnd) <> 'Snap Assist' _
        And BitAND($vWinStyle, $WS_VISIBLE) = $WS_VISIBLE _
        And BitAND($vWinStyle, $WS_MINIMIZE) <> $WS_MINIMIZE Then Return True
    ;~ If BitAND(WinGetState($hWnd), 4) = 4 _
    ;~     And BitAND($vWinStyle, $WS_VISIBLE) = $WS_VISIBLE _
    ;~     And BitAND($vWinStyle, $WS_MINIMIZE) <> $WS_MINIMIZE _
    ;~     And BitAND($vWinStyle, $WS_MINIMIZEBOX) = $WS_MINIMIZEBOX _
    ;~     And BitAND($vWinStyle, $WS_MAXIMIZEBOX) = $WS_MAXIMIZEBOX Then Return True
EndFunc

Func _topToggle($hWnd)
    If BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE), $WS_EX_TOPMOST) Then
        WinSetOnTop($hWnd, '', $WINDOWS_NOONTOP)
    Else
        WinSetOnTop($hWnd, '', $WINDOWS_ONTOP)
    EndIf
EndFunc

Func _setPriority($hWnd, $priority=2)
    ProcessSetPriority(_ProcessGetName(WinGetProcess($hWnd, "")), $priority)
EndFunc

Func _GetWindowsExplorerPath($hWnd)
    If Not IsHWnd($hWnd) Then Return SetError(1)
    Local $aWinList = WinList("[REGEXPCLASS:(Explore|Cabinet)WClass]")
    While 1
        For $i = 1 To UBound($aWinList) - 1
            If $hWnd == $aWinList[$i][1] Then ExitLoop 2
        Next
        Return SetError(2)
    WEnd
    Local $oShellApp = ObjCreate("Shell.Application")
    If Not IsObj($oShellApp) Then Return SetError(3)
    Local $oShellApp_Windows = $oShellApp.Windows()
    If Not IsObj($oShellApp_Windows) Then Return SetError(4)
    For $oShellApp_Inst In $oShellApp_Windows
        If $oShellApp_Inst.hwnd = $hWnd Then ExitLoop
    Next
    Local $iShellApp_Inst_SelectedItems_Count = $oShellApp_Inst.Document.SelectedItems.Count
    Local $sShellApp_Inst_LocationURL = $oShellApp_Inst.LocationURL
    Local $aRet = DllCall('shlwapi.dll', 'long', 'PathCreateFromUrlW', 'wstr', $sShellApp_Inst_LocationURL, 'wstr', '', 'dword*', 65534, 'dword', 0)
    If Not @error And $aRet[0] == 0 Then $sShellApp_Inst_LocationURL = $aRet[2]
    $oShellApp = 0
    $oShellApp_Windows = 0
    $oShellApp_Inst = 0
    Return $sShellApp_Inst_LocationURL
EndFunc

Func _monitors()
    Local $aPos, $aData = _WinAPI_EnumDisplayMonitors()
    If IsArray($aData) Then
        ReDim $aData[$aData[0][0] + 1][5]
        For $i = 1 To $aData[0][0]
            $aPos = _WinAPI_GetPosFromRect($aData[$i][1])
            For $j = 0 To 3
                $aData[$i][$j + 1] = $aPos[$j]
            Next
        Next
        Return $aData
    EndIf
EndFunc

Func _moveToMonitor($hWnd, $monitors, $dir = False)
    ;~ For $i = 1 To $monitors[0][0]
    ;~     ConsoleWrite($monitors[$i][0]&': X='&$monitors[$i][1]&' Y='&$monitors[$i][2]&' W='&$monitors[$i][3]&' H='&$monitors[$i][4]&@LF)
    ;~ Next
    For $i = 1 To $monitors[0][0]
        If _WinAPI_MonitorFromWindow($hWnd, $MONITOR_DEFAULTTONEAREST) == $monitors[$i][0] Then
            ExitLoop
        EndIf
    Next
    Local $pos = WinGetPos($hWnd)
    If $dir Then ;right
        If $i >= $monitors[0][0] Then
            $n = 1
        Else
            $n = $i + 1
        EndIf
    Else
        If $i <= 1 Then
            $n = $monitors[0][0]
        Else
            $n = $i - 1
        EndIf
    EndIf
    ;get old monitor's area
    Local $oArea = _getMonitorArea($monitors[$i][0])
    Local $oAreaWidth = _Max($oArea[0], $oArea[1]) - _Min($oArea[0], $oArea[1])
    Local $oAreaHeight = _Max($oArea[2], $oArea[3]) - _Min($oArea[2], $oArea[3])
    ;get new monitor's area
    Local $area = _getMonitorArea($monitors[$n][0])
    Local $areaWidth = _Max($area[0], $area[1]) - _Min($area[0], $area[1])
    Local $areaHeight = _Max($area[2], $area[3]) - _Min($area[2], $area[3])
    ;main vars
    Local $oxVal = $pos[0] - $monitors[$i][1]
    Local $oyVal = $pos[1] - $monitors[$i][2]
    Local $wWin = $pos[2]
    Local $hWin = $pos[3]
    _typeCheck($hWnd)
    ;calculate the new range
    Local $xMul = $areaWidth/$oAreaWidth
    Local $yMul = $areaHeight/$oAreaHeight
    Local $nxVal = ((($oxVal - 0) * ($monitors[$n][3] - 0)) / ($monitors[$i][3] - 0) + 0)/$xMul
    Local $nyVal = ((($oyVal - 0) * ($monitors[$n][4] - 0)) / ($monitors[$i][4] - 0) + 0)/$yMul
    ;check if window was fullscreened by Windows
    If BitAND(WinGetState($hWnd), 32) Then
        $wWin = $areaWidth
        $hWin = $areaHeight
    EndIf
    ;check if prev window height and width was 100% so we can fullscreen it in the next monitor
    If $wWin - $xf == $oAreaWidth And $hWin - $yf == $oAreaHeight Then ;check for fullscreen
        $wWin = $areaWidth + $xf
        $hWin = $areaHeight + $yf
        $nxVal = -($xf/2)
    EndIf
    ;check if prev window height or width was 100%
    If $wWin - $xf == $oAreaWidth Then $wWin = $areaWidth + $xf
    If $hWin - $yf == $oAreaHeight Then $hWin = $areaHeight + $yf
    ;check if window is still bigger than the next monitor
    If $wWin - $xf > $areaWidth Then $wWin = $areaWidth + $xf
    If $hWin - $yf > $areaHeight Then $hWin = $areaHeight + $yf
    ;check if window can fit by shriking the positiong values
    If $nxVal + ($wWin - $xf) >= $areaWidth Then $nxVal = ($areaWidth - $wWin + $xf)-($xf/2)
    If $nyVal + ($hWin - $yf) >= $areaHeight Then $nyVal = ($areaHeight - $hWin + $yf)
    ;check if window was touching right and bottom edges of previous monitor
    If $wWin + $oxVal - ($xf/2) == $oAreaWidth Then $nxVal = $areaWidth - ($wWin - ($xf/2))
    If $hWin + $oyVal - ($yf) == $oAreaHeight Then $nyVal = $areaHeight - ($hWin - ($yf))
    ;check if prev window was split in half on x
    If _almostEqual(($oAreaWidth/2), ($pos[2]-$xf), 0, 1) Then $wWin = ($areaWidth/2)+$xf
    ;check if prev window was split in half on y
    If _almostEqual(($oAreaHeight/2), ($pos[3]-$yf), 0, 1) Then $hWin = ($areaHeight/2)+$yf
    ;check if prev window was split in thirds
    If _almostEqual(($oAreaWidth/3), ($pos[2]-$xf), 0 ,1) Then $wWin = ($areaWidth/3)+$xf
    ;check if window was centered on x
    If _almostEqual(($oArea[0]+($oAreaWidth/2)), ($pos[0]+($pos[2]/2)), 0, 1) Then $nxVal = ($areaWidth/2) - ($wWin/2)
    ;check if window was centered on y
    If _almostEqual(($oArea[2]+($oAreaHeight/2)), (($pos[1]+($pos[3]/2))-($yf/2)), 0, 1) Then $nyVal = (($areaHeight/2) - ($hWin/2)) + ($yf/2)
    ;if half window is at x right
    If _almostEqual(($pos[0]-$monitors[$i][1])+($xf/2), ($oAreaWidth/2), 0, 1) Then $nxVal = ($areaWidth/2)-($xf/2)
    ;if half window is at y btm
    If _almostEqual($pos[1]-$monitors[$i][2], ($oAreaHeight/2), 0, 1) Then $nyVal = ($areaHeight/2)
    ;if third window is at third x mid
    If _almostEqual((($pos[0]-$monitors[$i][1])+($xf/2)), ($oAreaWidth/3), 0, 1) Then $nxVal = ($areaWidth/2)-($wWin/2)
    ;if third window is at third x right
    If _almostEqual(($pos[0]-$monitors[$i][1])+($xf/2), ($oAreaWidth/3)*2, 0, 1) Then $nxVal = Ceiling((($areaWidth/3)*2)-($xf/2))
    ;resize only if the window is resizable
    If _isResizable($hWnd) Then
        WinMove($hWnd, '', ($monitors[$n][1] + $nxVal), ($monitors[$n][2] + $nyVal), ($wWin), ($hWin))
    Else
        WinMove($hWnd, '', ($monitors[$n][1] + $nxVal), ($monitors[$n][2] + $nyVal))
    EndIf
EndFunc

Func _almostEqual($a, $b, $min, $max)
    $val = $a - $b
    If Abs($val) <= $max And Abs($val) >= $min Then Return True
EndFunc

Func _isResizable($hWnd)
    If BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_STYLE), $WS_SIZEBOX) Or _
    BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_STYLE), $WS_THICKFRAME) Or _
    BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_STYLE), $WS_MAXIMIZEBOX) Then Return True
    ;~ If BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_STYLE), $WS_MAXIMIZEBOX) Then Return True
EndFunc

Func _getMonitorArea($monitor)
    Local $monitorInfo = _WinAPI_GetMonitorInfo($monitor)
    Local $area[] = [DllStructGetData($monitorInfo[1], 1), DllStructGetData($monitorInfo[1], 3), DllStructGetData($monitorInfo[1], 2), DllStructGetData($monitorInfo[1], 4)]
    If @error Then
        Return
    EndIf
    Return $area
EndFunc