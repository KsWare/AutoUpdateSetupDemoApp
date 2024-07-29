@echo off
set scriptdir=%~dp0
powershell -ExecutionPolicy Bypass -NoExit -File "%scriptdir%upload-ftp.ps1"
pause