#Include config.ahk

; Test inventory fetching directly
DEBUG_MODE := true

; Include main functions we need
#Include auto-unlock-drops.ahk

; Test inventory fetching to see what we actually get
TestInventoryFetch() {
    FileAppend("=== TESTING INVENTORY FETCH ===`n", A_ScriptDir "\\drops_status.txt")
    
    ; Try to fetch inventory
    result := CheckDropsInventory()
    
    if (result) {
        FileAppend("Inventory fetch returned: SUCCESS`n", A_ScriptDir "\\drops_status.txt")
    } else {
        FileAppend("Inventory fetch returned: FAILED`n", A_ScriptDir "\\drops_status.txt")
    }
    
    ; Check what we actually got in CompletedDrops
    FileAppend("CompletedDrops entries: " . CompletedDrops.Count . "`n", A_ScriptDir "\\drops_status.txt")
    
    if (CompletedDrops.Count > 0) {
        FileAppend("Found entries:`n", A_ScriptDir "\\drops_status.txt")
        for dropName, progress in CompletedDrops {
            progressText := (progress == true) ? "100%" : (Round(progress * 100, 1) . "%")
            FileAppend("  - " . dropName . ": " . progressText . "`n", A_ScriptDir "\\drops_status.txt")
        }
    } else {
        FileAppend("No entries found - this indicates either:`n", A_ScriptDir "\\drops_status.txt")
        FileAppend("  1. Authentication required (not logged in)`n", A_ScriptDir "\\drops_status.txt")
        FileAppend("  2. HTML structure different than expected`n", A_ScriptDir "\\drops_status.txt")
        FileAppend("  3. No drops in progress on your account`n", A_ScriptDir "\\drops_status.txt")
    }
    
    ; Test manual URL pattern detection for known streamers
    FileAppend("`n=== TESTING KNOWN STREAMER PAGE FETCH ===`n", A_ScriptDir "\\drops_status.txt")
    
    ; Test fetching triciaisabirdy page directly (since you have 84% there)
    progress := CheckStreamerPageProgress("https://www.twitch.tv/triciaisabirdy", "triciaisabirdy")
    if (progress != false) {
        percentage := progress == true ? "100%" : Round(progress * 100, 1) . "%"
        FileAppend("Found progress on triciaisabirdy page: " . percentage . "`n", A_ScriptDir "\\drops_status.txt")
    } else {
        FileAppend("No progress found on triciaisabirdy page`n", A_ScriptDir "\\drops_status.txt")
    }
    
    FileAppend("`n=== TEST COMPLETE ===`n", A_ScriptDir "\\drops_status.txt")
    
    TrayTip("Inventory Test", "Test complete - check drops_status.txt", 5)
}

; Run the test
TestInventoryFetch()