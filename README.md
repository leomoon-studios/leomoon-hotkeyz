# LeoMoon HotKeyz

LeoMoon HotKeyz is a Windows tray application for assigning global keyboard shortcuts to programs, folders, URLs, text, media controls, system operations, and active-window actions.

## Supported systems

Windows 10 and Windows 11 are the target desktop platforms. Continuous integration performs noninteractive syntax and regression checks on the GitHub-hosted Windows Server 2022 image with AutoIt 3.3.18.0. The application is compiled as a 32-bit executable and can run on 64-bit Windows through WOW64.

Linux can be used for repository maintenance, editing, Git operations, and triggering GitHub Actions. The application and AutoIt test executables require Windows, so Linux maintainers should use the CI workflow for authoritative validation.

## Validation from Linux

Every push and pull request runs [`.github/workflows/ci.yml`](.github/workflows/ci.yml). The workflow can also be started manually from the GitHub Actions page by selecting **CI**, choosing **Run workflow**, and selecting the branch to test.

With the GitHub CLI installed and authenticated, a Linux maintainer can run:

```bash
gh workflow run ci.yml --ref your-branch
gh run list --workflow ci.yml --limit 1
gh run watch
```

CI downloads the checksum-pinned AutoIt 3.3.18.0 archive, runs strict `Au3Check` validation, executes [`tests/TestRunner.au3`](tests/TestRunner.au3) with `/ErrorStdOut`, and runs the noninteractive module composition smoke test. Tests use temporary files and injected Windows-operation backends, so they do not modify the runner's startup registry entry, global hotkeys, clipboard, windows, or persistent application settings.

On Windows, the same checks can be run directly when an extracted AutoIt toolchain is available:

```powershell
& scripts/check.ps1 -ToolchainDirectory C:\path\to\autoit-v3.3.18.0\install
```

## Test builds from Linux

The manual [Windows package workflow](.github/workflows/build-release.yml) accepts an `X.Y.Z` version, runs the full regression suite, builds the x86 application, creates a portable ZIP and an unsigned per-user Inno Setup installer, performs a silent install and uninstall test, and uploads one artifact containing the packages, release manifest, and checksums. Manual runs create workflow artifacts only and do not publish a GitHub Release.

From an authenticated GitHub CLI session on Linux, start and follow a test build with:

```bash
gh workflow run build-release.yml --ref your-branch -f version=1.8.12
gh run list --workflow build-release.yml --limit 1
gh run watch
```

After the run succeeds, download its artifact with `gh run download RUN_ID`. The extracted artifact must contain only the portable ZIP, setup executable, `release-manifest.json`, and `SHA256SUMS`.

## Configuration and recovery

The application stores `LeoMoon HotKeyz.ini` beside the executable. The `[Options]` section contains the main enable or disable shortcut, and the `[Hotkeys]` section contains action shortcuts.

Configuration saves use a temporary `LeoMoon HotKeyz.ini.tmp` file. A successful replacement keeps the previous configuration as `LeoMoon HotKeyz.ini.bak` in the same directory. If a save is interrupted or rejected, retain the live file and use the `.bak` file for recovery if needed.

The optional **Start with Windows** setting writes only the current user's `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run` registry key. It does not require administrator rights.

## Hotkey syntax

The settings interface is the recommended way to create shortcuts. In the INI representation, modifier characters follow AutoIt syntax:

| Modifier | INI character |
| --- | --- |
| Ctrl | `^` |
| Alt | `!` |
| Shift | `+` |
| Windows key | `#` |

Named keys use braces, such as `^!{LEFT}` for Ctrl+Alt+Left or `^!{NUMPAD1}` for Ctrl+Alt+Numpad 1. A hotkey must include at least one modifier, and it cannot duplicate the main toggle or another action hotkey. The repository keeps compatibility with version 1.8.12 markers while validating all decoded actions before registration.

## Advanced commands

The **Advanced command** action runs its value through `cmd.exe /d /c` in a hidden command prompt. It supports shell operators and therefore has the same permissions and destructive potential as a command entered manually. Review imported configuration before enabling its hotkeys, avoid commands from untrusted sources, and enable **Run as admin** only when the command genuinely requires elevation.

## Source layout

| Path | Responsibility |
| --- | --- |
| `src/LeoMoon HotKeyz.au3` | Dependency composition, process startup, event loop, and shutdown |
| `src/core/` | Application constants, action catalogs, typed hotkey records, codecs, validation-independent geometry, and INI persistence |
| `src/actions/` | Explicit action dispatch plus window, text, process, system, and clipboard operations |
| `src/app/` | Application composition, tray behavior, global hotkey registration, startup registry access, and user-facing error reporting |
| `src/gui/` | Main settings window, editor controls, editor model validation, and GUI state |
| `tests/` | Noninteractive AutoIt assertion runner, fixtures, test doubles, and module smoke test |
| `scripts/check.ps1` | Strict AutoIt syntax checks and regression-test entry point used by CI |

## Third-party code

`src/resources/ExtMsgBox.au3` and `src/resources/StringSize.au3` are vendored AutoIt UDFs by Melba23, with additional contributors credited in their retained headers. Source links, attribution details, and the upstream licensing statement are recorded in [`src/resources/README.md`](src/resources/README.md). AutoIt standard-library UDFs are supplied by the pinned AutoIt toolchain and are not vendored in this repository.
