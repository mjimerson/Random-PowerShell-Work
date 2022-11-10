function findOldADComputers () {
	$aOldComputers = @();
	$aAllAdComputers = Get-ADComputer -Filter * -Properties LastLogonDate,PasswordLastSet | Where { $_.Enabled -eq $true };
	foreach ($oAdComputer in $aAllAdComputers) {
		if ($oAdComputer.lastLogonDate -ne $null) {
			if ($oAdComputer.lastLogonDate -lt [DateTime]::Now.Subtract([TimeSpan]::FromDays(45))) {
				if ($oAdComputer.PasswordLastSet -lt [DateTime]::Now.Subtract([TimeSpan]::FromDays(45))) {
					$aOldComputers += $oAdComputer.Name;
				}
			}
		}
	}
	return $aOldComputers;
}

$sOldPcFilePath 	= 'C:\temp\ad_cleanup\Get-Old-Ad-Accounts-Files\old_computer_accounts.txt';
$sOnlinePcFilePath 	= 'C:\temp\ad_cleanup\Get-Old-Ad-Accounts-Files\online_pcs.txt';

if (Test-Path $sOnlinePcFilePath) {
	$aPastOnlinePcs = Get-Content $sOnlinePcFilePath;
} else {
	$aPastOnlinePcs = @();
}

if (Test-Path $sOldPcFilePath) {
	Remove-Item $sOldPcFilePath -Force
}

$aCurrentOldPcs = findOldAdComputers;

$aDnsQueryResults = Get-DnsARecord $aCurrentOldPcs;
foreach ($i in $aDnsQueryResults) {
	$sPc = $i[0];
	$bResult = $i[1];
	if ($bResult) { ## The PC has a DNS record
		if (!(Test-Ping $sPc)) { ## The PC is offline
			if ($aPastOnlinePcs -notcontains $sPc) { ## The PC has never been shown to be online
				Write-Debug "$sPc has a DNS record but is offline";
				Add-Content $sOldPcFilePath $sPc;
			}
		} else {
			Write-Debug "$sPc has a DNS record and is online";
			if ($aPastOnlinePcs -notcontains $sPc) {
				Add-Content $sOnlinePcFilePath $sPc;
			}
		}
	} else {
		Write-Debug "$sPc has no DNS record"
		Add-Content $sOldPcFilePath $sPc;
	}
}