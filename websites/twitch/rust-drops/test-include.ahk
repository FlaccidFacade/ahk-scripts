#Requires AutoHotkey v2.0

; Simple test to verify includes work
#Include test-for-live-stream.ahk

; Test the function
MsgBox "Testing IsUserLive function..."
result := IsUserLive("https://www.twitch.tv/test")
MsgBox "IsUserLive returned: " . result