import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// The tag name of the element that has the browser's focus, such as `INPUT`
/// or `FLUTTER-VIEW`.
///
/// With semantics on, a focused Flutter text field is a DOM `<input>` that
/// the engine keeps focused while the user types.
// Matches the stub in browser_focus.dart, which has no browser to read.
String? browserFocusedTag() {
  final document = globalContext.getProperty<JSObject>('document'.toJS);
  final focused = document.getProperty<JSObject?>('activeElement'.toJS);
  return focused?.getProperty<JSString>('tagName'.toJS).toDart;
}
