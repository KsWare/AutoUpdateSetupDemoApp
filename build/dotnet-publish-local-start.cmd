@echo off
set scriptdir=%~dp0
powershell -ExecutionPolicy Bypass -NoExit -File "%scriptdir%dotnet-publish-local.ps1"
pause