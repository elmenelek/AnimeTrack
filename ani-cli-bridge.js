/* ============================================================
   AnimeTrack -> ani-cli bridge
   A browser tab can never launch a terminal or run a program by
   itself — that sandbox is intentional. This script is the
   missing piece: it listens on 127.0.0.1 only (nothing outside
   this machine can reach it), and when the "Watch anime" button
   on the page asks for a title, it opens Git Bash directly and
   runs `ani-cli` inside it for you.

   Git Bash directly, not cmd.exe: on a fresh Windows machine,
   the ani-cli.cmd shim that Scoop generates internally re-invokes
   a bare `bash` to detect WSL vs Git Bash, and that bare `bash`
   often isn't resolvable at all if Git Bash's bin folder was
   never added to PATH. Launching bash.exe directly and letting
   IT resolve `ani-cli` through its own PATH sidesteps that
   entirely — bash resolves the shim correctly either way.

   Usage: double-click start-ani-cli-bridge.bat (or run
   `node ani-cli-bridge.js`) and leave the window open while you
   use the site. Ctrl+C to stop it.
   ============================================================ */

const http = require("http");
const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");

const PORT = 53177;
const HOST = "127.0.0.1";

function findBash() {
    const home = process.env.USERPROFILE || "";
    const candidates = [
        path.join(home, "scoop", "apps", "git", "current", "bin", "bash.exe"),
        "C:\\Program Files\\Git\\bin\\bash.exe",
        "C:\\Program Files (x86)\\Git\\bin\\bash.exe"
    ];
    return candidates.find(p => fs.existsSync(p)) || null;
}

// mintty.exe is the actual Git Bash terminal window (the one you get from
// the Start Menu shortcut). It lives under usr/bin, a different folder
// than bash.exe itself.
function findMintty() {
    const home = process.env.USERPROFILE || "";
    const candidates = [
        path.join(home, "scoop", "apps", "git", "current", "usr", "bin", "mintty.exe"),
        "C:\\Program Files\\Git\\usr\\bin\\mintty.exe",
        "C:\\Program Files (x86)\\Git\\usr\\bin\\mintty.exe"
    ];
    return candidates.find(p => fs.existsSync(p)) || null;
}

// Only letters, numbers, spaces and a few safe punctuation marks
// survive into the command line — everything else is stripped so
// a title can never break out of the quoted argument.
function sanitize(name) {
    return name.replace(/[^\w\s\-'.:!?]/g, "").trim();
}

// Wraps a string in single quotes the way bash expects, escaping
// any single quotes already inside it, so the title is always
// treated as one literal argument no matter what it contains.
function bashSingleQuote(str) {
    return "'" + str.replace(/'/g, "'\\''") + "'";
}

const server = http.createServer((req, res) => {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "GET, OPTIONS");

    if (req.method === "OPTIONS") { res.writeHead(204); res.end(); return; }

    const url = new URL(req.url, `http://${HOST}:${PORT}`);

    if (url.pathname === "/ping") {
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ ok: true }));
        return;
    }

    if (url.pathname !== "/watch") {
        res.writeHead(404, { "Content-Type": "text/plain" });
        res.end("Not found");
        return;
    }

    const rawName = url.searchParams.get("name") || "";
    const dub = url.searchParams.get("dub") === "1";
    const name = sanitize(rawName);

    if (!name) {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ ok: false, error: "Missing anime name" }));
        return;
    }

    const bashPath = findBash();
    if (!bashPath) {
        res.writeHead(500, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ ok: false, error: "Git Bash not found. Run SETUP INSTALL.bat first." }));
        return;
    }

    const aniCliCmd = "ani-cli " + bashSingleQuote(name) + (dub ? " --dub" : "");
    const fullCmd = aniCliCmd + '; echo; read -n 1 -s -r -p "Press any key to close..."';

    // ani-cli is interactive (fzf needs a real terminal to show the match
    // list), so it can't run headless - it needs an actual terminal window.
    // mintty is the real Git Bash terminal (what the Start Menu shortcut
    // opens); fall back to a plain console window if it isn't installed.
    const minttyPath = findMintty();
    const child = minttyPath
        ? spawn(minttyPath, ["-t", "ani-cli", "-e", bashPath, "-l", "-c", fullCmd], {
            detached: true,
            stdio: "ignore",
            windowsHide: false
        })
        : spawn("cmd.exe", ["/c", "start", "ani-cli", bashPath, "-i", "-l", "-c", fullCmd], {
            detached: true,
            stdio: "ignore",
            windowsHide: false
        });
    child.on("error", (err) => console.error("Failed to launch Git Bash:", err.message));
    child.unref();

    console.log(`Launching: ${aniCliCmd}`);

    res.setHeader("Content-Type", "application/json");
    res.writeHead(200);
    res.end(JSON.stringify({ ok: true, command: aniCliCmd }));
});

server.listen(PORT, HOST, () => {
    console.log(`AnimeTrack <-> ani-cli bridge running at http://${HOST}:${PORT}`);
    console.log(`Leave this window open. Press Ctrl+C to stop.`);
});
