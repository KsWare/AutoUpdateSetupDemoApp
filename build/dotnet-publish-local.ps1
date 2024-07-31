$env:APPVEYOR_BUILD_FOLDER="D:\Develop\Extern\GitHub.KsWare\AutoUpdateSetupDemoApp"
$env:PROJECT_NAME="AutoUpdateSetupDemoApp"
$publishProfile = "ClickOnceProfile"

# Versuche, MSBuild.exe zu finden
$possiblePaths = @(
    "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
)
$msbuildPath = $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $msbuildPath) {Write-Error "MSBuild not found."; exit 1}
Write-Output "Gefundener MSBuild-Pfad: $msbuildPath"
$msbuild = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $msbuild = $path
        break
    }
}
if (-not $msbuild) {
    Write-Error "MSBuild.exe not found"
    exit 1
}
Write-Output "Gefunden: $msbuildPath"

# Setze die Pfade zur Projektdatei und zum Publish-Profil
$projectPath = "$env:APPVEYOR_BUILD_FOLDER\src\$env:PROJECT_NAME"
$project ="$projectPath\$env:PROJECT_NAME.csproj"

& $msbuild $project /t:publish /p:PublishProfile=ClickOnceProfile /p:ApplicationRevision=10 /p:ApplicationVersion=0.1.0.*
# BUG bin\publish (PublishUrl) is always empty

$pubxmlFile = "$env:APPVEYOR_BUILD_FOLDER\src\$env:PROJECT_NAME\Properties\PublishProfiles\$publishProfile.pubxml"
[xml]$pubxml = Get-Content $pubxmlFile
$publishUrl = "$projectPath\$($pubxml.Project.PropertyGroup.PublishUrl.TrimEnd('\'))"	# bin\Publish
$publishDir = "$projectPath\$($pubxml.Project.PropertyGroup.PublishDir.TrimEnd('\'))"   # bin\Release\net8.0-windows\app.publish\

if (-not (Test-Path -Path $publishUrl)) { New-Item -ItemType Directory -Path $publishUrl }
Copy-Item -Path "$publishDir\Application Files" -Destination $publishUrl -Recurse -Force
Copy-Item -Path "$publishDir\setup.exe" -Destination $publishUrl -Force
Copy-Item -Path "$publishDir\$env:PROJECT_NAME.application" -Destination $publishUrl -Force

# Überprüfe, ob die Veröffentlichung erfolgreich war
if (Test-Path $publishUrl) {
    Write-Output "Veröffentlichung erfolgreich"
    Get-ChildItem -Path $publishUrl
} else {
    Write-Error "Veröffentlichung fehlgeschlagen"
    exit 1
}