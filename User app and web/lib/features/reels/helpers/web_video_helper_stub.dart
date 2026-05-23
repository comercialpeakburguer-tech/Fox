// Stub implementation for non-web platforms.
// These methods are never called on mobile (guarded by kIsWeb).

Future<String?> fetchVideoAsBlobUrl(String url, Map<String, String> headers) async => null;

void revokeBlobUrl(String url) {}
