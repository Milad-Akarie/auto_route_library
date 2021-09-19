import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@protected
class RouterScope extends InheritedWidget {
  final RoutingController controller;
  final NavigatorObserversBuilder inheritableObserversBuilder;
  final int segmentsHash;
  final List<NavigatorObserver> navigatorObservers;

  const RouterScope({
    required Widget child,
    required this.controller,
    required this.navigatorObservers,
    required this.inheritableObserversBuilder,
    required this.segmentsHash,
  }) : super(child: child);

  static RouterScope of(BuildContext context, {bool watch = false}) {
    var scope;
    if (watch) {
      scope = context.dependOnInheritedWidgetOfExactType<RouterScope>();
    } else {
      scope = context.findAncestorWidgetOfExactType<RouterScope>();
    }
    assert(() {
      if (scope == null) {
        throw FlutterError(
            'RouterScope operation requested with a context that does not include a RouterScope.\n'
            'The context used to retrieve the Router must be that of a widget that '
            'is a descendant of a RouterScope widget.');
      }
      return true;
    }());
    return scope!;
  }

  T? firstObserverOfType<T extends NavigatorObserver>() {
    final typedObservers = navigatorObservers.whereType<T>();
    if (typedObservers.isNotEmpty) {
      return typedObservers.first;
    } else {
      return null;
    }
  }

  @override
  bool updateShouldNotify(covariant RouterScope oldWidget) {
    return segmentsHash != oldWidget.segmentsHash;
  }
}

class StackRouterScope extends InheritedWidget {
  final StackRouter controller;
  final int segmentsHash;

  const StackRouterScope({
    required Widget child,
    required this.controller,
    required this.segmentsHash,
  }) : super(child: child);

  static StackRouterScope? of(BuildContext context, {bool watch = false}) {
    if (watch) {
      return context.dependOnInheritedWidgetOfExactType<StackRouterScope>();
    }
    return context.findAncestorWidgetOfExactType<StackRouterScope>();
  }

  @override
  bool updateShouldNotify(covariant StackRouterScope oldWidget) {
    return segmentsHash != oldWidget.segmentsHash;
  }
}

class TabsRouterScope extends InheritedWidget {
  final TabsRouter controller;
  final int segmentsHash;

  const TabsRouterScope({
    required Widget child,
    required this.segmentsHash,
    required this.controller,
  }) : super(child: child);

  static TabsRouterScope? of(BuildContext context, {bool watch = false}) {
    if (watch) {
      return context.dependOnInheritedWidgetOfExactType<TabsRouterScope>();
    }
    return context.findAncestorWidgetOfExactType<TabsRouterScope>();
  }

  @override
  bool updateShouldNotify(covariant TabsRouterScope oldWidget) {
    return segmentsHash != oldWidget.segmentsHash;
  }
}
