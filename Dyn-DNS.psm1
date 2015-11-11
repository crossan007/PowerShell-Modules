#All DynRest API visible here: https://help.dyn.com/rest-resources/
#region API - Get
Function Get-DYNLoginToken
{
Param
(
[Parameter(Mandatory=$True,Position=1)]
	[String]$CustomerName,
[Parameter(Mandatory=$True,Position=2)]
	[String]$UserName,
[Parameter(Mandatory=$True,Position=3)]
	[String]$Password
)
<#
.SYNOPSIS
Before issuing any commands to the DynAPI, a session token must be obtained.
All commands issued to the API must include this session token.
The Token will expire after a timeout, but it is recommended to destroy it when finished

.EXAMPLE
$token = Get-DYNLoginToken -CustomerName "customername" -UserName "username" -Password "password"

#>
	$data = @{
		customer_name = $CustomerName
		user_name = $UserName
		password = $Password
	}
	$body = $data | ConvertTo-JSON
	$response = Invoke-RestMethod -URI "https://api.dynect.net/REST/Session" -Method post -Body $body -ContentType 'application/json'
	$response.data.token
}

Function Get-AllZones
{
Param(
[Parameter(Mandatory=$True,Position=1)]
	[String]$Token
)
<#
.SYNOPSIS
Get a list of all of the zones that the currently logged in user (as defined by the login token) has access to.  Return a PSObject for each zone with two properties: ZoneName (Just the domain name), and ZoneURL (The API REST URL)

.EXAMPLE 
Get-AllZones -Token $token
#>

	$response = Invoke-RestMethod -Uri "https://api.dynect.net/REST/Zone/" -Method Get -ContentType "application/json" -Headers @{"Auth-Token"="$token"}
	foreach ($z in $response.data)
	{
		$ZoneObject = New-Object -TypeName PSObject
		Add-Member -InputObject $ZoneObject -MemberType NoteProperty -Name "ZoneName" -Value $($z -split '/')[3]
		Add-Member -InputObject $ZoneObject -MemberType NoteProperty -Name "ZoneURL" -Value $z
		$ZoneObject
	}
}

Function Get-AllZoneRecords
{
Param(
[Parameter(Mandatory=$True,Position=1)]
	[String]$ZoneName,
[Parameter(Mandatory=$True,Position=2)]
	[String]$Token
)
<#
.SYNOPSIS 
Get all the records for a single zone.
Returns a PSObject for each record with 4 properties: ZoneName, RecordName, RecordID, and RecordURL
.EXAMPLE
Get-AllZones -Token $token | %{ Get-AllZoneRecords -ZoneName $_.ZoneName -Token $Token}
#>
	$response = Invoke-RestMethod -Uri "https://api.dynect.net/REST/AllRecord/$($ZoneName)" -Method Get -ContentType "application/json" -Headers @{"Auth-Token"="$Token"}
	Foreach($record in $response.data)
	{
		$RecordObject = New-Object -TypeName PSObject
		Add-Member -InputObject $RecordObject -MemberType NoteProperty -Name "ZoneName" -Value $($record -split '/')[3]
		Add-Member -InputObject $RecordObject -MemberType NoteProperty -Name "RecordName" -Value $($record -split '/')[4]
		Add-Member -InputObject $RecordObject -MemberType NoteProperty -Name "RecordID" -Value $($record -split '/')[5]
		Add-Member -InputObject $RecordObject -MemberType NoteProperty -Name "RecordURL" -Value $record
		$RecordObject
	
	}

}

Function Get-RecordDetails{
param(
[Parameter(Mandatory=$True,Position=1)]
	[String]$RecordURL,
[Parameter(Mandatory=$True,Position=2)]
	[String]$token)
<#
.SYNOPSIS
Get the details for an individual record.  Requires the authentication token, and the RecordURL as given by Get-AllZoneRecords.  Returns 
.EXAMPLE
$allZoneRecords=Get-AllZones -Token $token | %{ Get-AllZoneRecords -ZoneName $_.ZoneName -Token $Token}
Get-RecordDetails -token $token -RecordURL $($allZoneRecords[3].RecordURL)
#>
Write-Host -ForegroundColor Green "Getting Record Details for: $RecordURL"
$response = Invoke-RestMethod -Uri "https://api.dynect.net$($RecordURL)" -Method Get -ContentType "application/json" -Headers @{"Auth-Token"="$Token"}
Foreach($record in $response.data)
	{
		$RecordDetailObject = New-Object -TypeName PSObject
		Add-Member -InputObject $RecordDetailObject -MemberType NoteProperty -Name "FQDN" -Value $($record.fqdn)
		Add-Member -InputObject $RecordDetailObject -MemberType NoteProperty -Name "TTL" -Value $($record.ttl)
		Add-Member -InputObject $RecordDetailObject -MemberType NoteProperty -Name "Zone" -Value $($record.zone)
		Add-Member -InputObject $RecordDetailObject -MemberType NoteProperty -Name "Type" -Value $($record.record_type)
		Add-Member -InputObject $RecordDetailObject -MemberType NoteProperty -Name "Data" -Value $($record.rdata)
		Add-Member -InputObject $RecordDetailObject -MemberType NoteProperty -Name "RecordId" -Value $($record.record_id)
		Add-Member -InputObject $RecordDetailObject -MemberType NoteProperty -Name "Raw" -Value $record
		$RecordDetailObject
	
	}
}

Function Get-UnpublishedZoneChanges{
param(
[Parameter(Mandatory=$True,Position=1)]
	[String]$ZoneName,
[Parameter(Mandatory=$True,Position=2)]
	[String]$token
)
<#
.SYNOPSIS
Get a list of all of the unpublished changes to the selected zone.
.EXAMPLE
 Get-UnpublishedZoneChanges -ZoneName "zoneName.net" -token $token | get-member
#>

	$response = Invoke-RestMethod -Uri "https://api.dynect.net/REST/ZoneChanges/$ZoneName" -Method GET -ContentType "application/json" -Headers @{"Auth-Token"="$Token"}
	if ($response.data)
	{
		Foreach($record in $response.data)
		{
			
			$Record
		
		}
	}
	else
	{
		$false

	}

}

Function Delete-UnpublishedZoneChanges{
param(
[Parameter(Mandatory=$True,Position=1)]
	[String]$ZoneName,
[Parameter(Mandatory=$True,Position=2)]
	[String]$token
)
<#
.SYNOPSIS
Get a list of all of the unpublished changes to the selected zone.
.EXAMPLE
 Get-UnpublishedZoneChanges -ZoneName "zoneName.net" -token $token | get-member
#>

	$response = Invoke-RestMethod -Uri "https://api.dynect.net/REST/ZoneChanges/$ZoneName" -Method DELETE -ContentType "application/json" -Headers @{"Auth-Token"="$Token"}
	$Response

}


#endregion

#region API - Set
Function Set-RecordTTL
{
param(
[Parameter(Mandatory=$True,Position=1)]
	[String]$RecordURL,
[Parameter(Mandatory=$True,Position=2)]
	[Int]$ttl,
[Parameter(Mandatory=$True,Position=3)]
	[String]$token
)
<#
.EXAMPLE
$ZoneRecords = Get-AllZones -Token $token | %{ Get-AllZoneRecords -ZoneName $_.ZoneName -Token $Token}
$ZoneRecords | %{ Set-RecordTTL -RecordURL $_.RecordURL -ttl 14400 -token $token}
#>
	$data = @{
		ttl = $ttl
	}
	$body = $data | ConvertTo-JSON
	$response = Invoke-RestMethod -Uri "https://api.dynect.net$($RecordURL)" -Method Put -ContentType "application/json" -Headers @{"Auth-Token"="$Token"} -Body $body
	$response

}

#endregion

#region API - Delete
Function Remove-LoginSession
{
Param(
$token)
	
	$response = Invoke-RestMethod -URI "https://api.dynect.net/REST/Session" -Method DELETE -Body $body -ContentType 'application/json' -Headers @{"Auth-Token"="$Token"}
	$response
}

#endregion

#region API - Action
Function Confirm-PublishZone{
	$title = "Confirm Zone Publish"
	$message = "Are you sure you want to publish the zone?"
	$Discard = New-Object System.Management.Automation.Host.ChoiceDescription "&Discard", "Discards all changes to the zone"
	$Publish = New-Object System.Management.Automation.Host.ChoiceDescription "&Publish", "Publishes the zone"
	$Cancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel", "Cancels publishing, but does not discard pending changes"
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($Discard, $Publish, $Cancel)
	$result = $host.ui.PromptForChoice($title, $message, $options, 2) 
	$result
}
Function Publish-Zone{
Param(
$ZoneName,
$Token
)

	
	$Changes = Get-UnpublishedZoneChanges -ZoneName $ZoneName -Token $Token
	if ($Changes)
	{
		$Changes | ft fqdn,ttl,serial
		switch (Confirm-PublishZone)
		{
			0 
			{
				#Discard
				Delete-UnpublishedZoneChanges -ZoneName $ZoneName -Token $Token
			}
			1 
			{
				#Publish	
				$data = @{
					publish = $true
				}
				$body = $data | ConvertTo-JSON
				$response = Invoke-RestMethod -Uri "https://api.dynect.net/REST/Zone/$ZoneName" -Method PUT -ContentType "application/json" -Headers @{"Auth-Token"="$Token"} -body $body
				$Response
			}
			2 
			{
				#Cancel
				Write-Host "Cancelling publishing.  Your record changes are still pending"
			}
		}
	
		
	}
	else
	{
	Write-Host "There are no pending changes for this zone.  Unable to publish!"
	}
	



}
#endregion

#region Logic - Actions

Function Display-RecordTTL
{
param(
$recordDetails
)
if ($recordDetails.ttl -lt 3600)
		{
			write-host -ForegroundColor Red "$($recordDetails.fqdn) TTL is $($recordDetails.ttl)"
		}
		elseif($recordDetails.ttl -lt 7200)
		{
			write-host -ForegroundColor Yellow "$($recordDetails.fqdn) TTL is $($recordDetails.ttl)"
		}
		else
		{
			write-host -ForegroundColor Green "$($recordDetails.fqdn) TTL is $($recordDetails.ttl)"
		}


}

Function GetDynZoneRecordDetails
{
Param(
$ZoneName,
$Token
)
	<#
	.EXAMPLE
	Get-DYNZoneRecordDetails -ZoneName "zoneName.org" -Token $token
	#>
	write-host "Getting Records for: $ZoneName"
	#Get a list of the records in the zone
	$Records = Get-DynRecords -ZoneName $ZoneName -Token $Token
	#process all the records
	foreach ($record in $records)
	{
		$recordDetails = Get-DYNRecordDetails -RecordReference $record -Token $Token
		Display-DynRecordTTL -RecordDetails $recordDetails
    }
 
	
}

Function Display-DynTTLReport
{
param(
$token
)
	$zones = Get-AllZones -token $token

	foreach ($z in $zones)
	{
		if($z.ZoneName -match '^[0-9]')
		{
			write-host "Ignoring $($z.ZoneName)"
		}
		else
		{
			Get-RecordDetails -ZoneName $z -Token $Token
		}
	}
}


Function Update-TTLDefaultRecordsInZone
{
Param(
$ZoneName,
$DefaultTTL,
$NewTTL,
$Token)
<#
.EXAMPLE
Update-TTLDefaultRecordsInZone -ZoneName "zoneName.net" -DefaultTTL 28800 -NewTTL 21600 -Token $token
Publish-Zone -ZoneName "zoneName.net" -Token $token
#>
	$ZoneRecords = Get-AllZoneRecords -ZoneName $ZoneName -Token $token
	Foreach ($ZoneRecord in $ZoneRecords)
	{ 
		if ($(Get-RecordDetails -RecordURL $ZoneRecord.RecordURL -Token $Token).ttl -eq $DefaultTTL)
		{
			Write-Host "Updating $($ZoneRecord.RecordName) because it is set to the default ttl"
			Set-RecordTTL -RecordURL $ZoneRecord.RecordURL -ttl $NewTTL -token $token
		}
		else
		{
			Write-Host "Not updating $($ZoneRecord.RecordName) because it is not set to the default ttl"
		}
	}
}
#endregion