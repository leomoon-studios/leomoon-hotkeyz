# Hotkey actions and editor options

[Documentation home](../README.md#user-documentation) · [Getting started](getting-started.md) · [Text and tags](text-and-tags.md) · [Profiles and troubleshooting](profiles-and-troubleshooting.md)

In **Settings → Add New** or **Edit Selected**, choose one action type. Assign a modified shortcut at the bottom, then click **OK** and save the main Settings window. Paths and text can use the supported [tags](text-and-tags.md#dynamic-tags).

## Run a program or open a file

Enter the program or file path, or use **Browse File**. Windows opens the target using the appropriate application or file association. For example, `C:\Windows\System32\notepad.exe` opens Notepad. A bare command such as `code` may be resolved by Windows through the system's executable search path.

Options in this section:

| Control                   | Meaning                                                                                                                                                            |
|---------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Parameters (Optional)** | Arguments passed to the program or file. Quote an argument containing spaces when the target program requires it. HotKeyz launches targets with parameters hidden. |
| **Run as admin**          | Requests the Windows `runas` action. Windows may show a User Account Control prompt.                                                                               |
| **Singleton**             | Does not start another copy if a process with the target's executable name is already running. It checks the process name, not the full path.                      |
| **Advanced command**      | Treats the entered value as a command line instead of a file path. See below.                                                                                      |

Absolute file paths start with the file's directory as their working directory. For example, a batch file on the Desktop sees that directory as `%CD%` and can use relative paths from it. Bare commands and relative targets retain Windows' normal resolution behavior.

The optional parameter `<GetActiveWindowsExplorerPath>` is replaced with the active File Explorer window's path when the action runs. The active window must be a supported Explorer folder and its path must exist. HotKeyz quotes the substituted path, so enter the placeholder without adding another pair of quotes. Other [dynamic tags](text-and-tags.md#dynamic-tags) can be used in the target and parameters.

### Advanced command

Check **Advanced command** and enter a command understood by `cmd.exe`, such as:

```cmd
start "" "C:\Windows\System32\notepad.exe" && echo Started
```

HotKeyz runs it through `cmd.exe /d /c` in a hidden command window. Shell operators such as `&&`, `&`, pipes, and redirection are interpreted by the command processor. The normal file-parameters and singleton controls are disabled for this mode. **Run as admin** can request elevation; the command then has those elevated permissions. Review commands and imported profiles before running them, especially commands that modify or delete files.

## Open a folder

Enter a folder path or choose **Browse Folder**. Examples include `C:\Users\<USERNAME>\Documents` and a network folder such as `\\server\share\projects`. `<USERNAME>` is expanded when the hotkey runs; the resulting folder must exist on that computer. HotKeyz also recognizes Windows shell locations such as My Computer and Libraries.

## Run a system action

Choose an entry from the system-action list. Availability can depend on Windows and the machine's configuration.

| Choices                                                                                                | Effect                                                                                                                 |
|--------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| **Control Panel (Category View)**, **Control Panel (Icon View)**, **Windows Settings**                 | Open the corresponding Windows settings interface.                                                                     |
| **Fonts Folder**, **Network Places**, **Network Connections**, **Printers And Faxes**, **Recycle Bin** | Open the selected Windows location.                                                                                    |
| **Empty Recycle Bin**                                                                                  | Empties the Recycle Bin.                                                                                               |
| **Volume Up**, **Volume Down**, **Volume Mute**                                                        | Send the corresponding system media key.                                                                               |
| **Cycle Playback Device**, **Cycle Recording Device**                                                 | Advance through active playback or recording devices and wrap to the first device. Set the Windows console, multimedia, and communications defaults together. A brief notification shows the selected device. |
| **Media Play/Pause**, **Media Next**, **Media Previous**, **Media Stop**                               | Send the corresponding media key to Windows.                                                                           |
| **Lock**, **Log Off**, **Restart**, **Shutdown**                                                       | Perform the named session or power action. Save work before using log off, restart, or shutdown.                       |
| **Turn Off Monitors**, **Turn Off Monitors And Lock**                                                  | Request monitor power-off, optionally followed by a workstation lock. Keyboard or mouse input can wake the displays.   |
| **Start Screensaver**, **Start Screensaver And Lock**                                                  | Run the Windows 3D text screensaver. The lock variant waits for the screensaver to finish, then locks the workstation. |
| **Empty Clipboard**                                                                                    | Clears the clipboard.                                                                                                  |

### Open or close an optical drive tray

**Open/close optical drive tray** checks the physical tray state each time: open trays receive Close, and closed trays receive Open. It uses the same drive selector and conditions as the separate actions. If the drive cannot report its state, HotKeyz sends no command and suggests using Open or Close instead. This handles manual tray changes without relying on the last command. Some drives or drivers may not support the state query; laptop trays may need to be closed by hand.

Choose **Open optical drive tray** or **Close optical drive tray** under **Run a system action**, then select the drive letter beside the action. Click **Refresh** after connecting or disconnecting an optical drive. The editor displays **None** when no drives are detected; connect a drive before adding the action. A disc does not need to be inserted.

The separate Open and Close actions always send their named operation; Open/close chooses the opposite of the current tray state. Each action targets only the selected drive and never chooses a different drive if it disappears. Existing profiles can still be loaded and saved with a disconnected drive; running that shortcut reports that the drive is unavailable. The editor retains the saved letter so you can reconnect it or select its new letter. Conditions and left/right modifier selections work with these actions too.

Some drives may be locked by burning software, and many laptop trays must be closed by hand. A successful close request does not prove the tray physically closed. Only local optical drives are supported. These are limitations of AutoIt's [CDTray function](https://www.autoitscript.com/autoit3/docs/functions/CDTray.htm).

## Run actions on active window

Choose an action and focus its target window before pressing the hotkey. Window actions operate on the active, visible, titled window; some applications or Windows security boundaries may prevent operations. An ineligible target may be ignored.

| Action                                                                                    | Effect                                                                                                                |
|-------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------|
| **Close**                                                                                 | Requests that the window close; the application may ask about unsaved work.                                           |
| **Minimize**, **Hide**                                                                    | Minimize or hide the active window. A hidden window may need its own application controls or Task Manager to recover. |
| **Terminate**                                                                             | Forcefully terminates the active window; unsaved work can be lost.                                                    |
| **Transparency +**, **Transparency -**                                                    | Increase transparency or reduce it toward fully opaque, respectively, in steps.                                       |
| **Toggle On Top**                                                                         | Toggle whether the window stays above ordinary windows.                                                               |
| **Take Screenshot**                                                                       | Ask for a filename and save a screenshot of the active window as a JPEG.                                              |
| **Set Process Priority to Low / Below Normal / Normal / Above Normal / High / Realtime**  | Set the active window's process priority. Realtime priority can make a system unresponsive.                           |
| **Toggle Ghost (Advanced)**                                                               | Toggle the window's transparent-to-mouse style; use carefully, because the window may stop receiving mouse clicks.    |
| **Move Center**, **Move Top Left / Mid / Right**, **Move Bottom Left / Mid / Right**      | Reposition the window within its current monitor's work area, preserving its size.                                    |
| **Move to Next Monitor**, **Move to Previous Monitor**                                    | Transfer the window to another monitor, mapping its position and size to the destination work area.                   |
| **Snap Fullscreen**                                                                       | Fit the window to the current monitor's work area.                                                                    |
| **Snap Top / Bottom (1x2)**, **Snap Left / Right (2x1)**                                  | Fit to the selected half of the work area.                                                                            |
| **Snap Left / Mid / Right (3x1)**                                                         | Fit to the selected vertical third.                                                                                   |
| **Snap Top / Bottom Left / Right (2x2)**                                                  | Fit to the selected quarter.                                                                                          |
| **Snap Top / Bottom Left / Mid / Right (3x2)**                                            | Fit to the selected cell in a three-column, two-row grid.                                                             |
| **Resize 3x2**                                                                            | Resize in place to approximately one third of the monitor work-area width and one half of its height.                 |
| **Custom Move and/or Resize**                                                             | Use the coordinate and size controls described below.                                                                 |
| **Generate Random Password** and **Generate Random UUID**                                 | Generate a value and paste it into the active window. See [Text and tags](text-and-tags.md#generated-values).         |
| **Upper Case / Lower Case / Title Case / Reverse Selected Text**, hash and Base64 actions | Copy, transform, and replace selected text. See [Text and tags](text-and-tags.md#transform-selected-text).            |

### Custom Move and/or Resize

Select **Custom Move and/or Resize**. Check **Move active window** to enter integer **X** and **Y** virtual-desktop coordinates; negative coordinates can be used for monitors left of or above the primary display. Check **Resize active window** to enter positive integer **W** and **H** dimensions in pixels. Select at least one operation. If both are selected, HotKeyz moves and resizes the window.

## Open a URL

Choose `https://`, `http://`, or `ftp://`, and enter the rest of the address. Windows opens the URL using the registered handler, normally your default browser. For example, select `https://` and enter `example.com/docs`.

## Paste text into active window

Enter text, including multiple lines, in the text box. When triggered, HotKeyz expands supported tags, temporarily uses the clipboard, and sends a paste command to the active window. See [Text and tags](text-and-tags.md) for examples and clipboard limitations.
