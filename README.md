# ed-played-time
A Windows Power Shell script that attempts to total up Elite Dangerous played time

## Use

1. Open a Power Shell window.  If you search for 'powershell' in Windows 10 start menu
 you should get a hit on 'Windows PowerShell'.  Run that and it will open a window with a prompt.
1. use the `cd` command to Change Directory to where you downloaded the ed-played-time.ps1 script
1. Now just type `ed-played-time.ps1` and it should find all the Journal.\*.\*.log files in the standard location, find the first and last lines in each, and total up those time deltas.  It will output:
    1. The name of each Journal file found
    1. The Start time found
    1. The End time found
    1. The time delta this represents
    1. The current running total of time deltas found
