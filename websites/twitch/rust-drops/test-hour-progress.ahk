#Include config.ahk

; Test the new "% of 1 hour" parsing
DEBUG_MODE := true

; Include main functions we need
#Include auto-unlock-drops.ahk

; Test the specific "% of 1 hour" pattern parsing
TestHourProgressParsing() {
    FileAppend("=== TESTING '% OF 1 HOUR' PATTERN PARSING ===`n", A_ScriptDir "\\drops_status.txt")
    
    ; Test HTML patterns found in the inventory file
    testCases := [
        '<span class="CoreText-sc-1txzju1-0 cWFBTs">83</span>% of 1 hour',
        '<span class="CoreText-sc-1txzju1-0 cWFBTs">41</span>% of 1 hour', 
        '<span class="CoreText-sc-1txzju1-0 cWFBTs">92</span>% of 1 hour',
        '<p class="CoreText-sc-1txzju1-0 flIPIR"><span class="CoreText-sc-1txzju1-0 cWFBTs">75</span>% of 1 hour</p>',
        'Some text before 67% of 1 hour some text after'
    ]
    
    ; Test each pattern
    for i, testHtml in testCases {
        FileAppend("Test case " . i . ": " . testHtml . "`n", A_ScriptDir "\\drops_status.txt")
        
        ; Clear previous results
        global CompletedDrops
        CompletedDrops.Clear()
        
        ; Parse this test HTML
        ParseInventoryData(testHtml)
        
        ; Show results
        if (CompletedDrops.Count > 0) {
            for dropName, progress in CompletedDrops {
                progressText := (progress == true) ? "100%" : (Round(progress * 100, 1) . "%")
                FileAppend("  -> Found: " . dropName . " = " . progressText . "`n", A_ScriptDir "\\drops_status.txt")
            }
        } else {
            FileAppend("  -> No matches found`n", A_ScriptDir "\\drops_status.txt")
        }
        FileAppend("`n", A_ScriptDir "\\drops_status.txt")
    }
    
    ; Test with the actual HTML file content if available
    FileAppend("=== TESTING WITH ACTUAL INVENTORY FILE ===`n", A_ScriptDir "\\drops_status.txt")
    
    try {
        inventoryContent := FileRead(A_ScriptDir "\\sample-twitch.tv\\drops\\inventory-values.html")
        
        CompletedDrops.Clear()
        ParseInventoryData(inventoryContent)
        
        FileAppend("Found " . CompletedDrops.Count . " entries from actual inventory file:`n", A_ScriptDir "\\drops_status.txt")
        
        if (CompletedDrops.Count > 0) {
            for dropName, progress in CompletedDrops {
                progressText := (progress == true) ? "100%" : (Round(progress * 100, 1) . "%")
                FileAppend("  - " . dropName . ": " . progressText . "`n", A_ScriptDir "\\drops_status.txt")
            }
        }
        
    } catch as err {
        FileAppend("Could not read inventory file: " . err.message . "`n", A_ScriptDir "\\drops_status.txt")
    }
    
    FileAppend("`n=== TEST COMPLETE ===`n", A_ScriptDir "\\drops_status.txt")
    
    TrayTip("Hour Progress Test", "Test complete - check drops_status.txt", 5)
}

; Run the test
TestHourProgressParsing()