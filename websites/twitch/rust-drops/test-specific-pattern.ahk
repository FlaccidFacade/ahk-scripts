#Include config.ahk

; Test finding progress on streamer pages
DEBUG_MODE := true

; Include main functions we need
#Include auto-unlock-drops.ahk

; Test HTML pattern matching for the specific pattern you found
TestProgressPattern() {
    FileAppend("=== TESTING SPECIFIC PROGRESS PATTERN ===`n", A_ScriptDir "\\drops_status.txt")
    
    ; Test HTML with the pattern you found
    testHtml := '<p class="CoreText-sc-1txzju1-0 kvaOP">84% progress toward Rust Drops on /triciaisabirdy</p>'
    
    FileAppend("Testing HTML: " . testHtml . "`n", A_ScriptDir "\\drops_status.txt")
    
    ; Test Pattern 6 from our parsing function
    if (RegExMatch(testHtml, 'i)(\d{1,3})%\s+progress\s+toward\s+[^/]*/([a-zA-Z0-9_]+)', &match)) {
        progressPercent := Integer(match[1])
        streamerName := match[2]
        FileAppend("SUCCESS: Found progress " . progressPercent . "% for streamer " . streamerName . "`n", A_ScriptDir "\\drops_status.txt")
    } else {
        FileAppend("FAILED: Pattern 6 did not match`n", A_ScriptDir "\\drops_status.txt")
    }
    
    ; Test the CoreText pattern specifically
    if (RegExMatch(testHtml, 'i)class="[^"]*CoreText[^"]*"[^>]*>(\d{1,3})%\s+progress', &match)) {
        progressPercent := Integer(match[1])
        FileAppend("SUCCESS: CoreText pattern found progress " . progressPercent . "%`n", A_ScriptDir "\\drops_status.txt")
    } else {
        FileAppend("FAILED: CoreText pattern did not match`n", A_ScriptDir "\\drops_status.txt")
    }
    
    ; Test a more flexible pattern
    if (RegExMatch(testHtml, 'i)(\d{1,3})%.*?progress.*?toward.*?/([a-zA-Z0-9_]+)', &match)) {
        progressPercent := Integer(match[1])
        streamerName := match[2]
        FileAppend("SUCCESS: Flexible pattern found progress " . progressPercent . "% for streamer " . streamerName . "`n", A_ScriptDir "\\drops_status.txt")
    } else {
        FileAppend("FAILED: Flexible pattern did not match`n", A_ScriptDir "\\drops_status.txt")
    }
    
    ; Now test by parsing this HTML through our ParseInventoryData function
    FileAppend("`n=== TESTING THROUGH ParseInventoryData ===`n", A_ScriptDir "\\drops_status.txt")
    
    ; Clear and test with our function
    global CompletedDrops
    CompletedDrops.Clear()
    ParseInventoryData(testHtml)
    
    FileAppend("Found " . CompletedDrops.Count . " entries after parsing`n", A_ScriptDir "\\drops_status.txt")
    
    if (CompletedDrops.Count > 0) {
        for streamerOrDrop, progress in CompletedDrops {
            if (progress == true) {
                FileAppend("- " . streamerOrDrop . " = COMPLETED (100%)`n", A_ScriptDir "\\drops_status.txt")
            } else {
                percentage := Round(progress * 100, 1)
                FileAppend("- " . streamerOrDrop . " = " . percentage . "% complete`n", A_ScriptDir "\\drops_status.txt")
            }
        }
    }
    
    ; Test the GetDropProgress function
    progress := GetDropProgress("triciaisabirdy", "triciaisabirdy")
    if (progress != false) {
        percentage := Round(progress * 100, 1)
        FileAppend("GetDropProgress found: triciaisabirdy = " . percentage . "%`n", A_ScriptDir "\\drops_status.txt")
    } else {
        FileAppend("GetDropProgress did not find triciaisabirdy`n", A_ScriptDir "\\drops_status.txt")
    }
    
    FileAppend("`n=== TEST COMPLETE ===`n", A_ScriptDir "\\drops_status.txt")
    
    TrayTip("Pattern Test", "Test complete - check drops_status.txt", 5)
}

; Run the test
TestProgressPattern()