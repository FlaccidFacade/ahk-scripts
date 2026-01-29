#Requires AutoHotkey v2.0

; Test script to validate HTML parsing from Facepunch registry
DEBUG_MODE := true
REGISTRY_URL := "https://twitch.facepunch.com/"

; Test arrays
StreamerDrops := []

; Test the HTML parsing functionality
TestHTMLParsing() {
    MsgBox "=== Testing HTML Parsing from Facepunch Registry ==="
    
    try {
        ; Fetch actual data from the website
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", REGISTRY_URL)
        http.Send()
        
        response := http.ResponseText
        MsgBox "Fetched HTML content successfully. Length: " . StrLen(response) . " characters"
        
        ; Test parsing functions
        TestParseStreamerData(response)
        
    } catch Error as e {
        MsgBox "Error fetching data: " . e.Message
    }
}

; Test parsing function (simplified version for testing)
TestParseStreamerData(html) {
    StreamerDrops := []
    
    MsgBox "Testing streamer URL extraction..."
    
    ; Test streamer link extraction
    pos := 1
    streamerCount := 0
    while (pos := RegExMatch(html, "i)https://www\.twitch\.tv/([a-zA-Z0-9_]+)", &match, pos)) {
        streamerName := match[1]
        streamerUrl := match[0]
        
        ; Skip directory/category links
        if (InStr(streamerName, "directory") || InStr(streamerName, "category")) {
            pos := match.Pos + match.Len
            continue
        }
        
        streamerCount++
        MsgBox "Found streamer #" . streamerCount . ": " . streamerName . "`nURL: " . streamerUrl
        
        ; Look for time requirements nearby
        searchStart := match.Pos
        searchEnd := Min(searchStart + 300, StrLen(html))
        nearbyText := SubStr(html, searchStart, searchEnd - searchStart)
        
        minutes := 60 ; default
        if (RegExMatch(nearbyText, "i)(\d+)\s+HOUR", &timeMatch)) {
            minutes := Integer(timeMatch[1]) * 60
            MsgBox "  → Time requirement: " . timeMatch[1] . " hours (" . minutes . " minutes)"
        } else {
            MsgBox "  → Using default: 60 minutes"
        }
        
        ; Check for item names
        itemName := "Unknown Item"
        if (InStr(nearbyText, "VAGABOND JACKET")) {
            itemName := "Vagabond Jacket"
        } else if (InStr(nearbyText, "LARGE BACKPACK")) {
            itemName := "Large Backpack"
        } else if (InStr(nearbyText, "SLEEPING BAG")) {
            itemName := "Sleeping Bag"
        } else if (InStr(nearbyText, "FRIDGE")) {
            itemName := "Fridge"
        }
        
        MsgBox "  → Item: " . itemName
        
        StreamerDrops.Push({
            username: streamerName,
            url: streamerUrl,
            minutes: minutes,
            dropType: "streamer",
            itemName: itemName
        })
        
        pos := match.Pos + match.Len
        
        ; Limit to first 10 for testing
        if (streamerCount >= 10) {
            break
        }
    }
    
    MsgBox "Testing general drops extraction..."
    
    ; Test general drops extraction
    pos := 1
    generalCount := 0
    while (pos := RegExMatch(html, "i)(\d+)\s+HOUR", &match, pos)) {
        hours := Integer(match[1])
        minutes := hours * 60
        
        generalCount++
        MsgBox "Found general drop #" . generalCount . ": " . hours . " hours (" . minutes . " minutes)"
        
        StreamerDrops.Push({
            username: "RustCategory" . hours . "h",
            url: "https://www.twitch.tv/directory/category/rust",
            minutes: minutes,
            dropType: "general",
            itemName: "General Drop (" . hours . "h)"
        })
        
        pos := match.Pos + match.Len
        
        ; Limit to first 10 for testing
        if (generalCount >= 10) {
            break
        }
    }
    
    MsgBox "Parsing test complete!`n" .
          "Found " . streamerCount . " streamers and " . generalCount . " general drops.`n" .
          "Total: " . StreamerDrops.Length . " drop opportunities."
}

; Run the test
TestHTMLParsing()