::@echo off
setlocal

:: Pfad zu MSBuild (Hier musst du den tatsÑchlichen Pfad zu MSBuild.exe auf dem Build-Server anpassen)
set MSBUILD_PATH="C:\Program Files\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"

:: Projektdateipfad relativ zum Speicherort der Batch-Datei
set "PROJECT_PATH=%~dp0..\src\AutoUpdateSetupDemoApp\AutoUpdateSetupDemoApp.csproj"

:: Verîffentlichungsordner relativ zum Speicherort der Batch-Datei
set "PUBLISH_PATH=%~dp0..\src\AutoUpdateSetupDemoApp\bin\publish"

:: FÅhre MSBuild aus, um ClickOnce zu verîffentlichen
echo Verîffentliche Anwendung mit ClickOnce...
%MSBUILD_PATH% "%PROJECT_PATH%" /p:Configuration=Release /p:DeployOnBuild=True /p:PublishProfile=ClickOnceProfile

:: öberprÅfe, ob die Verîffentlichung erfolgreich war
if exist "%PUBLISH_PATH%" (
    echo Verîffentlichung erfolgreich
) else (
    echo Verîffentlichung fehlgeschlagen
    exit /b 1
)

endlocal