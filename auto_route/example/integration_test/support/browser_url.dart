/// The url in the browser's address bar, or null off the web.
String? browserUrl() => null;

/// Presses the browser's back button; only the web has one.
void pressBrowserBack() => throw UnsupportedError('Only the web has a browser back button.');
