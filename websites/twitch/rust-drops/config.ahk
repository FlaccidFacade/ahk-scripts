; Configuration file for Twitch Rust Drops Automation
; Modify these values to customize the script behavior

; Debug mode - set to false to run silently
DEBUG_MODE := true

; Registry URL (shouldn't need to change)
REGISTRY_URL := "https://twitch.facepunch.com/"

; Time intervals for general drops (in hours)
GENERAL_DROPS_TIME := [2, 4, 6, 8, 10]

; Delay between checking streamers (in milliseconds)
STREAMER_CHECK_DELAY := 1000

; Delay between streamers (in milliseconds)
STREAMER_TRANSITION_DELAY := 3000

; Chrome loading delay (in milliseconds)
CHROME_LOAD_DELAY := 5000

; Minutes to add as buffer for each stream (to account for loading time)
TIME_BUFFER_MINUTES := 2

; Maximum time to wait for Chrome window to appear (in seconds)
CHROME_WAIT_TIMEOUT := 10