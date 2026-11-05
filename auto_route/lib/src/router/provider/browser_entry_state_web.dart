import 'dart:js_interop';

import 'package:web/web.dart';

/// The state the app saved in the browser's current history entry, or null.
///
/// The engine keeps it as `{serialCount, state}`, the shape this reads; an
/// entry the app has not written holds no serial count.
Object? browserEntryState() => switch (window.history.state.dartify()) {
  {'serialCount': _, 'state': final state} => state,
  _ => null,
};
