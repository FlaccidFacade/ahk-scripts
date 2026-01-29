#Requires AutoHotkey v2.0

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
    MsgBox "Failed to query the Twitch URL. Error: " . e.Message
    return false
  }
}