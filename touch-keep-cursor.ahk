#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; Touch on any screen no longer steals the mouse cursor: once the finger lifts
; (or the real mouse moves), the cursor jumps back to where the mouse left it.
; Run with /log to write touch-keep-cursor.log next to the script.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")   ; physical pixels on every monitor

global touched := false, lastTouch := 0, realSeen := false, savedX := 0, savedY := 0
global LOGGING := A_Args.Length && A_Args[1] = "/log"
global logFile := A_ScriptDir "\touch-keep-cursor.log"
if LOGGING
    try FileDelete(logFile)

pt := Buffer(8)
DllCall("GetCursorPos", "ptr", pt)
savedX := NumGet(pt, 0, "int"), savedY := NumGet(pt, 4, "int")

; 1) Mouse events Windows synthesizes from touch carry the 0xFF515700 signature.
hookProc := CallbackCreate(LowLevelMouseProc, "Fast", 3)
hHook := DllCall("SetWindowsHookEx", "int", 14, "ptr", hookProc
    , "ptr", DllCall("GetModuleHandle", "ptr", 0, "ptr"), "uint", 0, "ptr")
OnExit((*) => DllCall("UnhookWindowsHookEx", "ptr", hHook))

; 2) Touch screens themselves (HID digitizer, usage page 0x0D / usage 0x04), so
;    touches that apps take as pointer input, with no mouse events, are seen too.
sink := Gui()
rid := Buffer(8 + A_PtrSize, 0)
NumPut("ushort", 0x0D, "ushort", 0x04, "uint", 0x100, "ptr", sink.Hwnd, rid)   ; RIDEV_INPUTSINK
rawOk := DllCall("RegisterRawInputDevices", "ptr", rid, "uint", 1, "uint", 8 + A_PtrSize)
OnMessage(0xFF, (*) => TouchSeen("digitizer"))   ; WM_INPUT
WriteLog("start hook=" hHook " rawInput=" rawOk " saved=" savedX "," savedY)

SetTimer(Tick, 25)

LowLevelMouseProc(nCode, wParam, lParam) {
    global touched, realSeen
    if (nCode >= 0) {
        extra := NumGet(lParam, A_PtrSize = 8 ? 24 : 20, "uptr")
        if ((extra & 0xFFFFFF00) = 0xFF515700) {          ; mouse event synthesized from touch/pen
            TouchSeen("mouse-from-touch")
        } else if !(NumGet(lParam, 12, "uint") & 1) {     ; real (non-injected) mouse or touchpad
            if touched {
                Restore("mouse moved")
                if (wParam = 0x200)                       ; swallow this move so it starts from the saved spot
                    return 1
            }
            realSeen := true
        }
    }
    return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam, "ptr")
}

TouchSeen(src) {
    global touched, lastTouch, savedX, savedY
    if !touched
        WriteLog("touch (" src ") saved=" savedX "," savedY)
    touched := true
    lastTouch := A_TickCount
}

Tick() {
    global touched, lastTouch, realSeen, savedX, savedY
    static pt := Buffer(8)
    if touched {
        if (A_TickCount - lastTouch > 200 && !GetKeyState("LButton") && !GetKeyState("RButton"))
            Restore("finger lifted")
    } else if realSeen {                                  ; only real mouse movement updates the saved spot
        realSeen := false
        DllCall("GetCursorPos", "ptr", pt)
        savedX := NumGet(pt, 0, "int"), savedY := NumGet(pt, 4, "int")
    }
}

Restore(why) {
    global touched, savedX, savedY
    static pt := Buffer(8)
    if LOGGING {
        DllCall("GetCursorPos", "ptr", pt)
        WriteLog("restore (" why ") from " NumGet(pt, 0, "int") "," NumGet(pt, 4, "int") " to " savedX "," savedY)
    }
    DllCall("SetCursorPos", "int", savedX, "int", savedY)
    touched := false
}

WriteLog(s) {
    global LOGGING, logFile
    if LOGGING
        FileAppend(FormatTime(, "HH:mm:ss") " " s "`n", logFile)
}
