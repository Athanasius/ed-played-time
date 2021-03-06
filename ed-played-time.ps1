###########################################################################
# PowerShell script to look through current Elite Dangerous 'Journal' files
# and account apparent playtime.
###########################################################################
Param(
	[switch]$verbose = $false,
	[switch]$debug = $false
)
if ($verbose) {
	$VerbosePreference = "Continue"
}
if ($debug) {
	$DebugPreference = "Continue"
}

###########################################################################
# C# code to interpret 'shell:' style paths, pared down to only SavedGames
# <https://stackoverflow.com/a/25094236>
###########################################################################
Add-Type @"
	using System;
	using System.Runtime.InteropServices;

	public static class KnownFolder {
		public static readonly Guid SavedGames = new Guid( "4C5C32FF-BB9D-43b0-B5B4-2D72E54EAAA4" );
	}

	public class shell32 {
		[DllImport("shell32.dll")]
        	private static extern int SHGetKnownFolderPath(
             	[MarshalAs(UnmanagedType.LPStruct)] 
             	Guid rfid,
             	uint dwFlags,
             	IntPtr hToken,
             	out IntPtr pszPath
         	);

         	public static string GetKnownFolderPath(Guid rfid)
         	{
            	IntPtr pszPath;
            	if (SHGetKnownFolderPath(rfid, 0, IntPtr.Zero, out pszPath) != 0)
                	return ""; // add whatever error handling you fancy
            	string path = Marshal.PtrToStringUni(pszPath);
            	Marshal.FreeCoTaskMem(pszPath);
            	return path;
         	}
	}
"@
###########################################################################

###########################################################################
# Record the end of a session
###########################################################################
$end_session = {
	Write-Debug "end_sessions: started = $script:started, ended = $script:ended"
	Write-Verbose "start: $script:start_time"
	Write-Verbose "end: $script:end_time"
	$diff = $script:end_time - $script:start_time
	Write-Verbose "diff: $diff"
	$script:total_playedtime += $diff
	Write-Verbose "total played now: $script:total_playedtime"
	$delta = @{
		TimeStamp = $script:end_time
		Played = $diff
	}
	New-Object PSObject -Property $delta | Write-Output
	$script:started = $script:ended = $false
	$script:expected_part = 1
}
###########################################################################

###########################################################################
# Filter a single session
###########################################################################
$find_sessions = {
	[cmdletbinding()]
	param(
		[parameter(
			Mandatory = $true,
			ValueFromPipeline = $true)
		]
		$e
	)
	if (! $script:started) {
		if ($e.event -eq "Location") {
			Write-Debug "Found Location"
			$script:start_time = [datetime]::Parse($e.timestamp.ToString())
			$script:started = $true
			Write-Debug "find_sessions LOCATION: started = $script:started, ended = $script:ended"
		}
	}
	if ($script:started -and -not $script:ended) {
		#Write-Debug "find_sessions START: started = $script:started, ended = $script:ended"
		if ($e.event -eq "Shutdown") {
			Write-Debug "Found Shutdown"
			$script:end_time = [datetime]::Parse($e.timestamp.ToString())
			$script:ended = $true
			Write-Debug "find_sessions SHUTDOWN: started = $script:started, ended = $script:ended"
		}
		if ($e.event -eq "Commander") {
		# A Commander event seems to be the first written when logging in.
		# The event before it *might* be when we exited to the Main Menu
			Write-Debug "Found Commander event, using last_event"
			$script:end_time = [datetime]::Parse($script:last_event.timestamp.ToString())
			$script:ended = $true
			Write-Debug "find_sessions COMMANDER: started = $script:started, ended = $script:ended"
		}
	}
	if ($script:started -and $script:ended) {
		Write-Debug "find_sessions END: started = $script:started, ended = $script:ended"
		&$end_session
	}
	$script:last_event = $e
	#Write-Debug "find_sessions END: started = $script:started, ended = $script:ended, e = $e"
}
###########################################################################

###########################################################################
# Parse a Journal file for the relevant events
###########################################################################
$parse_journal = {
	[cmdletbinding()]
	param(
		[parameter(
			Mandatory = $true,
			ValueFromPipeline = $true)
		]
		$infile
	)
	Process {
		Write-Host "parse_journal $infile"
		$this_part = [int]$infile.ToString().Split("{.}")[2]
		Write-Debug "parse_journal: This is part $this_part (expected part $script:expected_part)"
		if ($this_part -ne $script:expected_part) {
			Write-Error "parse_journal: Expected part $script:expected_part, found part $this_part"
			exit
		}
		$last_part = $this_part
		foreach ($line in [System.IO.File]::ReadLines("$JournalFolder\$infile")) {
			ConvertFrom-Json -InputObject $line | &$find_sessions
			#Write-Debug "parse_journal: After find_sessions call"
		}
		# End of current file
		if ($script:started -and -not $script:ended) {
			Write-Debug "parse_journal START: started = $script:started, ended = $script:ended, last_line = $line"
			# Are we continuing in a next part?
			$json = ConvertFrom-Json -InputObject $line
			if ($json.event -ne "Continued") {
				Write-Debug "parse_journal: EOF and *not* a Continued"
				$script:end_time = [datetime]::Parse($json.timestamp.ToString())
				&$end_session
			} else {
				Write-Debug "parse_journal: EOF and Continued in part $($json.part.ToString())"
				$script:expected_part = [int]$json.part
			}
		}
	} 
}
###########################################################################

###########################################################################
# MAIN code
###########################################################################
$total_playedtime = 0
$SavedGames = [shell32]::GetKnownFolderPath([KnownFolder]::SavedGames)
$JournalFolder = "$SavedGames\Frontier Developments\Elite Dangerous"
$script:started = $false
$script:start_time = $false
$script:ended = $false
$script:end_time = $false
$script:expected_part = 1
$script:last_event
Get-ChildItem "$JournalFolder" -Filter "Journal.*.*.log" | &$parse_journal | Export-Csv -Path "$JournalFolder\ed-played-time.csv"
Write-Host "total played: $total_playedtime"
###########################################################################
