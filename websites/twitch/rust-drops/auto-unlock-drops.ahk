#Requires AutoHotkey v2.0

; Main Twitch Rust Drops Automation Script
; This script fetches streamer data from Facepunch registry, checks who's live,
; and opens Chrome to watch each stream for the required duration

; Import existing functions and configuration
#Include config.ahk

; IsUserLive function - checks if a Twitch streamer is currently live
IsUserLive(twitchUrl) {
    try {
        ; Send a GET request to the Twitch URL
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", twitchUrl)
        http.Send()

        ; Check if the response contains "isLive" or similar indicator
        response := http.ResponseText
        return InStr(response, "isLive") || InStr(response, "live_status")
    } catch Error as e {
        if (DEBUG_MODE) {
            Notify("Failed to query the Twitch URL: " . twitchUrl . ". Error: " . e.Message, 6)
        }
        return false
    }
}

; Helper function to repeat a string
RepeatString(str, count) {
    result := ""
    Loop count {
        result .= str
    }
    return result
}

; Non-blocking notification + logging helper with GUI window option
Notify(text, seconds := 4, showWindow := false) {
    ; append to status file
    try {
        FileAppend(Format("[{1}] {2}`n", A_Now, text), A_ScriptDir "\\drops_status.txt")
    } catch {
        ; ignore file write errors
    }
    
    ; Show in GUI window or tray tip based on preference
    if (showWindow) {
        ; Create or update status window
        ShowStatusWindow(text)
    } else {
        ; show a short tray tip
        TrayTip("Twitch Drops", text, seconds)
    }
}

; Status window for real-time updates
ShowStatusWindow(message) {
    static statusGui := ""
    static statusText := ""
    
    if (statusGui == "") {
        ; Create the GUI window
        statusGui := Gui("+Resize +MaximizeBox +MinimizeBox", "Twitch Drops Status")
        statusGui.SetFont("s10", "Consolas")
        statusText := statusGui.Add("Edit", "x10 y10 w600 h400 ReadOnly VScroll", "")
        statusGui.Show("w620 h420")
    }
    
    ; Update the window with latest status
    try {
        if (FileExist(A_ScriptDir "\\drops_status.txt")) {
            content := FileRead(A_ScriptDir "\\drops_status.txt")
            statusText.Text := content
            ; Auto-scroll to bottom
            statusText.Focus()
            Send("^{End}")
        }
    } catch {
        ; ignore read errors
    }
}

; Print comprehensive streamer status summary
PrintStreamerSummary(title, streamers, includeProgress := false) {
    if (streamers.Length == 0) {
        ; write empty status and notify
        FileAppend(title . "`n`nNo streamers found.`n", A_ScriptDir "\\drops_status.txt")
        TrayTip("Twitch Drops", "No streamers found (status written)", 5)
        return
    }
    
    summary := title . "`n" . RepeatString("=", 60) . "`n`n"
    
    for i, streamer in streamers {
        summary .= i . ". " . streamer.username . " (" . streamer.dropType . ")`n"
        summary .= "   Item: " . streamer.itemName . "`n"
        summary .= "   Required: " . streamer.minutes . " minutes`n"
        summary .= "   URL: " . streamer.url . "`n"
        
        if (includeProgress && StreamerProgress.Has(streamer.username)) {
            progress := StreamerProgress[streamer.username]
            summary .= "   Progress: " . progress.timeWatched . "/" . progress.requiredMinutes . " minutes"
            if (progress.isComplete) {
                summary .= " ✓ COMPLETE"
            }
            summary .= "`n"
        }
        
        summary .= "`n"
    }
    
    ; write summary to file and show a short tray notification instead of blocking MsgBox
    FileAppend(summary, A_ScriptDir "\\drops_status.txt")
    TrayTip("Twitch Drops", "Streamer list updated (saved to drops_status.txt)", 5)
}

; Print live check results summary
PrintLiveCheckResults(checkedStreamers, liveStreamers) {
    summary := "LIVE STATUS CHECK RESULTS`n" . RepeatString("=", 60) . "`n`n"
    summary .= "Checked: " . checkedStreamers.Length . " streamers`n"
    summary .= "Live: " . liveStreamers.Length . " streamers`n"
    summary .= "Offline: " . (checkedStreamers.Length - liveStreamers.Length) . " streamers`n`n"
    
    ; Live streamers
    if (liveStreamers.Length > 0) {
        summary .= "🟢 LIVE STREAMERS:`n"
        for i, streamer in liveStreamers {
            progress := StreamerProgress[streamer.username]
            remaining := streamer.minutes - progress.timeWatched
            summary .= "  " . i . ". " . streamer.username . " - " . streamer.itemName
            summary .= " (need " . remaining . " more min)`n"
        }
        summary .= "`n"
    }
    
    ; Offline streamers
    offlineStreamers := []
    for streamer in checkedStreamers {
        isLive := false
        for liveStreamer in liveStreamers {
            if (liveStreamer.username = streamer.username) {
                isLive := true
                break
            }
        }
        if (!isLive) {
            offlineStreamers.Push(streamer)
        }
    }
    
    if (offlineStreamers.Length > 0) {
        summary .= "🔴 OFFLINE STREAMERS:`n"
        for i, streamer in offlineStreamers {
            progress := StreamerProgress[streamer.username]
            remaining := streamer.minutes - progress.timeWatched
            summary .= "  " . i . ". " . streamer.username . " - " . streamer.itemName
            summary .= " (need " . remaining . " more min)`n"
        }
    }
    
    FileAppend(summary, A_ScriptDir "\\drops_status.txt")
    TrayTip("Twitch Drops", "Live check results saved to drops_status.txt", 5)
}

; Print current progress summary
PrintProgressSummary() {
    summary := "CURRENT PROGRESS SUMMARY`n" . RepeatString("=", 60) . "`n`n"
    
    completeCount := 0
    incompleteCount := 0
    totalTimeWatched := 0
    
    for username, progress in StreamerProgress {
        totalTimeWatched += progress.timeWatched
        if (progress.isComplete) {
            completeCount++
        } else {
            incompleteCount++
        }
    }
    
    summary .= "Total streamers: " . StreamerProgress.Count . "`n"
    summary .= "Complete: " . completeCount . " ✓`n"
    summary .= "Incomplete: " . incompleteCount . "`n"
    summary .= "Total time watched: " . Round(totalTimeWatched / 60, 1) . " hours`n`n"
    
    if (incompleteCount > 0) {
        summary .= "INCOMPLETE STREAMERS:`n"
        count := 1
        for username, progress in StreamerProgress {
            if (!progress.isComplete) {
                remaining := progress.requiredMinutes - progress.timeWatched
                summary .= "  " . count . ". " . username . " - " . progress.itemName . "`n"
                summary .= "     Progress: " . progress.timeWatched . "/" . progress.requiredMinutes . " min"
                summary .= " (need " . remaining . " more)`n"
                count++
            }
        }
        summary .= "`n"
    }
    
    if (completeCount > 0) {
        summary .= "COMPLETED STREAMERS:`n"
        count := 1
        for username, progress in StreamerProgress {
            if (progress.isComplete) {
                summary .= "  " . count . ". " . username . " - " . progress.itemName . " ✓`n"
                count++
            }
        }
    }
    
    FileAppend(summary, A_ScriptDir "\\drops_status.txt")
    TrayTip("Twitch Drops", "Progress summary saved to drops_status.txt", 5)
}

; Print general drops information
PrintGeneralDropsSummary() {
    if (GeneralDrops.Length == 0) {
        return
    }
    
    summary := "GENERAL DROPS (work on any Rust stream)`n" . RepeatString("=", 60) . "`n`n"
    
    for i, drop in GeneralDrops {
        summary .= i . ". " . drop.itemName . "`n"
        summary .= "   Required: " . drop.hours . " hours (" . drop.minutes . " minutes)`n"
        summary .= "   Works on: Any Rust category stream`n`n"
    }
    
    FileAppend(summary, A_ScriptDir "\\drops_status.txt")
    TrayTip("Twitch Drops", "General drops info saved to drops_status.txt", 3)
}

; Streamer data structure: {username, url, minutes, dropType, itemName}
StreamerDrops := []

; General drops data structure: {hours, minutes, itemName}
GeneralDrops := []

; Progress tracking: {username, timeWatched, isComplete, lastChecked}
StreamerProgress := Map()

; Current viewing session info
CurrentStreamer := ""
SessionStartTime := 0

; Global running flag - set to false to stop automation
Running := true

; Global flag to force skip current streamer - set to true to skip
SkipCurrentStreamer := false

; Hotkey to immediately stop automation and clean up: Ctrl+Alt+Q
^!q::ExitAutomation()

; Hotkey to force stop/skip current streamer: Ctrl+Alt+S
^!s::ForceStopCurrentStreamer()

; Hotkey to show/hide progress window: Ctrl+Alt+P
^!p::ToggleProgressWindow()

; Graceful shutdown: stops automation and closes Chrome
ExitAutomation() {
    Running := false
    ; Close Chrome windows
    try {
        for window in WinGetList("ahk_class Chrome_WidgetWin_1") {
            WinClose(window)
        }
    } catch {
        ; ignore
    }
    ; Log and notify without blocking
    FileAppend("Automation stopped by user (Ctrl+Alt+Q).`n", A_ScriptDir "\\drops_status.txt")
    TrayTip("Twitch Drops", "Automation stopped by user (Ctrl+Alt+Q)", 5)
    ExitApp
}

; Force stop/skip current streamer: moves to next available streamer
ForceStopCurrentStreamer() {
    SkipCurrentStreamer := true
    ; Log the action
    if (CurrentStreamer != "") {
        logMessage := "Force stopped current streamer: " . CurrentStreamer . " (Ctrl+Alt+S)"
        FileAppend(logMessage . "`n", A_ScriptDir "\\drops_status.txt")
        TrayTip("Twitch Drops", "Skipping " . CurrentStreamer . "...", 3)
        Notify("Force stopping " . CurrentStreamer . " and moving to next available streamer...", 5, true)
    } else {
        TrayTip("Twitch Drops", "No active streamer to skip", 3)
    }
}

; Global variable to track progress window state
ProgressWindowVisible := false

; Toggle progress window visibility
ToggleProgressWindow() {
    ProgressWindowVisible := !ProgressWindowVisible
    if (ProgressWindowVisible) {
        ShowProgressWindow()
    } else {
        HideProgressWindow()
    }
}

; Enhanced progress window showing detailed real-time progress
ShowProgressWindow() {
    static progressGui := ""
    static progressText := ""
    
    if (progressGui == "") {
        ; Create the GUI window
        progressGui := Gui("+Resize +MaximizeBox +MinimizeBox", "Twitch Drops - Real-Time Progress")
        progressGui.SetFont("s10", "Consolas")
        progressText := progressGui.Add("Edit", "x10 y10 w800 h500 ReadOnly VScroll", "")
        
        ; Add refresh button
        refreshBtn := progressGui.Add("Button", "x10 y520 w100 h30", "&Refresh")
        refreshBtn.OnEvent("Click", RefreshProgress)
        
        ; Add close button
        closeBtn := progressGui.Add("Button", "x120 y520 w100 h30", "&Close")
        closeBtn.OnEvent("Click", (*) => HideProgressWindow())
        
        progressGui.OnEvent("Close", (*) => HideProgressWindow())
    }
    
    ; Update content and show
    RefreshProgressContent()
    progressGui.Show("w820 h560")
    ProgressWindowVisible := true
}

; Hide progress window
HideProgressWindow() {
    static progressGui := ""
    if (progressGui != "") {
        progressGui.Hide()
    }
    ProgressWindowVisible := false
}

; Refresh progress content
RefreshProgress(*) {
    RefreshProgressContent()
}

; Update progress window content
RefreshProgressContent() {
    static progressGui := ""
    static progressText := ""
    
    if (progressGui == "" || !ProgressWindowVisible) {
        return
    }
    
    content := BuildProgressContent()
    progressText.Text := content
    
    ; Auto-scroll to show current activity
    ; Scroll to top of the Edit control (progressText)
    SendMessage(0x00B1, 0, 0, progressText)  ; EM_SETSEL: set selection to start, scrolls to top
}


; Build comprehensive progress content for the progress window
BuildProgressContent() {
    currentTime := A_Now
    content := "TWITCH DROPS AUTOMATION - REAL-TIME PROGRESS`n"
    content .= RepeatString("=", 80) . "`n`n"
    content .= "Last Updated: " . FormatTime(currentTime, "yyyy-MM-dd HH:mm:ss") . "`n`n"
    
    ; Current status section
    content .= "CURRENT STATUS`n" . RepeatString("-", 40) . "`n"
    if (CurrentStreamer != "") {
        sessionTime := Round((A_TickCount - SessionStartTime) / 60000, 1)
        progress := StreamerProgress[CurrentStreamer]
        content .= "🔴 Currently Watching: " . CurrentStreamer . "`n"
        content .= "   Item: " . progress.itemName . "`n"
        content .= "   Session Time: " . sessionTime . " minutes`n"
        content .= "   Total Progress: " . progress.timeWatched . "/" . progress.requiredMinutes . " minutes`n"
        remaining := progress.requiredMinutes - progress.timeWatched
        content .= "   Remaining: " . remaining . " minutes`n"
        if (progress.isComplete) {
            content .= "   Status: ✅ COMPLETED`n"
        } else {
            percentage := Round((progress.timeWatched / progress.requiredMinutes) * 100, 1)
            content .= "   Status: 🔄 In Progress (" . percentage . "%)`n"
        }
    } else {
        content .= "⏸️ No streamer currently active`n"
    }
    content .= "`n"
    
    ; Overall progress summary
    completeCount := 0
    incompleteCount := 0
    totalTimeWatched := 0
    
    for username, progress in StreamerProgress {
        totalTimeWatched += progress.timeWatched
        if (progress.isComplete) {
            completeCount++
        } else {
            incompleteCount++
        }
    }
    
    content .= "OVERALL PROGRESS SUMMARY`n" . RepeatString("-", 40) . "`n"
    content .= "Total Streamers: " . StreamerProgress.Count . "`n"
    content .= "✅ Completed: " . completeCount . "`n"
    content .= "🔄 In Progress: " . incompleteCount . "`n"
    content .= "⏱️ Total Time Watched: " . Round(totalTimeWatched / 60, 1) . " hours`n`n"
    
    ; Completed streamers
    if (completeCount > 0) {
        content .= "✅ COMPLETED STREAMERS`n" . RepeatString("-", 40) . "`n"
        count := 1
        for username, progress in StreamerProgress {
            if (progress.isComplete) {
                content .= count . ". " . username . " - " . progress.itemName . " (✓ " . progress.timeWatched . " min)`n"
                count++
            }
        }
        content .= "`n"
    }
    
    ; Incomplete streamers
    if (incompleteCount > 0) {
        content .= "🔄 STREAMERS IN PROGRESS`n" . RepeatString("-", 40) . "`n"
        count := 1
        for username, progress in StreamerProgress {
            if (!progress.isComplete) {
                remaining := progress.requiredMinutes - progress.timeWatched
                percentage := Round((progress.timeWatched / progress.requiredMinutes) * 100, 1)
                status := (username == CurrentStreamer) ? " 🔴 ACTIVE" : ""
                content .= count . ". " . username . " - " . progress.itemName . status . "`n"
                content .= "    Progress: " . progress.timeWatched . "/" . progress.requiredMinutes . " min (" . percentage . "%) - Need " . remaining . " more`n"
                count++
            }
        }
        content .= "`n"
    }
    
    ; Controls information
    content .= "🎮 KEYBOARD CONTROLS`n" . RepeatString("-", 40) . "`n"
    content .= "Ctrl+Alt+P: Toggle this progress window`n"
    content .= "Ctrl+Alt+S: Force stop/skip current streamer`n"
    content .= "Ctrl+Alt+Q: Stop automation completely`n`n"
    
    ; Recent activity (last few lines from drops_status.txt)
    content .= "📋 RECENT ACTIVITY`n" . RepeatString("-", 40) . "`n"
    try {
        if (FileExist(A_ScriptDir "\\drops_status.txt")) {
            fullLog := FileRead(A_ScriptDir "\\drops_status.txt")
            lines := StrSplit(fullLog, "`n")
            recentLines := Min(10, lines.Length)  ; Show last 10 lines
            startIndex := Max(1, lines.Length - recentLines + 1)
            
            Loop recentLines {
                lineIndex := startIndex + A_Index - 1
                if (lineIndex <= lines.Length && Trim(lines[lineIndex]) != "") {
                    content .= lines[lineIndex] . "`n"
                }
            }
        }
    } catch {
        content .= "Unable to read recent activity log.`n"
    }
    
    return content
}


; Main execution
Main()

Main() {
    if (DEBUG_MODE) {
        Notify("Starting Dynamic Twitch Rust Drops Automation...", 3, true)
    }
    
    ; Initialize streamer data
    if (!FetchStreamerData()) {
        FileAppend("Failed to fetch streamer data from registry. Exiting.`n", A_ScriptDir "\\drops_status.txt")
        TrayTip("Twitch Drops", "Failed to fetch registry. See drops_status.txt", 5)
        return
    }
    
    ; Show initial streamer list
    if (DEBUG_MODE) {
        PrintStreamerSummary("PARSED STREAMERS FROM FACEPUNCH REGISTRY", StreamerDrops)
        PrintGeneralDropsSummary()
    }
    
    ; Initialize progress tracking for all streamers
    InitializeProgress()
    
    ; Main automation loop - continues until all streamers are complete
    Loop {
        if (!Running) {
            break
        }
        ; Show current progress
        if (DEBUG_MODE) {
            PrintProgressSummary()
        }
        
        ; Check if we have any incomplete streamers
        incompleteStreamers := GetIncompleteStreamers()
        if (incompleteStreamers.Length == 0) {
            FileAppend("All streamers completed! Drops automation finished successfully!`n", A_ScriptDir "\\drops_status.txt")
            TrayTip("Twitch Drops", "All streamers completed!", 5)
            break
        }
        
        ; Get currently live streamers from incomplete list
        liveStreamers := GetLiveStreamersFromList(incompleteStreamers)
        
        if (liveStreamers.Length == 0) {
            FileAppend("No live streamers found. Waiting 10 minutes before rechecking...\n", A_ScriptDir "\\drops_status.txt")
            TrayTip("Twitch Drops", "No live streamers found. Rechecking in 10 minutes.", 5)
            Sleep 600000 ; Wait 10 minutes
            continue
        }
        
        ; Select next streamer to watch (prioritize least watched)
        nextStreamer := SelectNextStreamer(liveStreamers)
        
        if (DEBUG_MODE) {
            remainingTime := nextStreamer.minutes - StreamerProgress[nextStreamer.username].timeWatched
            FileAppend("Selected streamer: " . nextStreamer.username . " - " . nextStreamer.itemName . " (need " . remainingTime . " min)\n", A_ScriptDir "\\drops_status.txt")
            ; Show in console window instead of notification
            Run("notepad.exe " . A_ScriptDir . "\\drops_status.txt")
        }
        
        ; Watch the streamer with periodic checks
        WatchStreamerWithChecks(nextStreamer)
        
        ; Small break between streamers
        Sleep 3000
    }
    
    ; Final completion summary
    PrintProgressSummary()
    FileAppend("Twitch Drops automation completed successfully!`n", A_ScriptDir "\\drops_status.txt")
    TrayTip("Twitch Drops", "Automation completed successfully!", 5)
}

; Fetch streamer data from Facepunch registry
FetchStreamerData() {
    try {
        if (DEBUG_MODE) {
            Notify("Fetching data from " . REGISTRY_URL, 4)
        }
        
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", REGISTRY_URL)
        http.Send()
        
        response := http.ResponseText
        
        if (DEBUG_MODE) {
            Notify("Successfully fetched HTML content. Length: " . StrLen(response) . " characters", 4)
        }
        
        ; Parse the HTML content to extract streamer data
        ParseStreamerData(response)
        
        ; Call additional parsing for detailed drop information
        ParseDropDetails(response)
        
        return true
        
        } catch Error as e {
        if (DEBUG_MODE) {
            Notify("Error fetching registry: " . e.Message, 6)
        }
        return false
    }
}

; Parse HTML response to extract streamer information
ParseStreamerData(html) {
    ; Clear existing data
    StreamerDrops := []
    
    if (DEBUG_MODE) {
        Notify("Parsing HTML content from Facepunch registry...", 3)
    }
    
    ; Parse General Drops (available on any Rust stream)
    ParseGeneralDrops(html)
    
    ; Parse Streamer-specific Drops
    ParseStreamerSpecificDrops(html)
    
    if (DEBUG_MODE) {
        Notify("Parsed " . StreamerDrops.Length . " streamers from registry.", 4)
    }
}

; Parse General Drops section
ParseGeneralDrops(html) {
    ; Look for general drops pattern: "ITEM 󰥔 X HOURS"
    ; Extract time requirements for general drops
    generalDropTimes := []
    
    ; Regex to find patterns like "2 HOURS", "4 HOURS", etc.
    pos := 1
    while (pos := RegExMatch(html, "i)(\d+)\s+HOUR", &match, pos)) {
        hours := Integer(match[1])
        ; Convert hours to minutes
        minutes := hours * 60
        
        ; Add to separate GeneralDrops array - these work on any Rust stream
        GeneralDrops.Push({
            hours: hours,
            minutes: minutes,
            itemName: "General Drop (" . hours . "h)",
            dropType: "general"
        })
        
        pos := match.Pos + match.Len
    }
}

; Parse Streamer-specific Drops section  
ParseStreamerSpecificDrops(html) {
    ; Look for streamer links pattern: https://www.twitch.tv/StreamerName
    ; and associated time requirements
    
    pos := 1
    while (pos := RegExMatch(html, "i)https://www\.twitch\.tv/([a-zA-Z0-9_]+)", &match, pos)) {
        streamerName := match[1]
        streamerUrl := match[0]
        
        ; Skip if it's a general category link
        if (InStr(streamerName, "directory") || InStr(streamerName, "category")) {
            pos := match.Pos + match.Len
            continue
        }
        
        ; Look for time requirement near this streamer (search in surrounding text)
        ; Extract 500 characters after the streamer link to find time info
        searchStart := match.Pos
        searchEnd := Min(searchStart + 500, StrLen(html))
        nearbyText := SubStr(html, searchStart, searchEnd - searchStart)
        
        ; Default to 1 hour if no specific time found (common for streamer drops)
        minutes := 60
        dropType := "streamer"
        itemName := "Streamer Drop"
        
        ; Look for hour patterns in nearby text
        if (RegExMatch(nearbyText, "i)(\d+)\s+HOUR", &timeMatch)) {
            minutes := Integer(timeMatch[1]) * 60
            itemName := "Streamer Drop (" . timeMatch[1] . "h)"
        }
        
        ; Look for item names (common patterns from the page)
        if (InStr(nearbyText, "VAGABOND JACKET")) {
            itemName := "Vagabond Jacket"
        } else if (InStr(nearbyText, "LARGE BACKPACK")) {
            itemName := "Large Backpack"  
        } else if (InStr(nearbyText, "SLEEPING BAG")) {
            itemName := "Sleeping Bag"
        } else if (InStr(nearbyText, "FRIDGE")) {
            itemName := "Fridge"
        }
        
        ; Check if we already have this streamer (avoid duplicates)
        alreadyExists := false
        for existingStreamer in StreamerDrops {
            if (existingStreamer.username = streamerName) {
                alreadyExists := true
                break
            }
        }
        
        if (!alreadyExists) {
            StreamerDrops.Push({
                username: streamerName,
                url: streamerUrl,
                minutes: minutes,
                dropType: dropType,
                itemName: itemName
            })
        }
        
        pos := match.Pos + match.Len
    }
}

; Enhanced parsing function to extract drop items and their requirements
ParseDropDetails(html) {
    ; This function can be expanded to parse more detailed drop information
    ; such as specific item requirements, claim counts, etc.
    
    if (DEBUG_MODE) {
        ; Count total drops found
        streamerDropCount := StreamerDrops.Length
        generalDropCount := GeneralDrops.Length
        
        Notify("Parsing complete: Streamer drops=" . streamerDropCount . ", General drops=" . generalDropCount . ", Total=" . (streamerDropCount + generalDropCount), 5, true)
    }
}

; Initialize progress tracking for all streamers
InitializeProgress() {
    ; Only track progress for actual streamers, not general drops
    for streamer in StreamerDrops {
        StreamerProgress[streamer.username] := {
            timeWatched: 0,
            isComplete: false,
            lastChecked: 0,
            requiredMinutes: streamer.minutes,
            dropType: streamer.dropType,
            itemName: streamer.itemName
        }
    }
    
    if (DEBUG_MODE) {
        streamerCount := StreamerDrops.Length
        generalCount := GeneralDrops.Length
        
        Notify("Initialized progress tracking: streamer-specific=" . streamerCount . ", general=" . generalCount . ", total streamers tracked=" . StreamerProgress.Count, 6, true)
    }
}

; Get list of streamers that haven't completed their required time
GetIncompleteStreamers() {
    incompleteList := []
    
    for streamer in StreamerDrops {
        progress := StreamerProgress[streamer.username]
        if (!progress.isComplete && progress.timeWatched < streamer.minutes) {
            incompleteList.Push(streamer)
        }
    }
    
    return incompleteList
}

; Check live status for specific list of streamers
GetLiveStreamersFromList(streamerList) {
    liveStreamers := []
    
    if (DEBUG_MODE) {
        PrintStreamerSummary("CHECKING LIVE STATUS FOR STREAMERS", streamerList, true)
    }
    
    for streamer in streamerList {
        if (IsUserLive(streamer.url)) {
            liveStreamers.Push(streamer)
            StreamerProgress[streamer.username].lastChecked := A_TickCount
        }
        
        ; Small delay to avoid rate limiting
        Sleep 1000
    }
    
    ; Show consolidated results
    if (DEBUG_MODE) {
        PrintLiveCheckResults(streamerList, liveStreamers)
    }
    
    return liveStreamers
}

; Select next streamer prioritizing those with least watch time
SelectNextStreamer(liveStreamers) {
    if (liveStreamers.Length == 0) {
        return ""
    }
    
    ; Find streamer with least watch time
    selectedStreamer := liveStreamers[1]
    minWatchTime := StreamerProgress[selectedStreamer.username].timeWatched
    
    for streamer in liveStreamers {
        watchTime := StreamerProgress[streamer.username].timeWatched
        if (watchTime < minWatchTime) {
            minWatchTime := watchTime
            selectedStreamer := streamer
        }
    }
    
    return selectedStreamer
}

; Watch a streamer with periodic live checks (max 60 minutes per session)
WatchStreamerWithChecks(streamer) {
    CurrentStreamer := streamer.username
    SessionStartTime := A_TickCount
    
    ; Close any existing Chrome windows first
    CloseAllChrome()
    Sleep 2000
    
    ; Open Chrome to the streamer's channel
    if (!OpenChromeForStreamer(streamer)) {
        return false
    }
    
    ; Calculate how long to watch this session (max 60 minutes or remaining time)
    progress := StreamerProgress[streamer.username]
    remainingTime := streamer.minutes - progress.timeWatched
    sessionTime := Min(60, remainingTime) ; Max 60 minutes per session
    
    if (DEBUG_MODE) {
        Notify("Starting " . sessionTime . " minute session for " . streamer.username, 5, true)
    }
    
    ; Watch with 10-minute live checks
    watchResult := WatchWithPeriodicChecks(streamer, sessionTime)
    
    ; Close Chrome after session
    CloseAllChrome()
    
    return watchResult
}

; Watch streamer with periodic live checks every 10 minutes
WatchWithPeriodicChecks(streamer, maxMinutes) {
    totalWatchedThisSession := 0
    checkIntervalMinutes := 10
    
    Loop {
        ; Check if user requested to skip current streamer
        if (SkipCurrentStreamer) {
            if (DEBUG_MODE) {
                FileAppend("User requested to skip " . streamer.username . " after " . totalWatchedThisSession . " minutes. Moving to next streamer.`n", A_ScriptDir "\\drops_status.txt")
                TrayTip("Twitch Drops", "Skipped " . streamer.username . " - moving to next", 5)
            }
            SkipCurrentStreamer := false  ; Reset flag
            break
        }
        
        ; Calculate remaining time for this check period
        if (!Running) {
            break
        }
        remainingInSession := maxMinutes - totalWatchedThisSession
        if (remainingInSession <= 0) {
            break
        }
        
        ; Watch for up to 10 minutes or remaining time
        watchTime := Min(checkIntervalMinutes, remainingInSession)
        
        if (DEBUG_MODE && totalWatchedThisSession == 0) {
            ; non-blocking notification
            TrayTip("Twitch Drops", "Starting " . watchTime . " minute session for " . streamer.username, 5)
            FileAppend("Started session for " . streamer.username . " (" . watchTime . " min)`n", A_ScriptDir "\\drops_status.txt")
        }
        
        ; Watch for the specified time
        if (!Running) {
            break
        }
        if (!WaitForDuration(watchTime)) {
            ; Chrome was closed or error occurred
            break
        }
        
        ; Check again if user requested to skip (might have been set during WaitForDuration)
        if (SkipCurrentStreamer) {
            if (DEBUG_MODE) {
                FileAppend("User requested to skip " . streamer.username . " after " . totalWatchedThisSession . " minutes. Moving to next streamer.`n", A_ScriptDir "\\drops_status.txt")
                TrayTip("Twitch Drops", "Skipped " . streamer.username . " - moving to next", 5)
            }
            SkipCurrentStreamer := false  ; Reset flag
            break
        }
        
        ; Update progress
        totalWatchedThisSession += watchTime
        StreamerProgress[streamer.username].timeWatched += watchTime
        
        ; Update progress window if visible
        if (ProgressWindowVisible) {
            RefreshProgressContent()
        }
        
        ; Check if streamer completed their requirement
        if (StreamerProgress[streamer.username].timeWatched >= streamer.minutes) {
            StreamerProgress[streamer.username].isComplete := true
            if (DEBUG_MODE) {
                FileAppend(streamer.username . " COMPLETED! Total time watched: " . StreamerProgress[streamer.username].timeWatched . " minutes - Item: " . streamer.itemName . "`n", A_ScriptDir "\\drops_status.txt")
                Notify(streamer.username . " completed!", 5, true)
            }
            break
        }
        
        ; Check if we've reached max session time
        if (totalWatchedThisSession >= maxMinutes) {
            if (DEBUG_MODE) {
                FileAppend("Session limit reached for " . streamer.username . " (" . totalWatchedThisSession . " min). Total watched: " . StreamerProgress[streamer.username].timeWatched . "`n", A_ScriptDir "\\drops_status.txt")
                TrayTip("Twitch Drops", "Session limit reached for " . streamer.username, 5)
            }
            break
        }
        
        ; Check if streamer is still live (every 10 minutes)
        if (DEBUG_MODE) {
            TrayTip("Twitch Drops", "Checking live status for " . streamer.username, 3)
        }
        
        if (!IsUserLive(streamer.url)) {
            if (DEBUG_MODE) {
                FileAppend(streamer.username . " went offline during session. Session watched: " . totalWatchedThisSession . " minutes. Total watched: " . StreamerProgress[streamer.username].timeWatched . "`n", A_ScriptDir "\\drops_status.txt")
                TrayTip("Twitch Drops", streamer.username . " went offline", 5)
            }
            break
        }
        
        if (DEBUG_MODE) {
            TrayTip("Twitch Drops", streamer.username . " still live", 2)
        }
    }
    
    return true
}

; Open Chrome for a specific streamer (updated to return success/failure)
OpenChromeForStreamer(streamer) {
    try {
        Run 'chrome.exe "' . streamer.url . '"'
        Sleep 5000  ; Wait for Chrome to load
        
        ; Maximize the window for better drop detection
        WinWait "ahk_class Chrome_WidgetWin_1",, 10
        if (WinExist("ahk_class Chrome_WidgetWin_1")) {
            WinMaximize
            return true
        } else {
            Notify("Chrome window did not appear within timeout.", 6)
            return false
        }
        
    } catch Error as e {
        Notify("Error opening Chrome: " . e.Message, 6)
        return false
    }
}

; Wait for specified duration with Chrome monitoring (updated to return success/failure)
WaitForDuration(minutes) {
    totalSeconds := minutes * 60
    remainingSeconds := totalSeconds
    
    ; Update every minute
    Loop {
        if (!Running || SkipCurrentStreamer) {
            return false
        }
        if (remainingSeconds <= 0) {
            break
        }
        
        ; Check if Chrome is still open
        if (!WinExist("ahk_class Chrome_WidgetWin_1")) {
            if (DEBUG_MODE) {
                    Notify("Chrome window closed unexpectedly.", 6)
                }
            return false
        }
        
        ; Progress update every 5 minutes
        if (DEBUG_MODE && Mod(remainingSeconds, 300) == 0) {
            minutesLeft := Round(remainingSeconds / 60, 1)
            progressText := "Time remaining this session: " . minutesLeft . " minutes"
            if (CurrentStreamer != "") {
                totalWatched := StreamerProgress[CurrentStreamer].timeWatched
                progressText .= "`nTotal watched for " . CurrentStreamer . ": " . totalWatched . " minutes"
            }
            Notify(progressText, 5)
            
            ; Update progress window if visible
            if (ProgressWindowVisible) {
                RefreshProgressContent()
            }
        }
        
        Sleep 60000  ; Wait 1 minute
        remainingSeconds -= 60
    }
    
    return true
}

; Close all Chrome windows
CloseAllChrome() {
    try {
        for window in WinGetList("ahk_class Chrome_WidgetWin_1") {
            if (InStr(WinGetTitle(window), "Chrome") || WinGetTitle(window) != "") {
                WinClose(window)
            }
        }
        Sleep 2000  ; Wait for windows to close
    } catch {
        ; Ignore errors when closing
    }
}

