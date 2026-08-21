; Sleep Hotkey Script v2
; Assign Win+Z to trigger sleep

#z::  ; Win+Z
{
    DllCall("powrprof.dll\SetSuspendState", "Int", 0, "Int", 1, "Int", 0)
}