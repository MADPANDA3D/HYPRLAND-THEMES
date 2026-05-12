"use strict";

(() => {
  const host = location.hostname || "";
  if (host !== "pandora.com" && !host.endsWith(".pandora.com")) return;

  if (window.__madpandaPandoraMediaBridgeActive) return;
  window.__madpandaPandoraMediaBridgeActive = true;

  const POLL_MS = 2000;
  const HEARTBEAT_MS = 5000;
  const CONTROL_POLL_MS = 500;
  let lastPayload = "";
  let lastHeartbeat = 0;
  let lastControlPoll = 0;
  let mediaSessionHandlersReady = false;

  const textSelectors = {
    title: [
      ".nowPlayingTopInfo__current__trackName",
      '[data-qa="mini_track_title"]',
      '[data-qa="now_playing_track_title"]',
      '[data-qa="track_title"]',
      ".nowPlayingTopInfo__current__trackName",
      ".nowPlayingTopInfo__current__title",
      ".nowPlayingTopInfo__trackName",
      ".Tuner__Audio__TrackDetail__title"
    ],
    artist: [
      ".NowPlayingTopInfo__current__artistName",
      ".nowPlayingTopInfo__current__artistName",
      '[data-qa="mini_track_artist_name"]',
      '[data-qa="now_playing_artist_name"]',
      '[data-qa="artist_name"]',
      ".nowPlayingTopInfo__current__artistName",
      ".nowPlayingTopInfo__artistName",
      ".Tuner__Audio__TrackDetail__artist"
    ],
    album: [
      ".nowPlayingTopInfo__current__albumName",
      '[data-qa="mini_track_album_title"]',
      '[data-qa="now_playing_album_title"]',
      '[data-qa="album_title"]',
      ".nowPlayingTopInfo__current__albumName",
      ".nowPlayingTopInfo__albumName",
      ".Tuner__Audio__TrackDetail__album"
    ]
  };

  const artSelectors = [
    ".NowPlayinfTopInfo__artContainer__img",
    ".nowPlayingTopInfo__artContainer img",
    ".nowPlayingTopInfo__artContainer__art img",
    '[data-qa="album_art"] img',
    ".nowPlayingTopInfo__artContainer__art img",
    '[class*="artContainer" i] img',
    ".ImageLoader img",
    '[class*="ImageLoader" i] img',
    'img[src*="p-cdn.us/images"]',
    'img[src*="cont-"][src*="p-cdn.us"]'
  ];

  function cleanText(value) {
    const text = (value || "").replace(/\s+/g, " ").trim();
    for (const count of [4, 3, 2]) {
      if (text.length > 0 && text.length % count === 0) {
        const chunk = text.slice(0, text.length / count);
        if (chunk.repeat(count) === text) return chunk.trim();
      }
    }
    return text;
  }

  function unique(items) {
    return [...new Set(items.filter(Boolean))];
  }

  function visibleRect(element) {
    if (!element || !element.getBoundingClientRect) return null;
    const rect = element.getBoundingClientRect();
    if (rect.width <= 0 || rect.height <= 0) return null;
    return rect;
  }

  function rootCandidates() {
    return unique([
      ...document.querySelectorAll('[class*="nowPlayingTopInfo" i]'),
      ...document.querySelectorAll('[data-qa*="now_playing" i]'),
      ...document.querySelectorAll('[class*="Tuner__Audio" i]'),
      ...document.querySelectorAll('[class*="MiniPlayer" i]'),
      document
    ]);
  }

  function firstText(selectors) {
    for (const root of rootCandidates()) {
      for (const selector of selectors) {
        const element = root.querySelector(selector);
        const text = cleanText(element && element.textContent);
        if (text) return text;
      }
    }
    return "";
  }

  function imageCandidates() {
    const images = [];
    for (const root of rootCandidates()) {
      for (const selector of artSelectors) {
        images.push(...root.querySelectorAll(selector));
      }
    }

    return unique(images)
      .map((img) => {
        const src = img && (img.currentSrc || img.src);
        const rect = visibleRect(img) || { width: 0, height: 0, top: 0, left: 0, right: 0, bottom: 0 };
        const visible = rect.width > 24 && rect.height > 24;
        const area = Math.round(rect.width * rect.height);
        return { img, src, rect, visible, area };
      })
      .filter((item) => item.src && /^https?:\/\//.test(item.src))
      .sort((a, b) => Number(b.visible) - Number(a.visible) || b.area - a.area);
  }

  function backgroundArtCandidates() {
    const candidates = [];
    const targets = [
      ...document.querySelectorAll('[class*="artContainer" i]'),
      ...document.querySelectorAll('[class*="ImageLoader" i]')
    ];

    for (const element of targets) {
      const rect = visibleRect(element);
      const image = window.getComputedStyle(element).backgroundImage || "";
      const match = image.match(/url\(["']?(https?:\/\/[^"')]+)["']?\)/);
      if (match) {
        candidates.push({
          img: element,
          src: match[1],
          rect: rect || { width: 0, height: 0, top: 0, left: 0, right: 0, bottom: 0 },
          visible: Boolean(rect),
          area: rect ? Math.round(rect.width * rect.height) : 0
        });
      }
    }
    return candidates;
  }

  function bestArt() {
    const ranked = [...imageCandidates(), ...backgroundArtCandidates()]
      .filter((item) => item.src && /^https?:\/\//.test(item.src))
      .sort((a, b) => Number(b.visible) - Number(a.visible) || b.area - a.area);
    return ranked[0] || null;
  }

  function textNearRect(rect) {
    if (!rect || !rect.width || !rect.height) return [];
    const elements = [
      ...document.querySelectorAll('[data-qa], [class*="nowPlaying" i], [class*="Tuner" i], [class*="Mini" i], span, a, button')
    ];
    const lines = [];

    for (const element of elements) {
      const text = cleanText(element.textContent);
      if (!text || text.length > 90) continue;
      if (/^(now playing|my station|shuffle stations|upgrade|pandora)$/i.test(text)) continue;
      const candidateRect = visibleRect(element);
      if (!candidateRect) continue;
      const dx = Math.max(0, Math.max(rect.left - candidateRect.right, candidateRect.left - rect.right));
      const dy = Math.max(0, Math.max(rect.top - candidateRect.bottom, candidateRect.top - rect.bottom));
      if (dx > 360 || dy > 220) continue;
      lines.push({
        text,
        distance: Math.round(dx + dy),
        top: Math.round(candidateRect.top),
        left: Math.round(candidateRect.left)
      });
    }

    return unique(lines
      .sort((a, b) => a.distance - b.distance || a.top - b.top || a.left - b.left)
      .map((item) => item.text));
  }

  function inferFromNearby(lines) {
    const filtered = lines.filter((line) => !/^(thumbs|play|pause|skip|previous|next)$/i.test(line));
    const inferred = {};
    if (filtered[0]) inferred.title = filtered[0];
    const combined = filtered.find((line) => /\s[-–—]\s/.test(line));
    if (combined) {
      const parts = combined.split(/\s[-–—]\s/).map(cleanText).filter(Boolean);
      if (parts[0]) inferred.artist = parts[0];
      if (parts[1]) inferred.album = parts.slice(1).join(" - ");
    } else if (filtered[1]) {
      inferred.artist = filtered[1];
    }
    return inferred;
  }

  function playbackStatus() {
    const pressedPause = document.querySelector('[aria-label*="Pause" i], [title*="Pause" i]');
    const pressedPlay = document.querySelector('[aria-label*="Play" i], [title*="Play" i]');
    if (pressedPause) return "Playing";
    if (pressedPlay) return "Paused";
    return "Playing";
  }

  const controlSelectors = {
    next: [
      '[data-qa="skip_button"]',
      '[data-qa*="skip" i]',
      '[aria-label="Skip"]',
      '[aria-label*="Skip" i]',
      '[aria-label*="Next" i]',
      '[title="Skip"]',
      '[title*="Skip" i]',
      '[title*="Next" i]',
      'button[class*="Skip" i]',
      '[role="button"][class*="Skip" i]',
      'button[class*="skip" i]',
      '[role="button"][class*="skip" i]'
    ],
    previous: [
      '[data-qa="replay_button"]',
      '[aria-label*="Replay" i]',
      '[aria-label*="Previous" i]',
      '[title*="Replay" i]',
      '[title*="Previous" i]',
      'button[class*="Replay" i]',
      'button[class*="Previous" i]',
      '[role="button"][class*="Replay" i]',
      '[role="button"][class*="Previous" i]'
    ],
    "play-pause": [
      '[aria-label*="Pause" i]',
      '[aria-label*="Play" i]',
      '[title*="Pause" i]',
      '[title*="Play" i]',
      'button[class*="PlayButton" i]',
      'button[class*="PauseButton" i]'
    ]
  };

  function clickableControl(element) {
    if (!element) return null;
    const control = element.closest("button,[role='button'],a") || element;
    if (control.disabled || control.getAttribute("aria-disabled") === "true") return null;
    const rect = visibleRect(control);
    if (!rect || rect.width < 8 || rect.height < 8) return null;
    return control;
  }

  function clickFirstControl(command) {
    const selectors = controlSelectors[command] || [];
    for (const selector of selectors) {
      for (const element of document.querySelectorAll(selector)) {
        const control = clickableControl(element);
        if (!control) continue;
        control.click();
        return {
          clicked: true,
          selector,
          reason: ""
        };
      }
    }
    return {
      clicked: false,
      selector: "",
      reason: "selector-missing"
    };
  }

  function handleControlCommand(command, nonce) {
    if (!command || window.top !== window) return false;
    const result = clickFirstControl(command);
    document.documentElement.dataset.madpandaPandoraControl = result.clicked
      ? `clicked:${command}`
      : `missing:${command}`;
    send("madpanda-pandora-control-result", {
      action: command,
      nonce: nonce || "",
      clicked: result.clicked,
      selector: result.selector,
      reason: result.reason,
      pageUrl: location.href,
      frameUrl: location.href,
      isTopFrame: true,
      updatedAt: new Date().toISOString()
    });
    return result.clicked;
  }

  function inferFromDocument() {
    const title = cleanText(document.title);
    if (!title || title.toLowerCase().includes("pandora")) return {};
    const parts = title.split(/\s[-–—]\s/).map(cleanText).filter(Boolean);
    if (parts.length >= 2) {
      return { title: parts[0], artist: parts.slice(1).join(" - ") };
    }
    return { title };
  }

  function collect() {
    const selectedArt = bestArt();
    const nearbyLines = selectedArt ? textNearRect(selectedArt.rect) : [];
    const nearby = inferFromNearby(nearbyLines);
    const inferred = inferFromDocument();
    const selectedArtUrl = selectedArt ? selectedArt.src : "";
    const explicitTitle = firstText(textSelectors.title);
    const explicitArtist = firstText(textSelectors.artist);
    const explicitAlbum = firstText(textSelectors.album);

    const title = explicitTitle || nearby.title || inferred.title || "Pandora";
    const artist = explicitArtist || nearby.artist || inferred.artist || "";
    const album = explicitAlbum || nearby.album || "";
    const images = imageCandidates();

    const payload = {
      source: "pandora",
      title,
      artist,
      album,
      artUrl: selectedArtUrl,
      pageUrl: location.href,
      status: playbackStatus(),
      updatedAt: new Date().toISOString()
    };

    const debug = {
      pageUrl: location.href,
      frameUrl: location.href,
      documentTitle: cleanText(document.title),
      bridgeMarker: document.documentElement.dataset.madpandaPandoraBridge || "active",
      isTopFrame: window.top === window,
      imageCount: images.length,
      visibleImageCount: images.filter((item) => item.visible).length,
      selectedArtUrl,
      selectedArtArea: selectedArt ? selectedArt.area : 0,
      textFieldCount: [explicitTitle, explicitArtist, explicitAlbum].filter(Boolean).length,
      nearbyTextCount: nearbyLines.length,
      titleFound: Boolean(title && title !== "Pandora"),
      artistFound: Boolean(artist),
      albumFound: Boolean(album),
      updatedAt: payload.updatedAt
    };

    return { payload, debug };
  }

  function updateMediaSession(payload) {
    if (!("mediaSession" in navigator) || !window.MediaMetadata) return;
    const artwork = payload.artUrl
      ? [
          { src: payload.artUrl, sizes: "500x500", type: "image/jpeg" },
          { src: payload.artUrl, sizes: "512x512", type: "image/jpeg" }
        ]
      : [];

    try {
      navigator.mediaSession.metadata = new MediaMetadata({
        title: payload.title || "Pandora",
        artist: payload.artist || "Pandora",
        album: payload.album || "",
        artwork
      });
    } catch (_error) {
      // A bad image URL should never break the page or the bridge.
    }

    if (!mediaSessionHandlersReady && navigator.mediaSession.setActionHandler) {
      try {
        navigator.mediaSession.setActionHandler("nexttrack", () => {
          const result = clickFirstControl("next");
          send("madpanda-pandora-control-result", {
            action: "next",
            nonce: "media-session",
            clicked: result.clicked,
            selector: result.selector,
            reason: result.reason,
            pageUrl: location.href,
            frameUrl: location.href,
            isTopFrame: window.top === window,
            updatedAt: new Date().toISOString()
          });
        });
      } catch (_error) {
        // Older Chrome builds may reject optional action handlers.
      }
      try {
        navigator.mediaSession.setActionHandler("previoustrack", () => {
          const result = clickFirstControl("previous");
          send("madpanda-pandora-control-result", {
            action: "previous",
            nonce: "media-session",
            clicked: result.clicked,
            selector: result.selector,
            reason: result.reason,
            pageUrl: location.href,
            frameUrl: location.href,
            isTopFrame: window.top === window,
            updatedAt: new Date().toISOString()
          });
        });
      } catch (_error) {
        // Pandora often has replay instead of true previous; missing is fine.
      }
      mediaSessionHandlersReady = true;
    }
  }

  function send(type, payload, callback) {
    chrome.runtime.sendMessage({ type, payload }, (response) => {
      document.documentElement.dataset.madpandaPandoraBridge = chrome.runtime.lastError
        ? `error: ${chrome.runtime.lastError.message}`
        : response && response.ok
          ? "ok"
          : "sent";
      if (callback) callback(response || {});
    });
  }

  function pollControl(payload) {
    if (window.top !== window) return;
    const now = Date.now();
    if (now - lastControlPoll < CONTROL_POLL_MS) return;
    lastControlPoll = now;
    send("madpanda-pandora-control-poll", {
      pageUrl: payload.pageUrl,
      frameUrl: location.href,
      isTopFrame: true,
      updatedAt: new Date().toISOString()
    }, (response) => {
      if (response && response.ok && response.command) {
        handleControlCommand(response.command, response.nonce || "");
      }
    });
  }

  function setupControlPort() {
    if (window.top !== window) return;
    let port = null;
    let heartbeatTimer = null;

    const heartbeat = () => {
      if (!port) return;
      try {
        port.postMessage({
          type: "heartbeat",
          pageUrl: location.href,
          updatedAt: new Date().toISOString()
        });
      } catch (_error) {
        // The disconnect handler will reconnect.
      }
    };

    const connect = () => {
      try {
        port = chrome.runtime.connect({ name: "madpanda-pandora-control" });
        port.onMessage.addListener((message) => {
          if (message && message.type === "control-command" && message.command) {
            handleControlCommand(message.command, message.nonce || "");
          }
        });
        port.onDisconnect.addListener(() => {
          port = null;
          if (heartbeatTimer) {
            clearInterval(heartbeatTimer);
            heartbeatTimer = null;
          }
          setTimeout(connect, 2000);
        });
        heartbeat();
        heartbeatTimer = setInterval(heartbeat, 2000);
      } catch (_error) {
        setTimeout(connect, 2000);
      }
    };

    connect();
  }

  function tick() {
    const { payload, debug } = collect();
    const fingerprint = JSON.stringify(payload);
    updateMediaSession(payload);
    if (fingerprint !== lastPayload) {
      lastPayload = fingerprint;
      send("madpanda-pandora-media", payload);
    }

    const now = Date.now();
    if (now - lastHeartbeat > HEARTBEAT_MS) {
      lastHeartbeat = now;
      send("madpanda-pandora-debug", debug);
    }
    pollControl(payload);
  }

  document.documentElement.dataset.madpandaPandoraBridge = "active";
  setupControlPort();
  tick();
  setInterval(tick, POLL_MS);
  new MutationObserver(tick).observe(document.documentElement, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ["src", "class", "data-qa"]
  });
})();
