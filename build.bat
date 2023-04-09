@echo off
setlocal enableextensions

powershell -ExecutionPolicy RemoteSigned -File PKGBUILD.ps1

echo finish
pause
