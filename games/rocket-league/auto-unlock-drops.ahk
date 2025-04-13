
; Activate Rocket League window
WinActivate, ahk_class LaunchUnrealUWindowsClient ahk_exe RocketLeague.exe ahk_pid 4848
Loop, 57 ; Change 10 to the number of times you want to repeat the commands
{
    MouseMove, 200, 1210, 50
    MouseClick, left

    MouseMove, 1098, 813, 50
    MouseClick, left
    
    MouseMove, 1306, 1339, 100
    Sleep, 3500
    MouseClick, left
}