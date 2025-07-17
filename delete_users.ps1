# Delete unloaded user profiles that haven't been used in at least the given number of days (defaults to zero)
#
# Usage:
#	delete_users [-Days #] [-UserName <pattern>] [-DryRun] [-Quiet]

Param(
    $Days = 0,
    [string]$UserName = "*",
    [switch]$DryRun = $false,
    [switch]$Quiet = $false
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

$Profiles = Get-CimInstance -Class Win32_UserProfile -Filter "Loaded = 'False' and Special = 'False'" -ErrorAction Stop

if ($Quiet) {
	$ProgressPreference = "SilentlyContinue"
}

$ErrorActionPreference = "SilentlyContinue"
	
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
			Write-Output "Deleted profile for $Name at $LocalPath unused for $ProfileAge days"
		}
	}
}