#Requires AutoHotkey v2.0

SetTimer(CheckAndCloseChrome, 1000)

CheckAndCloseChrome() {
  for window in WinGetList("ahk_class Chrome_WidgetWin_1") {
    if (InStr(WinGetTitle(window), "Chrome")) {
      WinClose(window)
    }
  }
}