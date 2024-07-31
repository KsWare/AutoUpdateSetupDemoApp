::@echo off
setlocal

:: Pfad zu MSBuild (Hier musst du den tats�chlichen Pfad zu MSBuild.exe auf dem Build-Server anpassen)
set MSBUILD_PATH="C:\Program Files\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"

:: Projektdateipfad relativ zum Speicherort der Batch-Datei
set "PROJECT_PATH=%~dp0..\src\AutoUpdateSetupDemoApp\AutoUpdateSetupDemoApp.csproj"

:: Ver�ffentlichungsordner relativ zum Speicherort der Batch-Datei
set "PUBLISH_PATH=%~dp0..\src\AutoUpdateSetupDemoApp\bin\publish"

:: F�hre MSBuild aus, um ClickOnce zu ver�ffentlichen
echo Ver�ffentliche Anwendung mit ClickOnce...
%MSBUILD_PATH% "%PROJECT_PATH%" /p:Configuration=Release /p:DeployOnBuild=True /p:PublishProfile=ClickOnceProfile

:: �berpr�fe, ob die Ver�ffentlichung erfolgreich war
if exist "%PUBLISH_PATH%" (
    echo Ver�ffentlichung erfolgreich
) else (
    echo Ver�ffentlichung fehlgeschlagen
    exit /b 1
)

endlocal