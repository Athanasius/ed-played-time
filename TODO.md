# TODO

## Intended Evolution

1. ~~Iterate through all found Journal files using the First and Last line timestamps as time deltas to add to a running total.~~ **DONE**
1. ~~Rather than using the First line of each file, look for a "Location" event.~~ **DONE**
1. ~~Rather than blindly using the Last line of a file, look for "Shutdown" events.  NB: There may be others, as in returning to the main menu, in which case we'd then need to look for a new "Location" event again.~~ **DONE**
1. ~~Handle the (rare?) case of a session's Journal file filling and spilling over into a `01` or greater version.  This will also entail some state to handle a session spanning files, remembering there might not be a Shutdown/MainMenu event, so finding a Location event soon in the next file means "use the last event in the previous file as this time delta's end".~~ **DONE**


### Action Items
1. ~~Output the found data to a CSV file (in the Journals location).~~ **DONE**
1. ~~Use "Location" event as the start time.~~ **DONE**
1. ~~Use "Shutdown", "Music" ("MusicTrack":"MainMenu") to detect end of session.~~ **DONE**
1. ~~If we reach end of file, treat that as end of a session if we didn't yet see one.~~ **DONE**
1. ~~If we find a 'logout' event, start looking for a new 'login' event.~~ **DONE**
1. ~~If we reach the end of a `NN` Journal check if the next is `NN+1` for the same Journal file name timestamp.~~
    1. ~~This will need some state machine.  If the new file finds a new 'login' event before a 'logout' one then we need to decide what the end of the prior session was.  At the least we need to store the 'last line' timestamp from the prior file.~~ **DONE**
1. Try to figure out how to have Google Sheets aggregate the data per day, and include any 'empty' days in the chart.
