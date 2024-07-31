$env:APPVEYOR_BUILD_FOLDER="D:\Develop\Extern\GitHub.KsWare\AutoUpdateSetupDemoApp"
$env:PROJECT_NAME="AutoUpdateSetupDemoApp"

function error {param ([string]$message)
	Write-Host $message; exit 1
}

# Definiere den Pfad zum zu durchsuchenden Verzeichnis
$vswhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) {error "vswhere.exe not found."}

$devenv = & $vswhere -version 17.0 -products * -requires Microsoft.Component.MSBuild -property installationPath 2>$null
if (-not $devenv) {ShortExit "Visual Studio 2022 not found."}
$devenv = "$($devenv)\Common7\IDE\devenv.exe"
Write-Host "Gefunden: $($devenv)"

# Definiere den Pfad zum Projekt und die Konfiguration
$sln = "$env:APPVEYOR_BUILD_FOLDER\src\$env:PROJECT_NAME.sln"
$csproj = "$env:APPVEYOR_BUILD_FOLDER\src\$env:PROJECT_NAME\$env:PROJECT_NAME.csproj"
$deployPath="$env:APPVEYOR_BUILD_FOLDER\src\$env:PROJECT_NAME\bin\deploy"

Write-Host "csproj: $csproj"

$dotnet = "C:\Program Files\dotnet\dotnet.exe"
& $dotnet publish $csproj --configuration Release -p:PublishProfile=ClickOnceProfile --output $deployPath /p:BootstrapperEnabled=false

