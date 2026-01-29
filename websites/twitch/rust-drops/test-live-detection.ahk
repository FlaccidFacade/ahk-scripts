#Requires AutoHotkey v2.0

; Test script to check if a specific Twitch streamer is live
; Usage: Run this script and enter a Twitch username when prompted

#Include config.ahk

; Improved IsUserLive function
IsUserLive(twitchUrl) {
    try {
        ; Send a GET request to the Twitch URL
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", twitchUrl)
        http.Send()

        ; Check if the response contains live indicators
        response := http.ResponseText
        
        ; More specific checks for live status
        isLivePattern1 := InStr(response, '"isLiveBroadcast":true')
        isLivePattern2 := InStr(response, '"broadcastType":"live"')
        isLivePattern3 := InStr(response, 'data-a-target="player-overlay-play-button"')
        isLivePattern4 := InStr(response, '"stream":{"id"')
        
        ; Check for offline indicators
        isOfflinePattern1 := InStr(response, "offline_screen")
        isOfflinePattern2 := InStr(response, "channel-info-content")
        isOfflinePattern3 := InStr(response, '"stream":null')
        
        ; Log patterns found
        patterns := "Live patterns: " . isLivePattern1 . "," . isLivePattern2 . "," . isLivePattern3 . "," . isLivePattern4
        patterns .= " | Offline patterns: " . isOfflinePattern1 . "," . isOfflinePattern2 . "," . isOfflinePattern3
        FileAppend("PATTERNS: " . twitchUrl . " - " . patterns . "`n", A_ScriptDir "\\live_test.txt")
        
        ; If we find offline indicators, definitely not live
        if (isOfflinePattern1 || isOfflinePattern2 || isOfflinePattern3) {
            return false
        }
        
        ; If we find live indicators, likely live
        if (isLivePattern1 || isLivePattern2 || isLivePattern3 || isLivePattern4) {
            return true
        }
        
        ; Default to false if uncertain
        return false
        
    } catch Error as e {
        FileAppend("ERROR: Failed to query " . twitchUrl . " - " . e.Message . "`n", A_ScriptDir "\\live_test.txt")
        return false
    }
}

; Test a few common streamers
testStreamers := [
    "https://www.twitch.tv/shroud",
    "https://www.twitch.tv/summit1g", 
    "https://www.twitch.tv/pokimane",
    "https://www.twitch.tv/xqc"
]

FileAppend("=== Live Detection Test Started ===`n", A_ScriptDir "\\live_test.txt")

for streamerUrl in testStreamers {
    streamerName := RegExReplace(streamerUrl, ".*twitch\.tv/", "")
    isLive := IsUserLive(streamerUrl)
    result := isLive ? "LIVE" : "OFFLINE"
    
    FileAppend("RESULT: " . streamerName . " is " . result . "`n", A_ScriptDir "\\live_test.txt")
    TrayTip("Live Test", streamerName . " is " . result, 3)
    
    Sleep 2000  ; Wait between requests
}

FileAppend("=== Live Detection Test Completed ===`n", A_ScriptDir "\\live_test.txt")
TrayTip("Live Test", "Test completed - check live_test.txt", 5)