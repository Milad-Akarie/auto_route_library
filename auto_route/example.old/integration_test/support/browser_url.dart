/// The url in the browser's address bar, or null off the web.
String? browserUrl() => null;

/// The serial number the engine gives the browser's current history entry, or
/// null off the web.
int? browserEntryIndex() => null;

/// Presses the browser's back button; only the web has one.
void pressBrowserBack() =>
    throw UnsupportedError('Only the web has a browser back button.');

/// Presses the browser's forward button; only the web has one.
void pressBrowserForward() =>
    throw UnsupportedError('Only the web has a browser forward button.');

/// Types a url into the browser's address bar; only the web has one.
void typeBrowserUrl(String path) =>
    throw UnsupportedError('Only the web has an address bar.');

/// Makes the browser's current entry hold [path], as when the app is opened at
/// a deep link; only the web has one.
void openBrowserAt(String path) =>
    throw UnsupportedError('Only the web has an address bar.');

/// Whether the app has written the browser's current entry since
/// [openBrowserAt] made it;
/// only the web has one.
bool didAppWriteBrowserEntry() =>
    throw UnsupportedError('Only the web has a browser history.');

/// Makes the browser's current entry hold [path] and a state the app saved
/// there; only the web has one.
void saveBrowserEntryState(String path, Object state) =>
    throw UnsupportedError('Only the web has a browser history.');
