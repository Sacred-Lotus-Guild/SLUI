@echo off
setlocal enabledelayedexpansion

bash release.sh -dz

:: Function to create directory structure in .release
for /f "delims=" %%i in ('dir /b /s /a-d *.lua ^| findstr /v .release') do (
    set "file=%%i"
    set "relpath=!file:%cd%\=!"
    set "targetdir=.release\SLUI\!relpath!"

    :: Get directory part of the target path
    for %%j in ("!targetdir!") do set "targetdir=%%~dpj"

    :: Create directory structure if it doesn't exist
    if not exist "!targetdir!" mkdir "!targetdir!"

    :: Create symbolic link
    set "target=.release\SLUI\!relpath!"
    if exist "!target!" del "!target!"
    mklink "!target!" "!file!"
)
