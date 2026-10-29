# Changelog

## Unreleased

- Show hotkey action failures, unavailable startup shortcuts, and website-opening failures as nonblocking tray notifications.
- Reduced fresh Settings window startup time while retaining profile and hotkey validation.
- Fixed program-only options remaining checked or saved after changing a hotkey to another action type.
- Reduced Add/Edit window startup delay.
- Improved Settings save performance.
- Added per-hotkey left/right Ctrl, Alt, Shift, and Win selection, plus Caps Lock, Num Lock, and Scroll Lock On/Off conditions. All selected requirements must match for the hotkey to run.
- Added a Conditions dialog and restriction summaries in Settings. Modifier sides and lock conditions persist through profile saves, imports, and restarts.
- Added an **Open/close optical drive tray** action that reads the current tray state before opening or closing it.
- Added separate open/close optical-drive tray and actions with a drive selector and Refresh button.
- Restored double-clicking the tray icon to enable or disable HotKeyz.

## 2.0.0 - 2026-10-26

- Added a Windows release workflow that validates source, runs strict checks, builds the x86 app, and packages portable and installer artifacts.
- Added tag-based GitHub Release publishing with the verified Windows files and generated commit notes.
- Added a manual no-tag build trigger for validating Windows packages before a release tag is created.
- Updated the installer to use Inno Setup's default setup icon.
- Fixed Windows build version metadata injection for CRLF source files.
- Fixed the tray menu Settings command by binding callbacks to their explicit tray item IDs.
- Hotkey conflicts no longer prevent the application from launching. The app lists unavailable shortcuts and continues with the shortcuts it can register.
- Changed the default Turn Off Monitors And Lock shortcut from Ctrl + Win + L, which is reserved in Win 11, to Ctrl + Alt + L.
- Added a Windows installer option to start HotKeyz with Windows for the current user, enabled by default.
- Added a user guide covering Settings, hotkey actions, text tags, profiles, and troubleshooting.
- Fixed the Settings window not opening from the tray menu after the GUI refactor.
- Fixed saving hotkeys when old shortcuts were already unregistered, and improved restoration when registration fails.
- Fixed a false error when saving with Start with Windows disabled and no startup registry entry present.
- Fixed a crash when selecting a system action before assigning a complete hotkey.
- Fixed transparency adjustments on windows that had not previously been made transparent, and corrected Numpad Subtract and Multiply key encoding. Previously saved incorrect spellings are recognized on load.
- Restored support for the legacy Resize 3x2 and Hide window actions in imported profiles.
- Fixed tagged folder paths being treated as files before runtime tags such as `<USERNAME>` are expanded.
- Fixed Unicode profile text being misread, including UTF-8 files without a byte-order mark. Saving now writes a Unicode-compatible INI and retains the previous file as a backup.
- Fixed file hotkeys to launch with the target file's directory as their working directory, including batch files started after Windows login.
- Improved missing-target errors to show the affected hotkey and expanded path.
- Added regression coverage for settings, legacy profiles, Unicode, startup, window actions, and file working directories.

## 1.8.12 - 2023-06-10

- Compiled with the latest compiler for better Windows 11 support.

## 1.8.11 - 2023-02-02

- Added more Active Window actions.
  - Added Generate Random Password (Letters and Numbers).
- Fixed date-based text macros not evaluating properly.

## 1.8.10 - 2023-01-15

- Added more Active Window actions.
  - Added Generate Random Password (Letters).
  - Added Generate Random Password (Numbers).
  - Added Generate Random Password (PPP).
  - Added Generate Random UUID.
  - Added MD5 Selected Text.
  - Added SHA1 Selected Text.
  - Added SHA-256 Selected Text.
  - Added SHA-512 Selected Text.
  - Added Base64 Encode Selected Text.
  - Added Base64 Decode Selected Text.

## 1.8.9 - 2022-12-18

- Added more Active Window actions.
  - Upper Case Selected Text.
  - Lower Case Selected Text.
  - Title Case Selected Text.
  - Reverse Selected Text.

## 1.8.8 - 2022-12-17

- Added the Enter key to hotkey selection.
- Fixed the delay when using text macros.

## 1.8.7 - 2022-04-27

- Added Turn Off Monitors And Lock under system actions.

## 1.8.6 - 2021-12-19

- Minor bug fix.

## 1.8.5 - 2021-05-16

- Fixed a bug with Empty Clipboard.

## 1.8.4 - 2021-05-16

- Changed the default hotkey to Ctrl + Win + Comma for new setups.
- Added a Run as admin checkbox option when running a program.
- Added a Singleton checkbox option when running a program.
- Added Empty Clipboard to system actions.
- Added the Numpad Dot key to hotkey selection.
- Added new text macro tags.
  - `<COMPUTERNAME>`
  - `<USERNAME>`
- Improved the Batch command option.
- Fixed Microsoft Office resize issues.
- Bug fixes.

## 1.8.3 - 2020-06-09

- Added new Active Window actions.
  - Set Process Priority to Low.
  - Set Process Priority to Below Normal.
  - Set Process Priority to Normal.
  - Set Process Priority to Above Normal.
  - Set Process Priority to Hight.
  - Set Process Priority to Realtime.
- Fixed the application certificate.

## 1.8.2 - 2020-06-01

- Added new Active Window actions.
  - Move to Next Monitor.
  - Move to Previous Monitor.
- Minor UI changes.
- Bug fixes.

## 1.8.1 - 2020-05-23

- Removed actions.
  - Restart (Forced).
  - Shutdown (Forced).
- Breaking changes: delete and add these actions again if you use them.
  - Lock.
  - Log Off.
  - Restart.
  - Shutdown.
- Added new System actions.
  - Empty Recycle Bin.
  - Turn Off Monitors.
  - Start Screensaver.
  - Start Screensaver And Lock.
- Added new Active Window actions.
  - Move Center.
  - Move Top Left.
  - Move Top Mid.
  - Move Top Right.
  - Move Bottom Left.
  - Move Bottom Mid.
  - Move Bottom Right.
- Fixed lag when moving, resizing, and snapping windows.
- Fixed lag when changing transparency.
- Fixed an issue with running programs with parameters.
- Improved the Transparency module.
- Added Escape and Equal Sign keys to hotkey selection.
- Minor UI changes.

## 1.8.0 - 2020-05-18

- Added a new Active Window section with these actions.
  - Close.
  - Minimize.
  - Terminate.
  - Transparency +.
  - Transparency -.
  - Toggle On Top.
  - Take Screenshot.
  - Snap Fullscreen.
  - Snap Top (1x2).
  - Snap Bottom (1x2).
  - Snap Left (2x1).
  - Snap Right (2x1).
  - Snap Left (3x1).
  - Snap Mid (3x1).
  - Snap Right (3x1).
  - Snap Top Left (2x2).
  - Snap Top Right (2x2).
  - Snap Bottom Left (2x2).
  - Snap Bottom Right (2x2).
  - Snap Top Left (3x2).
  - Snap Top Mid (3x2).
  - Snap Top Right (3x2).
  - Snap Bottom Left (3x2).
  - Snap Bottom Mid (3x2).
  - Snap Bottom Right (3x2).
  - Toggle Ghost (Advanced).
  - Custom Move and/or Resize.

## 1.7.3 - 2020-05-02

- Added Windows Settings, Volume Up, Volume Down, Volume Mute, Media Play/Pause, Media Next, Media Previous, Media Stop, Lock, Log Off, Restart, Restart (Forced), Shutdown, and Shutdown (Forced) to special actions.
- Added Pause and Print Screen keys to hotkey selection.
- Added the ability to define parameters when running an application.
- Added the ability to paste custom text with a hotkey.
- Added text macro variables.
  - `<HOUR>` pastes the current hour.
  - `<MINUTE>` pastes the current minute.
  - `<SECOND>` pastes the current second.
  - `<YEAR>` pastes the current four-digit year.
  - `<MONTHNAME>` pastes the current month name.
  - `<MONTHNUMBER>` pastes the current month number.
  - `<DAYNAME>` pastes the current day name.
  - `<DAYNUMBER>` pastes the current day of the month.
- Minor bug fixes.

## 1.7.2

- Added an option to assign a hotkey to a URL.
- Minor bug fixes.

## 1.7.1

- Rebranded LeoMoon PowerKeys as LeoMoon HotKeyz.
- Minor improvements.
- Added a digital signature to the application.

## 1.7.0

- Added the Settings GUI with a custom hotkey manager.
- Major improvements.

## 1.6.0

- Added support for Windows environment variables.

## 1.5.0

- Added the ability to assign a custom hotkey that toggles LeoMoon HotKeyz.

## 1.4.0

- Added double-clicking the icon to toggle the application.

## 1.3.0

- Optimized the hotkey engine.

## 1.2.0

- Minor bug fix.

## 1.1.0

- Minor changes.

## 1.0.0

- Initial release.
