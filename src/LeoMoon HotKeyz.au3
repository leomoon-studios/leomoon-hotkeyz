;~ #NoTrayIcon
;~ #RequireAdmin

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_Icon_Add=resources\main.ico
#AutoIt3Wrapper_Res_Icon_Add=resources\disabled.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#pragma compile(Out, ..\build\LeoMoon HotKeyz.exe)
#pragma compile(Icon, resources\main.ico)
#pragma compile(Compression, 9)
#pragma compile(Comments, This program is freeware.)
#pragma compile(ProductName, LeoMoon HotKeyz)
#pragma compile(FileDescription, LeoMoon HotKeyz)
#pragma compile(FileVersion, 1.8.12.0)
#pragma compile(LegalCopyright, Amin Babaeipanah)
#pragma compile(CompanyName, LeoMoon Studios Inc.)
#pragma compile(LegalTrademarks, LeoMoon Studios Inc.)
#pragma compile(ProductVersion, 1.8.12.0)

#include <Misc.au3>
#include <resources\ExtMsgBox.au3>

#include <core\AppConstants.au3>
#include <core\ActionCatalog.au3>
#include <core\HotkeyRepository.au3>
#include <gui\GuiState.au3>
#include <actions\TextActions.au3>
#include <actions\SystemActions.au3>
#include <actions\WindowActions.au3>
#include <actions\ProcessActions.au3>
#include <actions\ActionDispatcher.au3>
#include <app\HotkeyRegistry.au3>
#include <app\ErrorReporter.au3>
#include <app\TrayController.au3>
#include <gui\HotkeyEditor.au3>
#include <gui\MainWindow.au3>
#include <app\Application.au3>

Opt("MustDeclareVars", 1)
AutoItSetOption("ExpandEnvStrings", 1)
Opt("TrayMenuMode", 3)
Opt("TrayOnEventMode", 0)
Opt("TrayAutoPause", 0)
Opt("GUIOnEventMode", 1)
Opt("GUICloseOnESC", 0)
Opt("SendKeyDownDelay", 0)

_Application_Main()

Func _Application_Main()
    If @OSArch <> "X86" Then _WinAPI_Wow64EnableWow64FsRedirection(False)
    _ExtMsgBoxSet(0, 0, -1, -1, 9, "Tahoma")
    If _Singleton($APP_TITLE, 1) = 0 Then
        _AppError_Report($APP_TITLE & " is currently running", 1, 0)
        Exit
    EndIf
    OnAutoItExitRegister("_Application_Shutdown")
    If Not _Application_Compose($APP_INI_PATH) Then
        _AppError_Report("Startup failed because application modules could not be initialized", @error, @extended)
        Exit 1
    EndIf
    While 1
        _TrayController_ProcessEvents()
        Sleep(10)
    WEnd
EndFunc
