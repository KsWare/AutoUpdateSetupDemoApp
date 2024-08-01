function Update-Version {
	$isPR = $env:isPR
	
	# Init AppVeyor API request 
	$apiUrl = 'https://ci.appveyor.com/api'
	$appveyorApiRequestHeaders = @{
		"Authorization" = "Bearer $env:AppVeyorApiToken"
		"Content-type" = "application/json"
		"Accept" = "application/json"
	}	

	# Read Settings
    if($isPR -eq $false) {
        $response = Invoke-RestMethod -Method Get -Uri "$apiUrl/projects/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG/settings" -Headers $appveyorApiRequestHeaders
        $settings = $response.settings        
    } else {
        # dummy settings
        $settings = @{versionFormat = $env:APPVEYOR_BUILD_VERSION}        
    }
	
    # Extract version format
    $currentVersionSegments = $env:APPVEYOR_BUILD_VERSION.Split(".")
    $major = $currentVersionSegments[0]
    $minor = $currentVersionSegments[1]
    $patch = $currentVersionSegments[2]
    $buildVersion = "$major.$minor.$patch"
    $buildNumber = $env:APPVEYOR_BUILD_NUMBER  
    if($isPR -eq $false) {
    	$versionFormat = $settings.versionFormat	
    	Write-Output "versionFormat: $versionFormat"	
    	if(-not ($versionFormat -match "^(\d+\.\d+\.\d+)\..+$")) {
    	    Write-Error -Message "`nERROR: Unsupported version format!" -ErrorAction Stop
    	    Exit-AppveyorBuild
    	}
    	$currentVersion = $Matches[1]	
    	$currentVersionSegments = $currentVersion.Split(".")	
    	Write-Output "Current version: $currentVersion.* / $($currentVersionSegments.Count+1) parts"
    }

    # Get new version from file
    if($isPR -eq $true -or -not (Test-Path $ENV:VersionFile)) { return }
    
    Write-Output "Read new version from file"
    $versionPattern = "^(\s*\##?\s*v?)(?<version>\d+\.\d+\.\d+)"
    $fileContent = Get-Content -path "$env:VersionFile" -TotalCount 5
    foreach ($line in $fileContent) {
        if ($line -match $versionPattern) {
            $newVersion = $matches['version']
            break
        }
    }    	
    if(-not ($newVersion)) {
        Write-Error -Message "`nERROR: No valid version found!" -ErrorAction Stop
        Exit-AppveyorBuild
    }	
    $newVersionSegments = $newVersion.Split(".")	
    Write-Output "New version: ""$newVersion.*"" / $($newVersionSegments.Count+1) parts"	
    if($newVersionSegments.Count+1 -ne 4) {
        $env:APPVEYOR_SKIP_FINALIZE_ON_EXIT="true"
        Write-Error -Message "`nERROR: Unsupported version format!" -ErrorAction Stop
        Exit-AppveyorBuild
    }	
    $buildVersion = $newVersion	    

    # Check if new version is greater  
    $reset_build = $false
    if(($isPR -eq $true) -or -not ($newVersion)) { return }
    
    if ($newVersionSegments[0] -gt $currentVersionSegments[0]) {
        $reset_build = $true
        $buildNumber = 0
    } elseif (($newVersionSegments[0] -eq $currentVersionSegments[0]) -and ($newVersionSegments[1] -gt $currentVersionSegments[1])) {
        $reset_build = $true
        $buildNumber = 0
    }elseif (($newVersionSegments[0] -eq $currentVersionSegments[0]) -and ($newVersionSegments[1] -eq $currentVersionSegments[1]) -and ($newVersionSegments[2] -gt $currentVersionSegments[2])) {
        $reset_build = $true
        $buildNumber = 0
    }
    Write-Output "Reset build number: $reset_build"    

    # Conditional update settings
    if(($reset_build -eq $true) -and ($isPR -eq $false)) {
        $b=$versionFormat -match "^(\d+\.\d+\.\d+)\.(.*)$"
        $settings.versionFormat = "$buildVersion.$($Matches[2])"
        Write-Output "Build version format: $($settings.versionFormat)"
        $body = ConvertTo-Json -Depth 10 -InputObject $settings
        $response = Invoke-RestMethod -Method Put -Uri "$apiUrl/projects" -Headers $appveyorApiRequestHeaders -Body $body
    }

    # Conditional Send nextBuildNumber = 1
    if(($reset_build -eq $true) -and ($isPR -eq $false)) {
        $build = @{ nextBuildNumber = 1 }
        $json = $build | ConvertTo-Json    
        Write-Output "Invoke 'Reset Build Nummer'"
        Invoke-RestMethod -Method Put "$apiUrl/projects/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG/settings/build-number" -Body $json -Headers $appveyorApiRequestHeaders
    }

    # set current build version
    if($isPR -eq $false) {
        Update-AppveyorBuild -Version "$buildVersion.$buildNumber$versionSuffix$meta"
    }

    Write-Output "APPVEYOR_BUILD_VERSION: $env:APPVEYOR_BUILD_VERSION"
	
	[System.Environment]::SetEnvironmentVariable('buildVersion', $buildVersion, [System.EnvironmentVariableTarget]::User)
	[System.Environment]::SetEnvironmentVariable('buildNumber', $buildNumber, [System.EnvironmentVariableTarget]::User)
}

#Export-ModuleMember -Function Update-Version
Update-Version