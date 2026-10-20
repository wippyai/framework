@echo off
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0make.ps1" %*
exit /b %errorlevel%
