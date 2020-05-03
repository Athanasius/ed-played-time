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
			Write-Debug "find_sessions START: started = $script:started, ended = $script:ended"
		}
	}
	if ($script:started -and -not $script:ended) {
		Write-Debug "find_sessions START: started = $script:started, ended = $script:ended"
		if ($e.event -eq "Shutdown") {
			Write-Debug "Found Shutdown"
			$script:end_time = [datetime]::Parse($e.timestamp.ToString())
			$script:ended = $true
			Write-Debug "find_sessions START: started = $script:started, ended = $script:ended"
		}
		if ($e.event -eq "Music" -and $_.MusicTrack -eq "MainMenu") {
			Write-Debug "Found MainMenu Music"
			$script:end_time = [datetime]::Parse($e.timestamp.ToString())
			$script:ended = $true
			Write-Debug "find_sessions START: started = $script:started, ended = $script:ended"
		}
	}
	if ($script:started -and $script:ended) {
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
	}
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
		Write-Verbose "parse_journal $infile"
		$script:started = $false
		$script:start_time = $false
		$script:ended = $false
		$script:end_time = $false
		foreach ($line in [System.IO.File]::ReadLines("$JournalFolder\$infile")) {
			ConvertFrom-Json -InputObject $line | &$find_sessions
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
Get-ChildItem "$JournalFolder" -Filter "Journal.*.*.log" | &$parse_journal | Export-Csv -Path "$JournalFolder\ed-played-time.csv"
Write-Host "total played: $total_playedtime"
###########################################################################
