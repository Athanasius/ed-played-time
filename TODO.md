# TODO

## Intended Evolution

1. ~~Iterate through all found Journal files using the First and Last line timestamps as time deltas to add to a running total.~~ **DONE**
1. Rather than using the First line of each file, look for a "Location" event.
1. Rather than blindly using the Last line of a file, look for "Shutdown" events.  NB: There may be others, as in returning to the main menu, in which case we'd then need to look for a new "Location" event again.
1. Handle the (rare?) case of a session's Journal file filling and spilling over into a `01` or greater version.  This will also entail some state to handle a session spanning files, remembering there might not be a Shutdown/MainMenu event, so finding a Location event soon in the next file means "use the last event in the previous file as this time delta's end".

