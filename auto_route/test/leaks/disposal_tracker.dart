import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records each object of type [T] that Flutter reports created while it
/// listens, and forgets it once Flutter reports it disposed.
///
/// Flutter reports these events in debug builds only. The tracker stops
/// listening when the test ends.
class DisposalTracker<T extends Object> {
  /// Starts listening to Flutter's object events.
  DisposalTracker() {
    FlutterMemoryAllocations.instance.addListener(_onEvent);
    addTearDown(() => FlutterMemoryAllocations.instance.removeListener(_onEvent));
  }

  final _live = Set<T>.identity();

  /// How many objects of type [T] were created since the tracker started.
  int created = 0;

  /// How many of the objects created since the tracker started are not
  /// disposed.
  int get undisposed => _live.length;

  /// Whether [object] was created since the tracker started and is not
  /// disposed.
  bool isUndisposed(T object) => _live.contains(object);

  void _onEvent(ObjectEvent event) {
    final object = event.object;
    if (object is! T) return;
    if (event is ObjectCreated) {
      created++;
      _live.add(object);
    } else if (event is ObjectDisposed) {
      _live.remove(object);
    }
  }
}
