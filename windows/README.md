# Sleep Hotkey for Windows

A lightweight AutoHotkey v2 script that binds **Win + Z** to instantly put your PC to sleep.

## Requirements

- Windows 10/11
- [AutoHotkey v2](https://www.autohotkey.com/) installed

## Setup

1. Clone or download this repo
2. Double-click `SleepHotkey.ahk` to run it
3. Press **Win + Z** to sleep

## Autostart on Boot

### Quick Method (Startup Folder)
1. Press `Win + R`
2. Type `shell:startup` and hit Enter
3. Copy `SleepHotkey.ahk` (or a shortcut to it) into the folder

### Robust Method (Task Scheduler)
1. Open Task Scheduler
2. Create Basic Task → name it "Sleep Hotkey"
3. Trigger: **When I log on**
4. Action: **Start a program** → browse to `AutoHotkey64.exe`
5. Arguments: `path\to\SleepHotkey.ahk`
6. Optionally check "Run with highest privileges"

## Customization

To change the hotkey, edit the `#z::` line in `SleepHotkey.ahk`:

| Combo | Syntax |
|-------|--------|
| Win + Z | `#z::` |
| Ctrl + Alt + S | `^!s::` |
| Ctrl + Shift + S | `^+s::` |
| Alt + S | `!s::` |

See the [AHK v2 key list](https://www.autohotkey.com/docs/v2/KeyList.htm) for full reference.

## License

MIT — do whatever you want.