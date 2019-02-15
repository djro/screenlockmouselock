# screenlockmouselock (tested in Ubuntu 16.04 only)
Locks a usb port (currently hard coded to xinput id=11) when the user session is locked, and unlocks the usb port when the session is unlocked.
If you have a mouse plugged into the coded usb port, the script will keep mouse movements from waking the monitor when the screen is locked.
Why is this useful? If you have a cat who likes to walk on your desk, your monitor won't turn on unless you press a keyboard key (which, fortunately for me, my cat is far less likely to touch).

1. To find which port your mouse is plugged into, run: xinput -list. Update the id variable in screenlockmouselock.sh (XINPUT_PROP_ID) to your id

2. Make sure to give script executable permissions (chmod +x screenlockmouselock.sh)

3. (!!important) Create an empty directory ~/.screenlockmouselock 

...This script assumes ~/.screenlockmouselock directory exists and currently blows up (in a evil bash loop) if the directory does not exist.
