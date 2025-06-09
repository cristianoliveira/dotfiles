#!/bin/bash

ARG="$1"

if [[ -z "$ARG" ]]; then
  echo "Usage: $0 [w30|w50|w75|w100|h30|h50|h75|h100]"
  exit 1
fi

osascript <<EOF
on run
    set arg to "$ARG"
    if arg does not start with "w" and arg does not start with "h" then
        display dialog "Invalid argument: " & arg
        return
    end if

    set dir to character 1 of arg
    set percentString to characters 2 thru -1 of arg as string
    set percent to percentString as integer

    if percent ≤ 0 or percent > 100 then
        display dialog "Invalid percentage: " & percentString
        return
    end if

    -- Get screen dimensions
    tell application "Finder"
        set {screenX, screenY, screenW, screenH} to bounds of window of desktop
    end tell

    set newW to screenW
    set newH to screenH

    if dir is "w" then
        set newW to (screenW * percent) / 100
    else if dir is "h" then
        set newH to (screenH * percent) / 100
    end if

    -- Get frontmost window
    tell application "System Events"
        set frontApp to name of first application process whose frontmost is true
        tell application process frontApp
            if (count of windows) = 0 then return
            set win to front window
            set {winX, winY} to position of win
            set {winW, winH} to size of win
            set size of win to {newW, newH}
        end tell
    end tell
end run
EOF

