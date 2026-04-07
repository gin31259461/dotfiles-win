@echo off
chcp 65001 >nul
cls
SETLOCAL

cd /d "%~dp0"

powershell -File install.ps1

pause
