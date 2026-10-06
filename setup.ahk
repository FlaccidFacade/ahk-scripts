#Requires AutoHotkey v2.0
; Copies .ahk scripts from WSL repo to a Windows staging folder,
; then creates startup shortcuts targeting the staged copies.

; Define startup, source, and staging directories.
STARTUP_DIR := A_AppData "\Microsoft\Windows\Start Menu\Programs\Startup"
SOURCE_DIR  := "\\wsl.localhost\Ubuntu-24.04\home\flaccidfacade\src\ahk-scripts"
STAGE_DIR   := A_MyDocuments "\AutoHotkey-Scripts"

; Ensure STARTUP_DIR and STAGE_DIR exist.
if !DirExist(STARTUP_DIR)
    DirCreate(STARTUP_DIR)
if !DirExist(STAGE_DIR)
    DirCreate(STAGE_DIR)

; Bail out with a warning if the WSL share isn't reachable
; (e.g. WSL not started, or wsl.localhost unsupported on this build).
if !DirExist(SOURCE_DIR) {
    MsgBox("Source not reachable:`n`n" SOURCE_DIR
        . "`n`nMake sure WSL is running (open a terminal first) "
        . "and that the distro name matches.", "AHK Startup Setup")
    ExitApp(1)
}

; Counters.
created := 0
updated := 0

Loop Files SOURCE_DIR "\*.ahk", "R"
{
    srcFull := A_LoopFileFullPath
    srcName := A_LoopFileName

    if (SubStr(srcName, 1, 1) = "." || InStr(A_LoopFileDir, "\\."))
        continue

    relDir  := SubStr(A_LoopFileDir, StrLen(SOURCE_DIR) + 1)
    destDir := STAGE_DIR relDir
    if !DirExist(destDir)
        DirCreate(destDir)
    staged := destDir "\" srcName

    FileCopy(srcFull, staged, 1)
    updated++

    dotPos := InStr(srcName, ".", false, -1)
    baseName := dotPos ? SubStr(srcName, 1, dotPos - 1) : srcName

    linkPath := STARTUP_DIR "\" StrReplace(relDir, "\", "-") "-" baseName ".lnk"
    if !FileExist(linkPath) {
        FileCreateShortcut(staged, linkPath, STAGE_DIR)
        created++
    }
}

; Summary.
msg := "AutoHotkey Startup Shortcuts Summary`n`n"
    . "Source folder: " . SOURCE_DIR . "`n"
    . "Staging folder: " . STAGE_DIR . "`n"
    . "Startup folder: " . STARTUP_DIR . "`n`n"
    . "Files synced: " . updated . "`n"
    . "Shortcuts created: " . created

TrayTip("Synced " . updated . " script(s), created " . created . " shortcut(s).", "AHK Startup Setup", 5)
MsgBox(msg, "AHK Startup Setup")