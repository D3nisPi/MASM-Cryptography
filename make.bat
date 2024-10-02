@echo off
setlocal enabledelayedexpansion
:: Environment variables
:: LIB - path to libraries (e.g. C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22621.0\um\x64\)
:: PATH - path to compiler (e.g. C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.41.34120\bin\Hostx64\x64\)

:: Params
set ENTRY=main
set EXEC_NAME=main.exe
set SOURCE_DIR=src
set BUILD_DIR=build
set LIBS=kernel32.Lib bcrypt.lib
set OPTIONS=/Fe.\%BUILD_DIR%\%EXEC_NAME% /w /nologo /Zi
set LINK_OPTIONS=%LIBS% /entry:%ENTRY% /nologo

:: Getting file list
for /r %SOURCE_DIR% %%I in (*.asm) do (
    set ABS_PATH=%%I
    set REL_PATH=!ABS_PATH:%~dp0=!
    set FILE_LIST=!FILE_LIST! !REL_PATH!
)
set FILE_LIST=%FILE_LIST:~1%

:: Creating .\build if not exist
if not exist %BUILD_DIR% (
    mkdir %BUILD_DIR%
)


:: Creating compilation command
:: ML64 [ /options ] filelist [ /link linkoptions ]
set COMPILE_CMD=ml64 %OPTIONS% %FILE_LIST% /link %LINK_OPTIONS%

:: Compilation
echo ***********************************************************
cmd /c %COMPILE_CMD%
echo ***********************************************************
if %ERRORLEVEL% neq 0 (
    exit
)

:: Remove files
del .\*.obj
del .\*.lnk

:: Run program
cmd /c %BUILD_DIR%\%EXEC_NAME%
echo.
echo Return code: %ERRORLEVEL%

endlocal