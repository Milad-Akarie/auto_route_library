import 'dart:js_interop';

@JS('location')
external _Location get _location;

extension type _Location(JSObject _) implements JSObject {
  external String get hash;
  external String get pathname;
  external String get search;
}

/// The url in the browser's address bar, without the origin.
///
/// Flutter web keeps the url after '#' by default, so that part wins when set.
String? browserUrl() {
  final hash = _location.hash;
  if (hash.length > 1) return hash.substring(1);
  return '${_location.pathname}${_location.search}';
}
