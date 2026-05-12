"use strict";

const HOST_NAME = "com.madpanda.darkzen.pandora_media";
const PANDORA_URLS = ["*://pandora.com/*", "*://*.pandora.com/*"];
const CONTROL_POLL_MS = 500;
const MESSAGE_TYPES = new Set([
  "madpanda-pandora-media",
  "madpanda-pandora-debug",
  "madpanda-pandora-control-poll",
  "madpanda-pandora-control-result"
]);
const controlPorts = new Set();
let controlPollTimer = null;

function isPandoraUrl(url) {
  try {
    const host = new URL(url || "").hostname;
    return host === "pandora.com" || host.endsWith(".pandora.com");
  } catch (_error) {
    return false;
  }
}

async function injectIntoTab(tabId) {
  if (!tabId) return;
  try {
    await chrome.scripting.executeScript({
      target: { tabId, allFrames: true },
      files: ["content-pandora.js"]
    });
  } catch (_error) {
    // Some Chrome pages and not-yet-ready restored tabs reject injection.
  }
}

async function injectExistingPandoraTabs() {
  try {
    const tabs = await chrome.tabs.query({ url: PANDORA_URLS });
    await Promise.all(tabs.map((tab) => injectIntoTab(tab.id)));
  } catch (_error) {
    // The regular content_script match still handles new Pandora page loads.
  }
}

function nativeRequest(payload) {
  return new Promise((resolve) => {
    let responded = false;
    try {
      const port = chrome.runtime.connectNative(HOST_NAME);
      port.onMessage.addListener((response) => {
        responded = true;
        resolve(response || { ok: true });
        port.disconnect();
      });
      port.onDisconnect.addListener(() => {
        if (!responded) {
          resolve({
            ok: false,
            error: chrome.runtime.lastError ? chrome.runtime.lastError.message : "native host disconnected"
          });
        }
      });
      port.postMessage(payload);
    } catch (error) {
      resolve({ ok: false, error: String(error) });
    }
  });
}

function nativeKindForType(type) {
  return type === "madpanda-pandora-debug"
    ? "debug"
    : type === "madpanda-pandora-control-poll"
      ? "control-poll"
      : type === "madpanda-pandora-control-result"
        ? "control-result"
        : "media";
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (!message || !MESSAGE_TYPES.has(message.type)) {
    return false;
  }

  nativeRequest({
    ...(message.payload || {}),
    __kind: nativeKindForType(message.type)
  }).then((response) => sendResponse(response || { ok: true }));
  return true;
});

async function pollNativeControl() {
  if (controlPorts.size === 0) return;
  const response = await nativeRequest({
    __kind: "control-poll",
    pageUrl: "",
    frameUrl: "",
    updatedAt: new Date().toISOString()
  });
  if (!response || !response.ok || !response.command) return;
  for (const port of [...controlPorts]) {
    try {
      port.postMessage({
        type: "control-command",
        command: response.command,
        nonce: response.nonce || ""
      });
    } catch (_error) {
      controlPorts.delete(port);
    }
  }
}

function ensureControlPolling() {
  if (controlPollTimer) return;
  controlPollTimer = setInterval(pollNativeControl, CONTROL_POLL_MS);
}

chrome.runtime.onConnect.addListener((port) => {
  if (!port || port.name !== "madpanda-pandora-control") return;
  controlPorts.add(port);
  ensureControlPolling();
  port.onMessage.addListener(() => {
    pollNativeControl();
  });
  port.onDisconnect.addListener(() => {
    controlPorts.delete(port);
    if (controlPorts.size === 0 && controlPollTimer) {
      clearInterval(controlPollTimer);
      controlPollTimer = null;
    }
  });
  pollNativeControl();
});

chrome.runtime.onInstalled.addListener(injectExistingPandoraTabs);
chrome.runtime.onStartup.addListener(injectExistingPandoraTabs);
chrome.tabs.onActivated.addListener(async ({ tabId }) => {
  try {
    const tab = await chrome.tabs.get(tabId);
    if (isPandoraUrl(tab.url)) await injectIntoTab(tabId);
  } catch (_error) {
    // Ignore tabs Chrome will not expose to this extension.
  }
});
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === "complete" && isPandoraUrl(tab.url)) {
    injectIntoTab(tabId);
  }
});
