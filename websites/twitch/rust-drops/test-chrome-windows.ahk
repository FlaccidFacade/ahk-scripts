#Requires AutoHotkey v2.0

; Test script to show which windows have the Chrome_WidgetWin_1 class
; This will help you understand what was being closed before the fix

FileAppend("=== Chrome Window Class Detection Test ===`n", A_ScriptDir "\\chrome_window_test.txt")
FileAppend("Timestamp: " . A_Now . "`n`n", A_ScriptDir "\\chrome_window_test.txt")

try {
    windowCount := 0
    for window in WinGetList("ahk_class Chrome_WidgetWin_1") {
        windowCount++
        windowTitle := WinGetTitle(window)
        windowProcess := WinGetProcessName(window)
        windowPath := WinGetProcessPath(window)
        
        result := "Window #" . windowCount . "`n"
        result .= "  Title: " . windowTitle . "`n" 
        result .= "  Process: " . windowProcess . "`n"
        result .= "  Path: " . windowPath . "`n"
        result .= "  Would be closed by OLD logic: " . ((InStr(windowTitle, "Chrome") || windowTitle != "") ? "YES" : "NO") . "`n"
        result .= "  Would be closed by NEW logic: " . ((windowProcess = "chrome.exe" || windowProcess = "Google Chrome.exe") ? "YES" : "NO") . "`n"
        result .= "`n"
        
        FileAppend(result, A_ScriptDir "\\chrome_window_test.txt")
    }
    
    if (windowCount == 0) {
        FileAppend("No windows found with Chrome_WidgetWin_1 class.`n", A_ScriptDir "\\chrome_window_test.txt")
    } else {
        FileAppend("Total windows found: " . windowCount . "`n", A_ScriptDir "\\chrome_window_test.txt")
    }
} catch Error as e {
    FileAppend("Error: " . e.Message . "`n", A_ScriptDir "\\chrome_window_test.txt")
}

FileAppend("=== Test Complete ===`n", A_ScriptDir "\\chrome_window_test.txt")
TrayTip("Chrome Window Test", "Test complete - check chrome_window_test.txt", 5)