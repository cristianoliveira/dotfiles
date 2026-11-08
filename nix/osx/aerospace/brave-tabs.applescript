on targetIndex(currentIndex, tabCount, direction)
  if direction is "next" then
    set step to 1
  else if direction is "prev" then
    set step to -1
  else
    error "Expected next or prev."
  end if

  if tabCount < 1 then return 0
  return ((currentIndex - 1 + step + tabCount) mod tabCount) + 1
end targetIndex

on run argv
  if (count of argv) is not 1 then error "Expected one direction: next or prev."
  set direction to item 1 of argv
  -- Validate before sending any Apple Events to the browser.
  my targetIndex(0, 0, direction)

  if application id "com.brave.Browser" is not running then return
  tell application id "com.brave.Browser"
    if not frontmost then return
    if (count of windows) is 0 then return
    tell front window
      set tabCount to count of tabs
      if tabCount < 2 then return
      set active tab index to my targetIndex(active tab index, tabCount, direction)
    end tell
  end tell
end run
