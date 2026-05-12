# MADPANDA Pandora Media Bridge

Minimal Chrome extension for Dark Zen's local Eww media widget.

It runs only on `*://pandora.com/*` and `*://*.pandora.com/*`, reads the current Pandora
now-playing metadata and album-art URL from the page and restored frames, updates
`navigator.mediaSession.metadata`, and sends the same small payload to the local
native messaging host `com.madpanda.darkzen.pandora_media`.

The service worker also injects the content script into already-open/restored
Pandora tabs so session restore does not leave the drawer without artwork.

The native host writes only the current title, artist, album, source URL, cached
cover path, status, heartbeat diagnostics, and timestamps under:

```text
$XDG_CACHE_HOME/madpanda/pandora-media/
```

No cookies, account data, or browsing history are stored.

Launch Chrome through:

```bash
mad-chrome-dark-zen
```

Dark Zen wires this helper to `SUPER+E` and installs a user-level
`google-chrome.desktop` override so app launchers and normal browser links also
enter through the same helper. `SUPER+E` opens a new Chrome window on the
current workspace.
