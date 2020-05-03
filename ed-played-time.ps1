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
# Parse Journal timestamp
###########################################################################
$parse_timestamp = {
	[cmdletbinding()]
	param(
		[parameter(
			Mandatory = $true,
			ValueFromPipeline = $true)
		]
		$e
	)
	if ($e) {
		Write-Debug "parse_timestamp: e = $e"
		[datetime]::Parse($e.timestamp.ToString())
	}
}
###########################################################################

###########################################################################
# Filter to 'start of session' events
###########################################################################
$filter_start_session = {
	#Write-Debug "filter_start_session: _ = $_"
	if ($_.event -eq "Location") {
		return $true
	}
	return $false
}
###########################################################################

###########################################################################
# Filter to 'end of session' events
###########################################################################
$filter_end_session = {
	#Write-Debug "filter_end_session: _ = $_"
	if ($_.event -eq "Shutdown") {
		Write-Debug "Found Shutdown"
		return $true
	}
	if ($_.event -eq "Music" -and $_.MusicTrack -eq "MainMenu") {
		Write-Debug "Found MainMenu Music"
		return $true
	}
	return $false
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
		$starttime = Get-Content -Path "$JournalFolder\$infile" | ConvertFrom-Json | Where-Object { &$filter_start_session $_ } | &$parse_timestamp
		if ($starttime) {
			Write-Verbose "start: $starttime"
			Write-Debug "Looking for endtime..."
			$endtime = Get-Content -Path "$JournalFolder\$infile" | ConvertFrom-Json | Where-Object {&$filter_end_session} | Select-Object -First 1 | &$parse_timestamp
			Write-Verbose "end: $endtime"
			$diff = $endtime - $starttime
			Write-Verbose "diff: $diff"
			$total_playedtime += $diff
			Write-Verbose "total played now: $total_playedtime"
			$delta = @{
				TimeStamp = $endtime
				Played = $diff
			}
			New-Object PSObject -Property $delta | Write-Output
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
