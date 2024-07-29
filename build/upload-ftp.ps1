# Absoluten Pfad des aktuellen Skripts ermitteln
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
# Pfad zur login-data.ps1 im .secrets-Verzeichnis
$loginDataPath = $loginDataPath = Join-Path $scriptDir "..\..\.secrets\ftp-ksware.de-software.login-data.ps1"
# Überprüfen und Importieren der login-data.ps1, falls vorhanden

if (Test-Path -Path $loginDataPath) {
    . $loginDataPath
}

if (-not $username -or -not $password) {
    Write-Host "Fehler: Anmeldedaten sind nicht gesetzt."
    exit 1
}

# FTP-Server-Details
$ftpServer = "ftp://ksware.kasserver.com/AutoUpdateSetupDemoApp"

# Verzeichnis mit den ClickOnce-Dateien
$localPath = "..\src\AutoUpdateSetupDemoApp\bin\publish"
$localPath = (Resolve-Path -Path (Join-Path -Path $scriptDir -ChildPath $localPath)).ToString()

# Funktion zum Hochladen von Dateien
function Upload-ToFtp {
    param (
        [string]$localFilePath,
        [string]$ftpFilePath
    )
	 Write-Host "Upload: $localFilePath"
	 Write-Host "     -> $ftpFilePath"

    $webclient = New-Object System.Net.WebClient
    $webclient.Credentials = New-Object System.Net.NetworkCredential($username, $password)

    $uri = New-Object System.Uri($ftpFilePath)
    try {
        $webclient.UploadFile($uri, $localFilePath)
       	Write-Host "        OK"
    } catch {
        Write-Host "$_"
    }
}

# Funktion zum Erstellen von Verzeichnissen auf dem FTP-Server
function Create-FtpDirectory {
    param (
        [string]$ftpDir
    )
	Write-Host "MkDir:  $ftpDir"
	
    $ftpRequest = [System.Net.FtpWebRequest]::Create($ftpDir)
    $ftpRequest.Credentials = New-Object System.Net.NetworkCredential($username, $password)
    $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
    try {
        $ftpResponse = $ftpRequest.GetResponse()
        $ftpResponse.Close()        
		Write-Host "        OK"
    } catch [System.Net.WebException] {
        if ($_.Exception.Response.StatusCode -eq 550) {
            Write-Host "        ERROR: 550 Verzeichnis existiert möglicherweise bereits"
        } else {
            Write-Host "        ERROR: S($_.Exception.Response.StatusCode)"
        }
    }
}

# Rekursiv durch Verzeichnisse gehen und Dateien hochladen
function Upload-Files {
    param (
        [string]$currentPath,
        [string]$currentFtpPath
    )

    Get-ChildItem -Path $currentPath -Recurse | ForEach-Object {
		$fullname = $_.FullName
		$relativePath = $fullName.Substring($localPath.Length + 1).Replace("\", "/")
		$ftpPath = "$currentFtpPath/$relativePath"
        if ($_.PSIsContainer) {            
            Create-FtpDirectory -ftpDir $ftpPath
        } else {            
            Upload-ToFtp -localFilePath $_.FullName -ftpFilePath $ftpPath
        }
    }
}

# Hochladen der Dateien starten
Upload-Files -currentPath $localPath -currentFtpPath $ftpServer

# http://ksware.de/software/AutoUpdateSetupDemoApp/AutoUpdateSetupDemoApp.application