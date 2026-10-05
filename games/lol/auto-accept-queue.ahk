#Requires AutoHotkey v2.0

; F8 to toggle the accepter on/off
; Ctrl+Alt+Q to turn OFF the accepter (works even when League has focus)
; F9 to reload the script

toggle := false

F8:: {
    global toggle
    toggle := !toggle
    TrayTip("Queue Accepter", toggle ? "ON - watching for queue" : "OFF")
    if toggle
        SetTimer(WatchQueue, 500)
    else
        SetTimer(WatchQueue, 0)
}

; Alternative OFF hotkey for when League captures F8
^!q:: {
    global toggle
    toggle := false
    TrayTip("Queue Accepter", "OFF")
    SetTimer(WatchQueue, 0)
}

WatchQueue() {
    ; Client window check
    if !WinExist("ahk_exe LeagueClient.exe") && !WinExist("ahk_exe LeagueClientUx.exe")
        return

    CoordMode("Pixel", "Screen")

    ; Green-ish accept button pixel (Riot green ~ #0AC98E area)
    ; Scan the middle band of the screen where the popup sits
    found := PixelSearch(&foundX, &foundY,
        A_ScreenWidth * 0.25, A_ScreenHeight * 0.35,
        A_ScreenWidth * 0.75, A_ScreenHeight * 0.65,
        0x0AC98E, 30)

    if found {
        Click(foundX, foundY)
        SoundBeep(800, 150)  ; beep so you know it fired
    }
}

F9::Reload()

#F8::ExitApp()