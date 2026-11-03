/// The url in the browser's address bar, or null off the web.
String? browserUrl() => null;

/// The serial number the engine gives the browser's current history entry, or null off the web.
int? browserEntryIndex() => null;

/// Presses the browser's back button; only the web has one.
void pressBrowserBack() => throw UnsupportedError('Only the web has a browser back button.');
