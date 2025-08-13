:: WORK IN PROGRESS
@echo off
setlocal enabledelayedexpansion

:: Create .release directory if it doesn't exist
if not exist ".release" mkdir ".release"
if not exist ".release\SLUI" mkdir ".release\SLUI"

:: Function to create directory structure in .release
for /f "delims=" %%i in ('dir /b /s /a-d *.lua') do (
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

echo Symbolic links created for all .lua files in .release directory
