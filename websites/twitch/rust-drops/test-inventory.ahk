#Requires AutoHotkey v2.0

; Test script for Twitch drops inventory checking
; This will test the inventory parsing without running the full automation

#Include config.ahk

; Global variable for completed drops
CompletedDrops := Map()

; Helper function to repeat a string
RepeatString(str, count) {
    result := ""
    Loop count {
        result .= str
    }
    return result
}

; Check Twitch drops inventory to see what drops are already completed
CheckDropsInventory() {
    global CompletedDrops := Map()
    
    try {
        ; Send a GET request to the Twitch drops inventory
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", "https://www.twitch.tv/drops/inventory")
        http.Send()
        
        response := http.ResponseText
        
        FileAppend("Fetched drops inventory data (length: " . StrLen(response) . " chars)`n", A_ScriptDir "\\inventory_test.txt")
        
        ; Parse the inventory for completed drops
        ParseInventoryData(response)
        
        return true
        
    } catch Error as e {
        FileAppend("Failed to fetch drops inventory: " . e.Message . "`n", A_ScriptDir "\\inventory_test.txt")
        return false
    }
}

; Parse inventory response to find completed drops
ParseInventoryData(html) {
    global CompletedDrops
    
    ; Clear existing completed drops data
    CompletedDrops := Map()
    
    completedCount := 0
    
    ; Pattern 1: Look for JSON-like progress indicators
    pos := 1
    while (pos := RegExMatch(html, 'i)"name"\s*:\s*"([^"]+)"[^}]*"progress"\s*:\s*(100|1\.0)', &match, pos)) {
        dropName := match[1]
        CompletedDrops[dropName] := true
        completedCount++
        FileAppend("Found completed drop (progress): " . dropName . "`n", A_ScriptDir "\\inventory_test.txt")
        pos := match.Pos + match.Len
    }
    
    ; Pattern 2: Look for claimed items
    pos := 1
    while (pos := RegExMatch(html, 'i)"name"\s*:\s*"([^"]+)"[^}]*"claimed"\s*:\s*true', &match, pos)) {
        dropName := match[1]
        CompletedDrops[dropName] := true
        completedCount++
        FileAppend("Found completed drop (claimed): " . dropName . "`n", A_ScriptDir "\\inventory_test.txt")
        pos := match.Pos + match.Len
    }
    
    ; Also look for Rust-specific items by name
    rustItems := ["VAGABOND JACKET", "LARGE BACKPACK", "SLEEPING BAG", "FRIDGE", "HOODIE", "PANTS", "BOOTS"]
    
    for item in rustItems {
        ; Check if this item appears with completion indicators
        if (InStr(html, item) && RegExMatch(html, 'i)' . item . '.*?(100%|Complete|Claimed)')) {
            CompletedDrops[item] := true
            completedCount++
            FileAppend("Found completed Rust item: " . item . "`n", A_ScriptDir "\\inventory_test.txt")
        }
    }
    
    FileAppend("Inventory check complete. Found " . completedCount . " completed drops.`n", A_ScriptDir "\\inventory_test.txt")
}

; Check if a specific drop/item is already completed
IsDropCompleted(dropName, itemName) {
    global CompletedDrops
    
    ; Check by exact drop name
    if (CompletedDrops.Has(dropName)) {
        return true
    }
    
    ; Check by item name
    if (CompletedDrops.Has(itemName)) {
        return true
    }
    
    ; Check for partial matches (case-insensitive)
    for completedDrop in CompletedDrops {
        if (InStr(completedDrop, dropName) || InStr(completedDrop, itemName)) {
            return true
        }
        if (InStr(dropName, completedDrop) || InStr(itemName, completedDrop)) {
            return true
        }
    }
    
    return false
}

; Run the test
FileAppend("=== Twitch Drops Inventory Test Started ===`n", A_ScriptDir "\\inventory_test.txt")

if (CheckDropsInventory()) {
    FileAppend("`n=== COMPLETED DROPS FOUND ===`n", A_ScriptDir "\\inventory_test.txt")
    
    if (CompletedDrops.Count == 0) {
        FileAppend("No completed drops found.`n", A_ScriptDir "\\inventory_test.txt")
    } else {
        count := 1
        for dropName in CompletedDrops {
            FileAppend(count . ". " . dropName . "`n", A_ScriptDir "\\inventory_test.txt")
            count++
        }
    }
    
    ; Test a few sample checks
    FileAppend("`n=== TESTING DROP COMPLETION CHECKS ===`n", A_ScriptDir "\\inventory_test.txt")
    testItems := ["VAGABOND JACKET", "LARGE BACKPACK", "SLEEPING BAG", "shroud", "summit1g"]
    
    for item in testItems {
        isCompleted := IsDropCompleted(item, item) ? "YES" : "NO"
        FileAppend("Is '" . item . "' completed? " . isCompleted . "`n", A_ScriptDir "\\inventory_test.txt")
    }
} else {
    FileAppend("Failed to check inventory.`n", A_ScriptDir "\\inventory_test.txt")
}

FileAppend("`n=== Test Complete ===`n", A_ScriptDir "\\inventory_test.txt")
TrayTip("Inventory Test", "Test complete - check inventory_test.txt", 5)