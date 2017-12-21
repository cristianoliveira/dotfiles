xmodmap ~/.xmodmap
# make CapsLock behave like Ctrl:
setxkbmap -option ctrl:nocaps

# make short-pressed Ctrl behave like Escape:
xcape -e 'Control_L=Escape'

xcape -e 'Super_L=Escape' -t 300_
