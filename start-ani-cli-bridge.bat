@echo off
title AnimeTrack - ani-cli bridge
cd /d "%~dp0"
echo AnimeTrack - Made by Elko
echo Starting the AnimeTrack ani-cli bridge...
echo Leave this window open while you use "Watch anime" on the site.
echo Close this window (or press Ctrl+C) to stop it.
echo.
node "ani-cli-bridge.js"
pause
