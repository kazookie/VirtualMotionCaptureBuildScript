@echo off
setlocal enableextensions

powershell -ExecutionPolicy Bypass -File PKGBUILD.ps1

echo finish
pause
