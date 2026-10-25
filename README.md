# Touch Keep Cursor

A small AutoHotkey v2 script for Windows that stops a touch screen from stealing your mouse cursor.

On Windows, tapping a touch screen moves the mouse cursor to where you touched. If you use a touch monitor next to your main screen, every tap drags the cursor away from your work. This script puts it back.

## What it does
- Your tap or drag works normally on the touch screen.
- **As soon as you lift your finger** (after about 0.2 s), the cursor jumps back to where the mouse left it.
- **If you grab the mouse straight away**, the cursor returns immediately and moves from its old spot.
- Mouse-only use is unaffected.

## How it works
Windows marks mouse events that were generated from touch or pen input with the signature `0xFF515700` in the event's extra info. The script installs a low-level mouse hook. It remembers the cursor position while you use the mouse, recognises touch-generated events, and calls `SetCursorPos` to return the cursor after the touch ends. It is per-monitor DPI aware, so it works across screens with different scaling.

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
