# Getting started with LeoMoon HotKeyz

[Documentation home](../README.md#user-documentation) · [Hotkey actions](actions.md) · [Text and tags](text-and-tags.md) · [Profiles and troubleshooting](profiles-and-troubleshooting.md)

LeoMoon HotKeyz is a Windows notification-area application that runs actions when you press your chosen global keyboard shortcuts. It can open files, programs, folders and websites; control windows and media; paste text; and perform system actions.

## Install or run

The application targets Windows 10 and Windows 11. Run the installer for a per-user installation, or extract the portable package and run `LeoMoon HotKeyz.exe`. Keep the portable executable in a location where your account can write files: HotKeyz stores its settings next to the executable.

The installer offers a **Start LeoMoon HotKeyz with Windows for the current user** checkbox, checked by default. You can change this later in Settings. The setting applies only to the Windows account that enables it and does not require administrator rights.

Only one instance of HotKeyz runs at a time. After launch, look for its icon in the notification area at the right end of the taskbar. If it is hidden, open the taskbar's hidden-icons menu. HotKeyz remains running there until you exit it.

## Tray menu

Right-click the HotKeyz notification-area icon to open its menu.

| Item                              | What it does                                                                              |
|-----------------------------------|-------------------------------------------------------------------------------------------|
| **Enable LeoMoon HotKeyz**        | Toggles the action hotkeys on or off. The check mark and tray tooltip indicate the state. |
| **Settings...**                   | Opens the settings window. If it is already open, activates it.                           |
| **Visit LeoMoon Studios website** | Opens the LeoMoon website.                                                                |
| **Exit**                          | Closes the application and releases its registered hotkeys.                               |

You can also toggle action hotkeys with the **HotKeyz main hotkey**. On a new profile its default is **Ctrl + Win + comma**. This is an enable/disable shortcut, not a shortcut for opening Settings. When action hotkeys are disabled, the main hotkey and tray menu let you enable them again.

## Settings window

Open **Settings...** from the tray menu. The window contains:

- **Start with Windows**: add or remove HotKeyz from the current user's Windows startup entries when you save. The startup entry runs the current executable; if you move a portable copy, update this setting from the new location.
- **HotKeyz main hotkey**: choose one or more of **Ctrl**, **Alt**, **Shift**, and **Win**, then select the key. This shortcut toggles the other HotKeyz actions. It must not duplicate an action hotkey.
- **Edit hotkeys**: a list of your configured actions. The columns show **Type**, **Hotkey**, **Item**, and **Options**. Click a column heading to sort. Select a row to edit or delete it; double-clicking a row opens its editor.
- **Add New**: opens an empty hotkey editor.
- **Edit Selected**: opens the selected hotkey in the editor.
- **Delete Selected**: asks for confirmation and removes the selected row from the list.
- **Save**: validates and applies the settings, writes the configuration, and closes the window when successful.
- **Cancel** or the window close button: closes Settings without saving the changes in the list.

Changes made in the hotkey editor are first applied to the Settings list. They become active and are written to the profile when you click **Save** in the main Settings window. If a save or startup-setting operation reports an error, read the message before closing Settings; see [Troubleshooting](profiles-and-troubleshooting.md#troubleshooting).

## Add a hotkey

1. Right-click the tray icon and choose **Settings...**.
2. Click **Add New**.
3. Select one action type and fill in its fields. See [Hotkey actions](actions.md) for each choice.
4. Under **Assign a hotkey**, select at least one modifier—**Ctrl**, **Alt**, **Shift**, or **Win**—and a key from the list.
5. Click **OK** to add the row to Settings, then click **Save** to apply it.
6. Press the shortcut in an appropriate window to try it.

The editor disables **OK** when the selection is incomplete, invalid, or duplicates another configured action or the main hotkey. Windows or another application may also already use a shortcut, even if it is not in your HotKeyz list. Choose a different combination if registration fails.

For example, to open a website, choose **Open a URL**, select `https://`, enter `example.com`, assign **Ctrl + Alt + E**, click **OK**, and then **Save**. To edit it later, select its row and click **Edit Selected**.

## Shortcuts in a new profile

If HotKeyz creates a new INI file, it supplies the following defaults. An imported or previously saved profile can differ. The Notepad and Internet Explorer entries use their configured default paths, which may not exist on every machine.

| Shortcut                                                          | Default action                                                                     |
|-------------------------------------------------------------------|------------------------------------------------------------------------------------|
| **Ctrl + Win + ,**                                                | Toggle HotKeyz action shortcuts.                                                   |
| **Ctrl + Alt + L**                                                | Turn off monitors and lock the workstation.                                        |
| **Ctrl + Shift + E** / **Ctrl + Shift + I**                       | Open the configured Notepad / Internet Explorer target.                            |
| **Ctrl + Alt + C** / **U** / **P**                                | Open My Computer / the user profile folder / Control Panel.                        |
| **Ctrl + Alt + Page Down**                                        | Minimize the active window.                                                        |
| **Ctrl + Alt + Numpad Add** / **Subtract** / **0** / **Multiply** | Increase transparency / decrease transparency / toggle on top / take a screenshot. |
| **Ctrl + Alt + Up** / **Left** / **Right**                        | Snap the active window to the full work area / left half / right half.             |
| **Ctrl + Alt + Numpad 7 / 8 / 9**                                 | Snap to the top left / middle / right of a 3×2 grid.                               |
| **Ctrl + Alt + Numpad 4 / 5 / 6**                                 | Snap to the left / middle / right vertical third.                                  |
| **Ctrl + Alt + Numpad 1 / 2 / 3**                                 | Snap to the bottom left / middle / right of a 3×2 grid.                            |
| **Alt + Shift + Right** / **Left**                                | Move the active window to the next / previous monitor.                             |
| **Ctrl + Alt + 0**                                                | Paste a sample date and time template.                                             |

## Lock conditions

In Add/Edit Hotkey, open **Modifiers and conditions...** and set Caps Lock, Num Lock, or Scroll Lock to **Any**, **On**, or **Off**. All specified lock conditions must match for the action to run. **Any** ignores that lock.

The state is captured when HotKeyz begins handling the shortcut. If a blocking dialog delays the callback and you change a lock during that delay, the callback uses the state it reads after the delay. A nonmatching shortcut does nothing: it does not run the action, change the locks, or pass the shortcut to another application.

## Left and right modifiers

In **Modifiers and conditions...**, choose **Either**, **Left**, or **Right** for each enabled Ctrl, Alt, Shift, or Win modifier. For example, Ctrl: Left with F9 runs only when left Ctrl is held. Holding both Ctrl keys also satisfies Left or Right. These selectors apply to action shortcuts; the main enable/disable shortcut continues to accept either side.

Modifier sides are captured when the base key is pressed. You can combine side requirements with lock conditions; every requirement must match. Locks are checked when the queued action begins. The shortcut stays reserved even when a side or lock does not match, so that press is not passed to another application. You cannot assign the same combination twice with different conditions.

Side-specific shortcuts now run in this development build. Physical keyboards, AltGr, and alternate layouts still need release testing. Save/reload your settings after changing keyboard layouts. Long pauses can drop presses; the observer resumes when the application loop resumes. Repeated key-downs repeat the action, and an overloaded queue drops excess presses rather than replaying them indefinitely.

## Next steps

- See [Hotkey actions](actions.md) for program options, commands, system controls, and window management.
- See [Text and tags](text-and-tags.md) for dynamic text and user-specific paths.
- See [Profiles and troubleshooting](profiles-and-troubleshooting.md) for backups, copying settings, and resolving failures.
