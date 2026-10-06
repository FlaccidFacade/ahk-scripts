#Requires AutoHotkey v2.0
; GUI manager: enable/disable which staged .ahk scripts run at startup.

STAGE_DIR   := A_MyDocuments "\AutoHotkey-Scripts"
STARTUP_DIR := A_AppData "\Microsoft\Windows\Start Menu\Programs\Startup"

; Collect staged scripts recursively, with a fake-ok blank list message.
scripts := []
if DirExist(STAGE_DIR)
    Loop Files STAGE_DIR "\*.ahk", "R"
    {
        if (SubStr(A_LoopFileName, 1, 1) = "." || InStr(A_LoopFileDir, "\."))
            continue
        relDir := Trim(SubStr(A_LoopFileDir, StrLen(STAGE_DIR) + 1), "\")
        scripts.Push({ name: (relDir ? StrReplace(relDir, "\", "-") . "-" : "") . A_LoopFileName,
                       staged: A_LoopFileFullPath })
    }

CleanupOrphans()

; Build the GUI.
myGui := Gui("+Resize", "AHK Startup Manager")
myGui.SetFont("s10")
myGui.AddText(, "Check = runs at startup.")
lv := myGui.AddListView("w600 r20 Checked -ReadOnly NoSort", ["Script"])
for s in scripts {
    row := lv.Add(, s.name)
    lnk := STARTUP_DIR "\" s.name ".lnk"
    if FileExist(lnk)
        lv.Modify(row, "Check")   ; existing shortcut = currently enabled
    else
        lv.Modify(row, "-Check")
}
myGui.AddButton("Default w120", "&Apply").OnEvent("Click", ApplyChanges)
myGui.Show()

ApplyChanges(*) {
    cnt := 0
    Loop lv.GetCount() {
        lnk := STARTUP_DIR "\" lv.GetText(A_Index) ".lnk"
        if (lv.GetNext(A_Index - 1, "C") = A_Index) {   ; row itself is checked
            if !FileExist(lnk) {
                FileCreateShortcut(scripts[A_Index].staged, lnk, STAGE_DIR)
                cnt++
            }
        } else if FileExist(lnk) {
            FileDelete(lnk)
            cnt++
        }
    }
    TrayTip("Applied: " . cnt . " change(s).", "AHK Startup Manager", 5)
}

CleanupOrphans() {
    removed := 0
    valid := Map()
    valid.CaseSense := false
    for s in scripts
        valid[s.name ".lnk"] := true

    Loop Files STARTUP_DIR "\*.lnk" {
        if valid.Has(A_LoopFileName)
            continue
        ; Only delete shortcuts we created: target must live in STAGE_DIR.
        FileGetShortcut(A_LoopFileFullPath, &target)
        if (target && InStr(target, STAGE_DIR "\") = 1) {
            FileDelete(A_LoopFileFullPath)
            removed++
        }
    }
    if removed
        TrayTip("Removed " . removed . " orphaned shortcut(s).", "AHK Startup Manager", 5)
}