# Delete unloaded user profiles that haven't been used in at least the given number of days (defaults to zero)
#
# Usage:
#	DeleteUsers [-Days #] [-UserName <pattern>] [-DryRun] [-Quiet] [-Log]

Param(
    $Days = 0,
    [string]$UserName = "*",
    [switch]$DryRun = $false,
    [switch]$Quiet = $false,
	[switch]$Log = $false
)

Function TranslateSidToName {
    param(
        [string]$sid
    )

    try {
        $osid = New-Object System.Security.Principal.SecurityIdentifier($sid)
        $osid.Translate([System.Security.Principal.NTAccount])
    } catch {
        "<Unresolved>"
    }
}

Function ConvertToDate {
    param(
        [uint32]$lowpart,
		[uint32]$highpart
    )

    $ft64 = ([UInt64]$highpart -shl 32) -bor $lowpart
    [datetime]::FromFileTime($ft64)
}

Function GetDaysSinceDate {
    param(
        [datetime]$date
    )

    ((Get-Date) - $date).days
}

if ($Log) {			
	$Transcript = ".\logs\$(hostname)-$(Get-Date -F 'yyyyMMddHHmmss').log"
	Start-Transcript | Out-Null
}

if ($Quiet) {
	$ProgressPreference = "SilentlyContinue"
} else {
	Write-Host "Machine Name........: $(hostname)"
	Write-Host "Current Date........: $((Get-Date).ToString())"
	Write-Host "Run By..............: $($env:USERDOMAIN)\$($env:USERNAME)"
}

$ErrorActionPreference = "SilentlyContinue"

$Profiles = Get-CimInstance -Class Win32_UserProfile -Filter "Loaded = 'False' and Special = 'False'" -ErrorAction Stop

foreach ($Profile in $Profiles) {
	$Sid = $Profile.sid
	$Name = TranslateSidToName $Sid
	$LocalPath = $Profile.LocalPath
	$profileListsIdKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$Sid"
	$LocalProfileUnloadTimeLow = Get-ItemPropertyValue -Path $profilelistsidkey -Name LocalProfileUnloadTimeLow
	$LocalProfileUnloadTimeHigh = Get-ItemPropertyValue -Path $profilelistsidkey -Name LocalProfileUnloadTimeHigh
	$LastUseTime = ConvertToDate $LocalProfileUnloadTimeLow $LocalProfileUnloadTimeHigh
	$ProfileAge = if ($LastUseTime) {GetDaysSinceDate $LastUseTime} else {GetDaysSinceDate $Profile.LastUseTime}
	
	Write-Progress -Activity 'Removing Profiles' -Status "Checking $Name" -Id 0
	 
	if (($ProfileAge -ge $Days) -and ($Name -like $UserName)) {
		
		Write-Progress -Id 1 -ParentId 0 "Deleting $Name"
		
		if (-not $DryRun) {
			Remove-CimInstance -InputObject $Profile
		}
		
		if (-not $Quiet) {
			Write-Host "Deleted profile for $Name at $LocalPath unused for $ProfileAge days"
		}
	}
}