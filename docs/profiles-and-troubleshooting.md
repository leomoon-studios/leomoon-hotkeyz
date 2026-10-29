# Profiles and troubleshooting

[Documentation home](../README.md#user-documentation) · [Getting started](getting-started.md) · [Hotkey actions](actions.md) · [Text and tags](text-and-tags.md)

## Where settings are stored

HotKeyz stores `LeoMoon HotKeyz.ini` beside the executable. The installer normally places the executable under the current user's local application-data Programs folder; a portable copy stores the INI in its extracted folder. The folder must be writable by your account. A new profile is created with default shortcuts if no INI file exists.

The optional startup entry is separate from the INI: it is the `LeoMoon HotKeyz` value under `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run`. It affects only the current Windows account. The installer offers it checked by default, and the **Start with Windows** checkbox in Settings changes the same value.

## Back up or move a profile

1. Exit HotKeyz using its tray menu.
2. Copy `LeoMoon HotKeyz.ini` from beside the old executable to a safe location.
3. Put a copy beside the executable on the new computer, then start HotKeyz.
4. Check paths and shortcuts in Settings. Paths to drives, files, and folders must exist on the new computer; Windows or other applications may already use some shortcuts.
5. If you want the new copy to start with Windows, enable **Start with Windows** in its Settings and save.

User-specific paths can use `<USERNAME>`, as described in [Text and tags](text-and-tags.md#dynamic-tags). Review imported commands and actions before using them.

## Saving and recovery

HotKeyz writes a temporary `LeoMoon HotKeyz.ini.tmp`, verifies the new hotkey records, and replaces the live INI. A successful replacement keeps the previous file as `LeoMoon HotKeyz.ini.bak`. Keep a separate backup before large edits or manual changes.

To restore a backup, exit HotKeyz, save a copy of the current INI elsewhere, and copy the desired `.bak` file to `LeoMoon HotKeyz.ini` beside the executable. Start HotKeyz and check the restored shortcuts. A backup represents the preceding successful configuration and may not contain your most recent edits.

The app reads UTF-8 with or without a byte-order mark, UTF-16 with a byte-order mark, and legacy Windows ANSI text when the bytes are not valid UTF-8. Unmarked encodings can be ambiguous: valid UTF-8 takes precedence. A successful save writes UTF-16 with a byte-order mark so Unicode text is preserved by Windows INI functions. If an old file is already corrupted, keep the original and restore the correct text from a clean backup.

Development builds recognize a versioned `[HotkeyRestrictions]` section and a companion `[HotkeyRestrictedActions]` section. Restricted records use a placeholder in `[Hotkeys]` so older readers do not receive the original action as an ordinary unrestricted entry. The current development build enforces lock conditions and modifier-side restrictions; see [conditions and modifier sides](getting-started.md#lock-conditions). Do not open or save a restricted profile with an older HotKeyz version; older versions cannot enforce its conditions and may damage its metadata. Preserve a separate backup before changing versions.

## INI representation

The Settings interface is the recommended way to edit hotkeys. For reference, the file has an `[Options]` section with the main toggle and a `[Hotkeys]` section mapping key combinations to actions:

```ini
[Options]
Main=^#,
[Hotkeys]
^!n=C:\Windows\System32\notepad.exe
^!{PGDN}=[HkzWM]Minimize
^!d=[HkzSndTxt]Today is <YYYY-MM-DD>
```

Modifier characters are `^` for Ctrl, `!` for Alt, `+` for Shift, and `#` for Win. Named keys use braces, for example `^!{LEFT}`. The equals key is represented in INI keys as `{HkzEq}`. Legacy value markers include `[HkzWM]` for window actions, `[HkzSndTxt]` for text, `[HkzCmd]` for an advanced command, `[HkzExe]` for system actions, `[HkzSysSnd]` for media actions, `[HkzParam]` for file parameters, `[HkzNL]` for a text line break, and `[HkzOptAdmin]` / `[HkzOptOne]` for options. Use Settings where possible; invalid or duplicate entries can prevent registration.

## Troubleshooting

### The tray icon or Settings window is missing

Check the notification area's hidden-icons menu and confirm that HotKeyz is running. Right-click its tray icon and choose **Settings...**. If another instance is already running, use that instance or exit it before launching another copy.

### Optical drive shortcuts

The saved system action includes its drive letter, for example `[HkzExe]Open optical drive tray D:` or `[HkzExe]Close optical drive tray E:`. There are no separate command-line parameters. Copying a profile preserves that letter; it may need changing on another computer. Bulk Save does not require the drive to be connected. The editor checks that a selected letter is currently an optical drive, while execution checks it again and reports missing drives or failed tray commands separately.

### A shortcut does nothing or is unavailable

Check that **Enable LeoMoon HotKeyz** is checked in the tray menu. If Windows or another application already owns the combination, select another hotkey in Settings and save. At startup, unavailable action hotkeys are reported and the app continues with the shortcuts it could register; the main toggle can also be unavailable. Some combinations are reserved by Windows.

For an active-window action, focus a visible, titled window first. Some applications may block window operations or simulated copy/paste. If the target runs with higher privileges, Windows can limit what a non-elevated application can do with it.

### A file or folder target cannot be found

Check the **Target** and hotkey shown in the error. Confirm that the drive is connected and the expanded path exists on this computer. For example, `<USERNAME>` can correctly expand to `home` while `D:\home` still fails if there is no `D:` drive. Update the target in Settings; Windows can resolve bare executable names through its search path, but a concrete path must be accessible.

### Settings cannot be saved

Check that the executable's folder is writable, the chosen main hotkey is complete and distinct from action shortcuts, and no shortcut is duplicated or owned by another application. Check file and folder paths and action values. If a save fails, preserve the live file and backup before trying recovery; see [Saving and recovery](#saving-and-recovery).

### Text has unexpected characters

Restart with the current version and check the original profile's encoding. The app supports UTF-8, UTF-16 with a byte-order mark, and legacy ANSI as described above. If the wrong characters were already saved into the original text, restore a clean backup or correct that text in Settings. Keep the original file before converting it.

### A batch file uses the wrong current directory

For an absolute file target, HotKeyz launches from the file's directory. Make sure the hotkey points to the batch file itself and that the running copy includes the current fix. Advanced commands and bare or relative targets have different working-directory behavior; see [Program and command actions](actions.md#run-a-program-or-open-a-file).

### Error and detail numbers

Error messages can include `error` and `detail` numbers for troubleshooting. Their meanings depend on the operation; they are not universal Windows error codes. When reporting a problem, include the complete message, the affected hotkey and action, and the steps to reproduce it. Avoid sharing private paths or text unless needed to diagnose the issue.
