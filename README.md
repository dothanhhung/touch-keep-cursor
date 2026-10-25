# Touch Keep Cursor

A small AutoHotkey v2 script for Windows that stops a touch screen from stealing your mouse cursor.

On Windows, tapping a touch screen moves the mouse cursor to where you touched. If you use a touch monitor next to your main screen, every tap drags the cursor away from your work. This script puts it back.

## What it does
- Your tap or drag works normally on the touch screen.
- **As soon as you lift your finger** (after about 0.2 s), the cursor jumps back to where the mouse left it.
- **If you grab the mouse straight away**, the cursor returns immediately and moves from its old spot.
- Mouse-only use is unaffected.

## How it works
Two detectors run together:
- A low-level mouse hook catches mouse events Windows synthesizes from touch (extra-info signature `0xFF515700`).
- A raw input listener registers for the touch digitizer (HID usage page `0x0D`, usage `0x04`), catching touches some apps take as pointer input without ever generating a mouse event.

The script only updates its saved position while it sees real (non-injected) mouse movement. After a touch, once there's no touch input for 200 ms and no button is held, it calls `SetCursorPos` to return the cursor. It is per-monitor DPI aware, so it works across screens with different scaling.

## Install
1. Install [AutoHotkey v2](https://www.autohotkey.com/) (or `winget install AutoHotkey.AutoHotkey`).
2. Download `touch-keep-cursor.ahk` and double-click it. An "H" icon appears in the system tray (it may be under the **^** arrow).
3. **Start with Windows:** press Win + R, type `shell:startup`, and put a shortcut to the script in that folder.

To stop it: right-click the tray icon → **Exit**.

## Limits
- It can't see touches on windows running as administrator unless you run the script as administrator too.
- Apps that handle raw pointer input without generating mouse events may not trigger it.

## License
MIT
