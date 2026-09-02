# AnimeTrack

A single-file anime watch tracker that lives entirely in your browser. No account, no server, no build step: open the HTML file and it works. Your list is saved to `localStorage`, so it never leaves your machine.

<img width="800" height="554" alt="demo" src="https://github.com/user-attachments/assets/a4c776a8-f23f-4861-b3ef-7858cbce0357" />


## Features

- **Track seasons and episodes** for everything you're watching, with a one-tap stepper to bump your progress
- **Live cover art, autocomplete, and typo correction** pulled from MyAnimeList, AniList, and Kitsu as you type
- **Find something to watch**: pick a genre and get a matching suggestion
- **Popular right now**: a live top-10 of what's trending, one tap to add
- **8 accent colors × light/dark**: pick a theme and the whole app repaints, colors saved per device
- **Watch history** and one-click JSON export/import for backups
- **Watch anime**: type a title, pick Sub or Dub, and it launches ani-cli in a new terminal window for you

## Getting started

Download the repo and open `anime track.html` in any browser. That's it, the tracker, theming, recommendations, and history all work immediately with no setup.

### Optional: the "Watch anime" button

This one feature needs a tiny local helper, because a webpage is never allowed to open a terminal or run a program on its own. That's a browser safety boundary, not a bug. The helper (`ani-cli-bridge.js`) listens on `127.0.0.1` only and opens `ani-cli` for you when you ask.

**First time only, on Windows:**

1. Run **`SETUP INSTALL.bat`**. It installs everything `ani-cli` needs (Scoop, Git, `ani-cli`, `fzf`, `ffmpeg`, `mpv`). Safe to run again any time; it skips anything already installed.
2. Run **`start-ani-cli-bridge.bat`** and leave that window open while you use the site.
3. Click **Watch anime**, type a title, choose Sub or Dub, hit Watch.

Not on Windows, or don't want this feature? Ignore both `.bat` files, everything else in AnimeTrack works exactly the same without them.

## How it works

- **Data**: your anime list, episode progress, and watch history live in `localStorage`. Nothing is sent anywhere except the read-only lookups to MyAnimeList/AniList/Kitsu for cover art and recommendations.
- **The bridge**: `ani-cli-bridge.js` is a ~100-line local HTTP server. It never listens outside `127.0.0.1`, and every title is sanitized before it ever reaches a shell.

## Credits

Made by **Elko**. Questions or issues: [elmenelek.xyz](https://elmenelek.xyz)

Cover art, search, and recommendations come from: MyAnimeList (Jikan), AniList, and Kitsu APIs.
