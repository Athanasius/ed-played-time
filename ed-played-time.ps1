###########################################################################
# PowerShell script to look through current Elite Dangerous 'Journal' files
# and account apparent playtime.
###########################################################################

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
		$ts
	)
	[datetime]::Parse($ts.timestamp.ToString())
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
		$starttime = Get-Content -Path "$JournalFolder\$infile" -TotalCount 1 | ConvertFrom-Json | Select-Object -Property timestamp | &$parse_timestamp
		$endtime = Get-Content -Path "$JournalFolder\$infile" -Tail 1 | ConvertFrom-Json | Select-Object -Property timestamp | &$parse_timestamp
		Write-Host "start: $starttime"
		Write-Host "end: $endtime"
		$diff = $endtime - $starttime
		Write-Host "diff: $diff"
		$total_playedtime += $diff
		Write-Host "total played now: $total_playedtime"
	}
}
###########################################################################

###########################################################################
# MAIN code
###########################################################################
$total_playedtime = 0
$SavedGames = [shell32]::GetKnownFolderPath([KnownFolder]::SavedGames)
$JournalFolder = "$SavedGames\Frontier Developments\Elite Dangerous"
Get-ChildItem "$JournalFolder" -Filter "Journal.*.*.log" | &$parse_journal
###########################################################################
