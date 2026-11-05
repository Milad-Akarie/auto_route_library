import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// An observer that adds `push <name>` for each page route pushed, and
/// `pop <name>` for each route popped, to [events].
class RouteEventRecorder extends AutoRouterObserver {
  /// Records into [events].
  new(this.events);

  /// The events so far, oldest first.
  final List<String> events;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) {
    if (route is PageRoute) {
      events.add('push ${route.settings.name ?? 'unnamed'}');
    }
  }

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) =>
      events.add('pop ${route.settings.name ?? 'unnamed'}');
}
