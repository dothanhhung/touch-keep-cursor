#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; Touch on any screen no longer steals the mouse cursor: once the finger lifts
; (or the real mouse moves), the cursor jumps back to where the mouse left it.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")   ; physical pixels on every monitor

global touched := false, lastTouch := 0, savedX := 0, savedY := 0

hookProc := CallbackCreate(LowLevelMouseProc, "Fast", 3)
hHook := DllCall("SetWindowsHookEx", "int", 14, "ptr", hookProc
    , "ptr", DllCall("GetModuleHandle", "ptr", 0, "ptr"), "uint", 0, "ptr")
OnExit((*) => DllCall("UnhookWindowsHookEx", "ptr", hHook))
SetTimer(Tick, 25)

LowLevelMouseProc(nCode, wParam, lParam) {
    global touched, lastTouch
    if (nCode >= 0) {
        extra := NumGet(lParam, A_PtrSize = 8 ? 24 : 20, "uptr")
        if ((extra & 0xFFFFFF00) = 0xFF515700) {          ; mouse event synthesized from touch/pen
            touched := true
            lastTouch := A_TickCount
        } else if (touched && !(NumGet(lParam, 12, "uint") & 1)) {   ; real mouse input right after a touch
            Restore()
            if (wParam = 0x200)                           ; swallow this move so it starts from the saved spot
                return 1
        }
    }
    return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam, "ptr")
}

Tick() {
    global touched, lastTouch, savedX, savedY
    static pt := Buffer(8)
    if !touched {
        DllCall("GetCursorPos", "ptr", pt)
        savedX := NumGet(pt, 0, "int"), savedY := NumGet(pt, 4, "int")
    } else if (A_TickCount - lastTouch > 200 && !GetKeyState("LButton") && !GetKeyState("RButton")) {
        Restore()
    }
}

Restore() {
    global touched, savedX, savedY
    DllCall("SetCursorPos", "int", savedX, "int", savedY)
    touched := false
}
