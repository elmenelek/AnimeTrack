@echo off
title AnimeTrack - ani-cli setup
color 0B
cd /d "%~dp0"

echo ================================================
echo   AnimeTrack  -  ani-cli installer for Windows
echo   Made by Elko
echo ================================================
echo.
echo This sets up everything ani-cli needs on a clean
echo Windows 10 / 11 machine.
echo   - Scoop (package manager)
echo   - Git
echo   - Windows Terminal
echo   - ani-cli, fzf, ffmpeg, mpv
echo.

net session >nul 2>nul
if errorlevel 1 goto :notadmin
echo [BLOCKED] This window is running as Administrator.
echo Scoop refuses to install itself as admin on purpose.
echo.
echo Close this window, then double-click this file again
echo normally - do NOT choose "Run as administrator".
echo.
pause
exit /b 1

:notadmin
echo Press any key to start...
pause >nul
echo.

set "FAILED=0"
call :refresh_path

where scoop >nul 2>nul
if not errorlevel 1 goto :scoop_present
echo [1/6] Installing Scoop...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; try { Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force } catch {}; Invoke-RestMethod get.scoop.sh -UseBasicParsing | Invoke-Expression"
call :refresh_path
where scoop >nul 2>nul
if not errorlevel 1 goto :scoop_ok
echo [FAILED] Scoop did not install. Scroll up for the PowerShell error.
echo.
echo Common fixes:
echo   - Check your internet connection
echo   - Make sure this window is NOT run as administrator
echo   - Try running this directly in a normal PowerShell window:
echo       irm get.scoop.sh | iex
set "FAILED=1"
goto :summary
:scoop_ok
echo [OK] Scoop installed.
goto :after_scoop
:scoop_present
echo [1/6] Scoop already installed, skipping.
:after_scoop

where git >nul 2>nul
if not errorlevel 1 goto :git_present
echo.
echo [2/6] Installing Git...
call scoop install git
if errorlevel 1 (
    echo [FAILED] Git did not install.
    set "FAILED=1"
    goto :summary
)
call :refresh_path
echo [OK] Git installed.
goto :after_git
:git_present
echo [2/6] Git already installed, skipping.
:after_git

call :fix_bash_path

echo.
echo [3/6] Adding the extras bucket...
call scoop bucket add extras
echo [OK] extras bucket ready.

where wt >nul 2>nul
if not errorlevel 1 goto :wt_present
echo.
echo [4/6] Installing Windows Terminal...
call scoop install extras/windows-terminal
if errorlevel 1 (
    echo [WARN] Windows Terminal did not install. Not required for
    echo AnimeTrack to work, continuing anyway.
) else (
    echo [OK] Windows Terminal installed.
)
goto :after_wt
:wt_present
echo [4/6] Windows Terminal already present, skipping.
:after_wt

echo.
echo [5/6] Installing ani-cli, fzf, ffmpeg, mpv...
call scoop install ani-cli fzf ffmpeg mpv
if errorlevel 1 (
    echo [FAILED] One of ani-cli / fzf / ffmpeg / mpv did not install.
    echo Scroll up to see which one and why.
    set "FAILED=1"
    goto :summary
)
echo [OK] ani-cli and its dependencies installed.

echo.
echo [6/6] Installing yt-dlp - optional, used for downloads...
call scoop install yt-dlp
if errorlevel 1 (
    echo [WARN] yt-dlp did not install. Downloads inside ani-cli may
    echo not work, but watching will still work fine.
)

call :refresh_path
where ani-cli >nul 2>nul
if not errorlevel 1 goto :summary
echo.
echo [FAILED] ani-cli was not found on PATH after install.
set "FAILED=1"

:summary
echo.
echo ================================================
if "%FAILED%"=="1" goto :summary_failed
echo   Done.
echo.
echo   Now start the AnimeTrack bridge with
echo   start-ani-cli-bridge.bat and use the
echo   "Watch anime" button on the site.
echo.
echo   If you have any issues or questions, contact me:
echo   elmenelek.xyz
goto :end
:summary_failed
echo   Setup did not finish. See the [FAILED] lines above.
echo   Fix that, then run this file again.
:end
echo ================================================
echo.
pause
exit /b %FAILED%

:refresh_path
set "PATH=%PATH%;%USERPROFILE%\scoop\shims;%USERPROFILE%\scoop\apps\git\current\cmd;%USERPROFILE%\scoop\apps\git\current\bin"
exit /b 0

:fix_bash_path
set "GITBASHDIR="
if exist "%USERPROFILE%\scoop\apps\git\current\bin\bash.exe" set "GITBASHDIR=%USERPROFILE%\scoop\apps\git\current\bin"
if not defined GITBASHDIR if exist "C:\Program Files\Git\bin\bash.exe" set "GITBASHDIR=C:\Program Files\Git\bin"
if not defined GITBASHDIR (
    echo [WARN] Could not find Git's bash.exe. ani-cli needs the
    echo "bash" command to work - if it fails later, this is why.
    exit /b 0
)
set "PATH=%PATH%;%GITBASHDIR%"
where bash >nul 2>nul
if not errorlevel 1 (
    echo [OK] "bash" already resolves to Git Bash.
    exit /b 0
)
echo [OK] Adding Git Bash to PATH so "bash" works everywhere...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$dir = [Environment]::GetEnvironmentVariable('Path','User'); if ($dir -notlike '*%GITBASHDIR%*') { [Environment]::SetEnvironmentVariable('Path', ($dir + ';%GITBASHDIR%'), 'User') }"
exit /b 0
