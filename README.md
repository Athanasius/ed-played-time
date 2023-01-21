**This project has been retired (but the live version might still be running).  Please fork and continue work on it if you find it useful.**
===

# ed-played-time
A Windows Power Shell script that attempts to total up Elite Dangerous played time

## Use

1. Open a Power Shell window.  If you search for 'powershell' in Windows 10 start menu
 you should get a hit on 'Windows PowerShell'.  Run that and it will open a window with a prompt.
1. use the `cd` command to Change Directory to where you downloaded the ed-played-time.ps1 script
1. Now just type `ed-played-time.ps1` and hit return to run the script.  It should find all the Journal.\*.\*.log files in the standard location, find all the gameplay sessions in each, and total up those play times.
It will output:
    1. A line for each Journal file found: `parse_journal Journal.YYMMDDHHMMSS.NN.log`
    1. The total time played it found.
1.  It will also write a file `ed-played-time.csv` in the Journals folder.  This, obviously, is a CSV format file with each line containing the 'end' timestamp and time delta for a session.  This should be easy to import into any spreadsheet for further processing, such as making a graph.

If you happen to have `.ps1` files associated with `Windows PowerShell` on your system then you might be able to just double-click the file to get it to do its work.  On my system they're associated with `NotePad` (security paranoia).  If I manually `Open with` PowerShell then the window flashes up and closes before I can see much of anything.  

If you like you can supply one, or both, of the `-verbose` and `-debug` command-line flags in order to get more output.  
* `-verbose` - Show the start and end times of each session it found, the time different between them, and the new total played time up to that point.
* `-debug` - Lots and lots of additional output that will probably mean nothing to you, and just spam your PowerShell window.  It's for what it says on the tin, debugging.

If you really want to look at all the verbose and/or debug output then you probably want to page it:  

    ./ed-played-time.ps1 -verbose -debug *>&1 | Out-Host -Paging

## Producing a Graph

Here's an example of how to turn the resulting CSV file into a graph, using Google Sheets.

1. Login to Google Sheets `https://docs.google.com/spreadsheets`
1. Create a new `Blank` sheet
1. Import the CSV file:  
    1. `File` menu
    1. `Import` menu item
    1. `Upload` menu item
    1. Drag the ed-played-time.csv file in to the dialogue.
    1. On the dialogue that pops up just click `Import data`, the defaults should work.
1. Create a Chart:  
    1. Left-click the 'TimeStamp' cell, A2.
    1. Shift-Left-click the bottom cell in column B.
    1. `Insert` menu
    1. `Chart` menu item  
This will create a default line chart.  You might prefer a Column Chart, in which case:
        1. Click the Chart
        1. Now click the "3 vertical dots" menu handle in the top right of the Chart.
        1. Click `Edit chart` on the popup menu.
        1. In the `Setup` part of the right hand `Chart editor` pane click `Chart type` and select `Column chart`.  

    NB: This will give you a chart with each column being a play session, and you could, of course, have multiple per day, or none for days.  The data/setup would need a little massaging to be strictly per day columns, including any empty days.

## Caveats

I've taken some care to have this time accounting be accurate, but unfortunately some quirks of the events written to the Journal files get in the way.

1. Obviously I can't detect if someone is just sat in a station, space, or supercruise whilst actually idle.
1. There is no reliable way to detect if a player exits out to the Main Menu.  What I've settled on for now is:
    1. detecting the `Commander` event which is the very start of actually logging in to the game proper.
    1. If I was already in "seen start of a session" state (I use the `Location` event for this purpose, so it will trigger later than the `Commander` event for the first login in a session) then use the timestamp of the immediately preceding event as when the player had exited to the Main Menu.
    1. There might be other events that are output whilst in the Main Menu, particularly adding or removing friends and the like.  In that case the accounting won't be correct.
  But, if all you did was exit to the Main Menu, idle there a while, then go back in, the event immediately before the `Commander` event for this fresh login should be the `Music` event that going to the Main Menu triggered.  
*NB: That `Music` event is **not** a `MainMenu` one, as it is when you initially run the game client*.  If it was then I could have just used that.  In my testing it's a `"MusicTrack:"Exploration"` event, and that is also written, at least, when logged in and docked at a space port.
1. Due to the fudge for detecting exiting to the Main Menu the code does not yet detect:
    1. Player logs in, plays for a while or not.
    1. Player exits to main menu and idles there.
    1. Player fully exits the game without logging in to the game proper again.  

    In this case the script will use the timestamp from the last line in the Journal, as the player fully exits the game client, for the end of that session, and thus erroneously account for extra play time.
