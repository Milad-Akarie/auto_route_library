import 'dart:async';

import 'package:auto_route/src/router/parser/route_information_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The route information provider that propagates the platform route information changes.
///
/// This provider also reports the new route information from the [Router] widget
/// back to engine using message channel method, the
/// [SystemNavigator.routeInformationUpdated].
///
/// Each time [SystemNavigator.routeInformationUpdated] is called, the
/// [SystemNavigator.selectMultiEntryHistory] method is also called. This
/// overrides the initialization behavior of
/// [Navigator.reportsRouteUpdateToEngine].
class AutoRouteInformationProvider extends RouteInformationProvider with WidgetsBindingObserver, ChangeNotifier {
  /// Create a platform route information provider.
  ///
  /// Use the [initialRouteInformation] to set the default route information for this
  /// provider.
  factory AutoRouteInformationProvider({
    RouteInformation? initialRouteInformation,
    bool Function(String? location)? neglectWhen,
  }) {
    final initialRouteInfo =
        initialRouteInformation ??
        RouteInformation(uri: Uri.parse(WidgetsBinding.instance.platformDispatcher.defaultRouteName));

    return AutoRouteInformationProvider._(initialRouteInformation: initialRouteInfo, neglectIf: neglectWhen);
  }
  AutoRouteInformationProvider._({required RouteInformation initialRouteInformation, this.neglectIf})
    : _value = initialRouteInformation;

  /// if true is return the route will be
  /// reported to engine
  bool Function(String? location)? neglectIf;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = .none,
  }) {
    if (neglectIf != null && neglectIf!(routeInformation.uri.toString())) {
      return;
    }

    // On web DefaultRouteParser hands over the uri escaped for the engine;
    // compare and keep the app's own uri, and escape one that skipped it.
    final appRouteInformation = routeInformation is AutoRouteInformation && routeInformation.appUri != null
        ? RouteInformation(uri: routeInformation.appUri, state: routeInformation.state)
        : routeInformation;
    final reportedUri = identical(appRouteInformation, routeInformation) && kIsWeb
        ? escapeForWebEngine(routeInformation.uri)
        : routeInformation.uri;

    // The routes saved for state restoration stay with the Router.
    final state = UrlState.platformState(routeInformation.state);
    var replace =
        type == .neglect ||
        (type == .none &&
            _valueInEngine.uri == appRouteInformation.uri &&
            UrlState.platformState(_valueInEngine.state) == state);

    if (!replace && routeInformation is AutoRouteInformation) {
      replace = routeInformation.replace;
    }
    unawaited(SystemNavigator.selectMultiEntryHistory());
    unawaited(SystemNavigator.routeInformationUpdated(uri: reportedUri, state: state, replace: replace));
    _value = appRouteInformation;
    _valueInEngine = appRouteInformation;
  }

  @override
  RouteInformation get value => _value;
  RouteInformation _value;

  RouteInformation _valueInEngine = RouteInformation(
    uri: Uri.parse(WidgetsBinding.instance.platformDispatcher.defaultRouteName),
  );

  void _platformReportsNewRouteInformation(RouteInformation routeInformation) {
    if (_value == routeInformation) return;
    _value = routeInformation;
    _valueInEngine = routeInformation;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) WidgetsBinding.instance.addObserver(this);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void dispose() {
    // In practice, this will rarely be called. We assume that the listeners
    // will be added and removed in a coherent fashion such that when the object
    // is no longer being used, there's no listener, and so it will get garbage
    // collected.
    if (hasListeners) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    assert(hasListeners, 'The route information provider has no listener to report to.');
    _platformReportsNewRouteInformation(routeInformation);
    return SynchronousFuture<bool>(true);
  }
}
