import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

bool _swRegistered = false;
bool _swFailed = false;

/// Registers the reel-stream service worker (once) and pushes the latest
/// auth headers so it can inject them into streaming requests.
Future<bool> _ensureServiceWorker(Map<String, String> headers) async {
  if (_swFailed) return false;

  try {
    if (!_swRegistered) {
      final registration = await web.window.navigator.serviceWorker
          .register('reel-stream-sw.js'.toJS)
          .toDart;

      // Wait for the SW to become active if it's installing for the first time.
      final sw = registration.active ?? registration.installing ?? registration.waiting;
      if (sw != null && sw.state != 'activated') {
        final completer = Completer<void>();
        sw.onstatechange = ((web.Event _) {
          if (sw.state == 'activated') completer.complete();
        }).toJS;
        await completer.future.timeout(const Duration(seconds: 5));
      }
      _swRegistered = true;
    }

    // Push current auth headers to the SW.
    final controller = web.window.navigator.serviceWorker.controller;
    if (controller != null) {
      final jsHeaders = <String, String>{};
      headers.forEach((key, value) {
        jsHeaders[key] = value;
      });
      controller.postMessage({
        'type': 'SET_AUTH_HEADERS',
        'headers': jsHeaders,
      }.jsify());
      return true;
    }
  } catch (_) {
    _swFailed = true;
  }
  return false;
}

/// Prepares a playback URL for the reel video on web.
///
/// **Primary (streaming):** Registers a Service Worker that intercepts the
/// request and injects auth headers. The browser's native `<video>` element
/// then handles Range requests, chunked buffering, and seeking — no need
/// to download the entire file up front. Works for any file size.
///
/// **Fallback (blob):** If the Service Worker can't be registered (e.g. in
/// an iframe or insecure context), downloads the video via `fetch()` and
/// creates a Blob URL. This buffers the full file, so it's only practical
/// for shorter videos.
Future<String?> fetchVideoAsBlobUrl(String url, Map<String, String> headers) async {
  // --- Strategy 1: Service Worker streaming (preferred) ---
  final bool swReady = await _ensureServiceWorker(headers);
  if (swReady) {
    // Append a marker so the SW knows to intercept this specific request.
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}__reel_stream__=1';
  }

  // --- Strategy 2: Blob download fallback ---
  try {
    final jsHeaders = web.Headers();
    headers.forEach((key, value) {
      jsHeaders.append(key, value);
    });
    final response = await web.window
        .fetch(url.toJS, web.RequestInit(method: 'GET', headers: jsHeaders))
        .toDart;
    if (!response.ok) return null;
    final blob = await response.blob().toDart;
    return web.URL.createObjectURL(blob);
  } catch (_) {}
  return null;
}

/// Releases memory held by a Blob URL. No-op for Service Worker URLs.
void revokeBlobUrl(String url) {
  // Only revoke actual blob: URLs, not the SW streaming URLs.
  if (url.startsWith('blob:')) {
    try {
      web.URL.revokeObjectURL(url);
    } catch (_) {}
  }
}
