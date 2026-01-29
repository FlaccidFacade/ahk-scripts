#Include config.ahk

; Test the enhanced progress detection with streamer focus
DEBUG_MODE := true

; Include main functions we need
#Include auto-unlock-drops.ahk

; Test inventory parsing and progress detection with specific streamers
TestStreamerProgressDetection() {
    FileAppend("=== TESTING STREAMER PROGRESS DETECTION ===`n", A_ScriptDir "\\drops_status.txt")
    
    ; Check inventory
    FileAppend("Checking Twitch drops inventory for streamer progress...`n", A_ScriptDir "\\drops_status.txt")
    CheckDropsInventory()
    
    ; Print what we found
    FileAppend("Streamer progress entries found: " . CompletedDrops.Count . "`n", A_ScriptDir "\\drops_status.txt")
    
    if (CompletedDrops.Count > 0) {
        FileAppend("Streamer progress details:`n", A_ScriptDir "\\drops_status.txt")
        for streamerOrDrop, progress in CompletedDrops {
            if (progress == true) {
                FileAppend("- " . streamerOrDrop . " = COMPLETED (100%)`n", A_ScriptDir "\\drops_status.txt")
            } else {
                percentage := Round(progress * 100, 1)
                FileAppend("- " . streamerOrDrop . " = " . percentage . "% complete`n", A_ScriptDir "\\drops_status.txt")
            }
        }
    } else {
        FileAppend("No streamer progress found. Checking if HTML parsing needs adjustment.`n", A_ScriptDir "\\drops_status.txt")
    }
    
    ; Test lookups for our known streamers from StreamerDrops
    FileAppend("`n=== TESTING SPECIFIC STREAMER LOOKUPS ===`n", A_ScriptDir "\\drops_status.txt")
    
    if (StreamerDrops.Length > 0) {
        for streamer in StreamerDrops {
            progress := GetDropProgress(streamer.username, streamer.itemName)
            if (progress != false) {
                percentage := Round(progress * 100, 1)
                FileAppend("Found progress for streamer '" . streamer.username . "': " . percentage . "% (item: " . streamer.itemName . ")`n", A_ScriptDir "\\drops_status.txt")
                
                ; Also check if it shows as completed
                isCompleted := IsDropCompleted(streamer.username, streamer.itemName)
                FileAppend("  -> Is completed: " . (isCompleted ? "YES" : "NO") . "`n", A_ScriptDir "\\drops_status.txt")
            } else {
                FileAppend("No progress found for streamer '" . streamer.username . "' (item: " . streamer.itemName . ")`n", A_ScriptDir "\\drops_status.txt")
            }
        }
    } else {
        FileAppend("No streamers configured in StreamerDrops array.`n", A_ScriptDir "\\drops_status.txt")
    }
    
    ; Test common streamer names that might be in inventory
    testStreamers := ["trausi", "hjune", "spoonkid", "blooprint", "aloneintokyo", "coconutb", "posty", "ramsey", "willjum", "rust"]
    
    FileAppend("`n=== TESTING COMMON STREAMERS ===`n", A_ScriptDir "\\drops_status.txt")
    for streamerName in testStreamers {
        progress := GetDropProgress(streamerName, streamerName)
        if (progress != false) {
            percentage := Round(progress * 100, 1)
            FileAppend("Found progress for '" . streamerName . "': " . percentage . "%`n", A_ScriptDir "\\drops_status.txt")
        } else {
            FileAppend("No progress found for '" . streamerName . "'`n", A_ScriptDir "\\drops_status.txt")
        }
    }
    
    FileAppend("`n=== TEST COMPLETE ===`n", A_ScriptDir "\\drops_status.txt")
    
    TrayTip("Streamer Progress Test", "Test complete - check drops_status.txt", 5)
}

; Run the test
TestStreamerProgressDetection()