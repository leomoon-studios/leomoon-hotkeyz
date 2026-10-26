# Text, tags, and generated values

[Documentation home](../README.md#user-documentation) · [Getting started](getting-started.md) · [Hotkey actions](actions.md) · [Profiles and troubleshooting](profiles-and-troubleshooting.md)

## Paste a text template

1. Open **Settings → Add New**.
2. Select **Paste text into active window** and enter your text. You can include line breaks.
3. Assign a shortcut, click **OK**, and then **Save**.
4. Place the cursor in an application that accepts pasted text and press the shortcut.

For example:

```text
Hello <USERNAME>,
Today is <YYYY-MM-DD>.
```

When the shortcut runs, HotKeyz replaces the tags with the current values. They are not permanently replaced in the saved template.

## Dynamic tags

The following tags are expanded when an action runs. They can be used in text, action targets, and parameters where the resulting value is valid.

| Tag              | Value                                                    |
|------------------|----------------------------------------------------------|
| `<HOUR>`         | Current hour.                                            |
| `<MINUTE>`       | Current minute.                                          |
| `<SECOND>`       | Current second.                                          |
| `<YEAR>`         | Current four-digit year.                                 |
| `<MONTHNAME>`    | Current month name.                                      |
| `<MONTHNUMBER>`  | Current month number.                                    |
| `<DAYNAME>`      | Current day-of-week name.                                |
| `<DAYNUMBER>`    | Current day of the month.                                |
| `<YYYYMMDD>`     | Date in compact year-month-day form, such as `20261026`. |
| `<YYYY-MM-DD>`   | Date with separators, such as `2026-10-26`.              |
| `<COMPUTERNAME>` | Current Windows computer name.                           |
| `<USERNAME>`     | Current Windows account name.                            |

For example, `D:\<USERNAME>\Projects` becomes `D:\home\Projects` when the current account is named `home`. The drive and expanded folder must exist; the tag changes the username, not the drive. To apply text in a file or folder path while editing, keep the tag in the path rather than replacing it with your current username.

File parameters additionally support `<GetActiveWindowsExplorerPath>`. It is resolved from the active File Explorer window when the action runs. See [Program parameters](actions.md#run-a-program-or-open-a-file).

## Generated values

These are found under **Run actions on active window**. Focus an editable field first, then press the assigned shortcut.

| Action                                             | Result                                                                        |
|----------------------------------------------------|-------------------------------------------------------------------------------|
| **Generate Random Password (PPP)**                 | A 20-character string using the app's PPP-style letters, digits, and symbols. |
| **Generate Random Password (Letters)**             | 20 random uppercase and lowercase letters.                                    |
| **Generate Random Password (Numbers)**             | 20 random digits.                                                             |
| **Generate Random Password (Letters and Numbers)** | 20 random letters and digits from `2` through `9`.                            |
| **Generate Random UUID**                           | A randomly generated version 4 UUID.                                          |

The password and UUID actions use Windows cryptographic randomness and paste the generated value into the active window. Choose the character set to match the destination's rules.

## Transform selected text

Under **Run actions on active window**, select one of these actions, highlight text in an editable application, and press the hotkey:

- **Upper Case Selected Text**, **Lower Case Selected Text**, **Title Case Selected Text**, or **Reverse Selected Text**.
- **MD5 Selected Text**, **SHA1 Selected Text**, **SHA-256 Selected Text**, or **SHA-512 Selected Text**: replace the selection with its hash in hexadecimal.
- **Base64 Encode Selected Text** or **Base64 Decode Selected Text**: encode or decode UTF-8 text. Decoding requires valid Base64-encoded UTF-8.

Hashing is one-way; it does not encrypt the text or preserve a recoverable copy. Verify the result before replacing anything important.

## Clipboard behavior

Paste, generation, and selection-transform actions temporarily use the Windows clipboard and try to restore its previous contents afterward. A transform copies the selection before replacing it. The target application must accept normal copy/paste commands, and another application changing the clipboard at the same time can interfere. Some clipboard formats cannot be safely preserved; in that case an operation can fail instead of proceeding. **Empty Clipboard** is a separate system action that intentionally clears it.
