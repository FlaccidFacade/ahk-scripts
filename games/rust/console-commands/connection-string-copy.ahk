#Requires AutoHotkey v2.0

; Hotkey: Alt+Shift+C -> copies "client.connect IP:PORT" for the current Rust server
!+c::{
  ClipSaved := ClipboardAll()
  A_Clipboard := ""

  Send("{F1}")                ; open console
  Sleep(150)
  Send("status{Enter}")       ; query server info
  Sleep(600)                  ; wait for output to render

  Send("^a")
  Sleep(50)
  Send("^c")
  if !ClipWait(1) {
    A_Clipboard := ClipSaved
    SoundBeep(900, 120)
    ToolTip("Failed to read console output")
    SetTimer(() => ToolTip(), -1200)
    Send("{F1}")            ; close console
    return
  }

  text := A_Clipboard
  ipPort := ""
  
    ; Final fallback: read Rust Player.log for the latest Connecting line
    ipPort := GetLatestConnectingIpPortFromLog()
 
 
  ; Prefer the explicit "Connecting: IP:PORT" log line if present
  if RegExMatch(text, "mi)Connecting:\s+(\d{1,3}(?:\.\d{1,3}){3}:\d{2,5})", &m) {
    ipPort := m[1]
  } 
  if RegExMatch(text, "mi)\b(\d{1,3}(?:\.\d{1,3}){3}:\d{2,5})\b", &m) {
    ; Fallback: any IP:PORT in the console text
    ipPort := m[1]
  }
  

  if ipPort != "" {
    A_Clipboard := "client.connect " ipPort
    ToolTip("Copied: " A_Clipboard)
    SetTimer(() => ToolTip(), -1500)
  } else {
    A_Clipboard := ClipSaved
    SoundBeep(900, 120)
    ToolTip("Server IP:PORT not found in console output loser")
    SetTimer(() => ToolTip(), -4500)
  }

  Send("{F1}")                ; close console
}

GetLatestConnectingIpPortFromLog() {
  path := GetRustPlayerLogPath()
  if path = "" || !FileExist(path) {
    return ""
  }
  ; Read the tail of the log to avoid huge file loads
  f := FileOpen(path, "r")
  if !f {
    return ""
  }
  size := f.Length
  chunkSize := 512000  ; ~500 KB from end
  if size > chunkSize {
    f.Pos := size - chunkSize
  }
  text := f.Read()
  f.Close()
  arr := StrSplit(text, "`n")
  i := arr.Length
  while i >= 1 {
    line := arr[i]
    i -= 1
    if RegExMatch(line, ".*", &m) {
      return m[1]
    }
  }
  return ""
}

GetRustPlayerLogPath() {
  ; Rust (Unity) logs typically at: %UserProfile%\AppData\LocalLow\Facepunch Studios LTD\Rust\Player.log
  localenv := EnvGet("LOCALAPPDATA")
  if !localenv {
    return ""
  }
  parent := RegExReplace(localenv, "\\Local$")
  return parent "\LocalLow\Facepunch Studios LTD\Rust\Player.log"
}