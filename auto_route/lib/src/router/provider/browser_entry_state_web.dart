import 'dart:js_interop';

import 'package:web/web.dart';

/// The state the app saved in the browser's current history entry, or null.
///
/// The engine keeps it as `{serialCount, state}`, the shape this reads; an
/// entry the app has not written holds no serial count.
// Matches the stub in browser_entry_state.dart; the saved state may be null.
// ignore: avoid-unnecessary-nullable-return-type
Object? browserEntryState() {
  final entry = window.history.state.dartify();
  return entry is Map && entry.containsKey('serialCount') ? entry['state'] : null;
}
