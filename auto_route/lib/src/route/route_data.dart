part of '../router/controller/routing_controller.dart';

/// Holds final information of presented routes
/// That's consumed by [AutoRoutePage]
///
/// It's also scoped by [RouteDataScope] to be used by clients
/// e.g RouteData.of(context).name
///
/// It also tracks ancestors by taking in a parent-route
class RouteData<R> {
  /// Default constructor
  new({
    required RouteMatch<Object?> route,
    required this.router,
    required this.stackKey,
    required List<RouteMatch<Object?>> pendingChildren,
    required this.type,
    this._popCompleter,
    this._parent,
  }) : _route = route,
       _ownQueryParams = route.queryParams,
       _ownFragment = route.fragment,
       _pendingChildren = List.of(pendingChildren);
  RouteMatch<Object?> _route;
  RouteData<Object?>? _parent;
  final Completer<R?>? _popCompleter;

  // The [AutoRouteLeaveListener]s in this page, told when the page is left.
  final _leaveCallbacks = <RouteLeaveCallback>[];

  void _reportLeave(RouteLeaveKind kind) {
    for (final callback in List.of(_leaveCallbacks)) {
      callback(kind);
    }
  }

  /// The router this instance was created by
  final RoutingController router;

  /// The type of [PageRoute] this entity will be attached to
  ///
  /// This is ignored if [router] is a [TabsRouter]
  final RouteType type;

  /// The key used by [AutoRoutePage.canUpdate]
  ///
  /// This is ignored if [router] is a [TabsRouter]
  LocalKey get key => _route.key;

  /// The virtual stack-key this route is a part of
  ///
  /// Routes can only be updated if they have the same [key]
  /// and  the same stackKey
  ///
  /// Used inside of [AutoRoutePage.canUpdate]
  final Key stackKey;

  /// Builds page title that's passed to `_PageBasedCupertinoPageRoute.title`
  /// where it can be used by `CupertinoNavigationBar`
  ///
  /// it can also be used manually by calling [RouteData.title] inside widgets
  String Function(BuildContext context) get title =>
      _route.titleBuilder == null ? (_) => _route.name : (context) => _route.titleBuilder!(context, this);

  /// Builds a String value that that's passed to
  /// [AutoRoutePage.restorationId]
  ///
  /// It's [AutoRoute.restorationId], or the route name, and unique among the
  /// pages of [router]: the pages of a Navigator can't share a restoration
  /// id, so a second page with the same one gets '#1' appended, a third '#2'.
  @internal
  String get restorationId => _restorationId ?? _baseRestorationId;

  String get _baseRestorationId => _route.restorationId == null ? _route.name : _route.restorationId!(_route);

  // Assigned in routing_controller.dart, a part of this library.
  // ignore: avoid-unassigned-fields
  String? _restorationId;

  /// Whether is route is in the visible url-segments
  bool get isActive => router.isRouteActive(name);

  /// Whether this route has pending children
  bool get hasPendingChildren => _pendingChildren.isNotEmpty;

  List<RouteMatch<Object?>> _pendingChildren;

  /// The pre-matched sub-routes of this route
  ///
  /// These are consumed by the sub-router once it's created
  List<RouteMatch<Object?>> get pendingChildren => _pendingChildren;

  /// Looks up and returns the scoped instance
  ///
  /// throws an error if it does not find it
  static RouteData<Object?> of(BuildContext context) {
    return RouteDataScope.of(context).routeData;
  }

  /// The pop completer that's used in navigation actions
  /// e.g [StackRouter.push]
  /// it completes when the built route is popped
  Future<R?> get popped {
    if (router.ignorePopCompleters || _popCompleter == null) {
      return SynchronousFuture(null);
    }
    return _popCompleter.future;
  }

  /// Validates and returns [args] casted as [T]
  ///
  /// if args is null and [orElse] is null an error is thrown
  /// otherwise [orElse] is called and args are built by it
  T argsAs<T>({T Function()? orElse}) {
    final given = _route.args;
    if (given == null) {
      if (orElse == null) {
        final messages = ['$T can not be null because the corresponding page has a required parameter'];
        if (_route.autoFilled) {
          messages
            ..add('${_route.name} is an auto created ancestor of target route ${_route.flattened.last.name}')
            ..add(
              'This usually happens when you try to navigate to a route that is inside of a nested-router\nbefore adding the nested-router to the stack first',
            )
            ..add('try navigating to ${_route.flattened.map((e) => e.name).join(' -> ')}');
        }
        throw MissingRequiredParameterError('\n${messages.join('\n')}\n');
      }
      return orElse();
    } else if (given case final T typed) {
      return typed;
    }
    throw MissingRequiredParameterError('Expected [$T],  found [${given.runtimeType}]');
  }

  // The query params and fragment this route was opened with. A route pushed
  // on top shares its own with every route in the stack, so these are kept
  // apart to be shared again once that route is popped.
  Parameters _ownQueryParams;
  String _ownFragment;

  void _updateRoute(RouteMatch<Object?> value) {
    if (_route != value) {
      _route = value;
    }
  }

  /// Reruns the raw [RouteMatch]
  RouteMatch<Object?> get route => _route;

  /// Helper to access [RouteMatch.name]
  String get name => _route.name;

  /// Helper to access [RouteMatch.path]
  String get path => _route.path;

  /// Returns the parent [RouteData] of this instance
  ///
  /// Returns null if this is a root entry
  RouteData<Object?>? get parent => _parent;

  /// Helper to access [RouteMatch.meta]
  Map<String, Object?> get meta => _route.meta;

  /// Helper to access [RouteMatch.args]
  ///
  /// this method is unsafe prefer using [argsAs]
  // Null for a route pushed without args. The rule reads RouteMatch<Object?>'s args as never null.
  // ignore: avoid-unnecessary-nullable-return-type
  Object? get args => _route.args;

  /// Helper to access [RouteMatch.stringMatch]
  String get match => _route.stringMatch;

  /// Helper to access [RouteMatch.id]
  LocalKey get matchId => _route.id;

  /// The track to the very first ancestor match
  ///
  /// This can be used to render visual breadcrumbs in UI
  List<RouteMatch<Object?>> get breadcrumbs => .unmodifiable([...?_parent?.breadcrumbs, _route]);

  /// Collects all path params form all previous ancestors
  Parameters get inheritedPathParams {
    return breadcrumbs.map((e) => e.params).reduce((value, element) => value + element);
  }

  /// Helper to access [RouteMatch.params]
  Parameters get params => _route.params;

  /// Helper to access [RouteMatch.queryParams]
  Parameters get queryParams => _route.queryParams;

  /// Helper to access [RouteMatch.fragment]
  String get fragment => _route.fragment;

  RouteMatch<Object?> _getTopMatch(RouteMatch<Object?> routeMatch) {
    if (routeMatch.children case [..., final last]) {
      return _getTopMatch(last);
    }
    return routeMatch;
  }

  /// Returns the top most [RouteMatch] in the
  /// pending children, if it has not pending children
  /// this [route] is returned
  RouteMatch<Object?> get topMatch {
    if (pendingChildren case [..., final last]) {
      return _getTopMatch(last);
    }
    return route;
  }

  /// Builds the [AutoRoutePage] page
  AutoRoutePage<T> buildPage<T>() {
    return _route.buildPage(this);
  }

  // Set while a guard reevaluates this route; kept for debugging.
  // ignore: unused_field
  bool _isReevaluating = false;

  void _onStartReevaluating(RouteMatch<Object?> newMatch) {
    _isReevaluating = true;
    _updateRoute(newMatch);
    _ownQueryParams = newMatch.queryParams;
    _ownFragment = newMatch.fragment;
    _pendingChildren = List<RouteMatch<Object?>>.from(newMatch.children ?? []);
  }

  void _onEndReevaluating() {
    _isReevaluating = false;
  }

  bool _isPoppedByNavigator = false;

  /// Records that the navigator popped this route's page, e.g. through
  /// [StackRouter.pop] or the back button, rather than the router removing it.
  ///
  /// A guard reevaluation that collected the stack before the pop does not
  /// add the page back.
  @internal
  void onPoppedByNavigator() {
    _isPoppedByNavigator = true;
    if ((router, animation) case (final StackRouter stackRouter, final leaving?)) {
      stackRouter._addLeavingAnimation(leaving);
    }
  }

  /// Completes the pop completer with the given result
  void onPopInvoked(R? result) {
    if (router.ignorePopCompleters) {
      // if pop completers are ignored then we don't complete the pop completer
      return;
    }
    if (_popCompleter != null && !_popCompleter.isCompleted) {
      _popCompleter.complete(result);
    }
  }

  /// The animation of the [Route] that shows this page, or null before the
  /// route is built.
  ///
  /// The page's route sets it when it builds, as does the page of a route
  /// built by [CustomRouteType.customRouteBuilder]; [animationCompletion] and
  /// [RoutingController.waitForTransitions] read it.
  Animation<Object?>? animation;

  /// Sets [animation].
  // Deprecated in 12.0.0, removed in 13.0.0.
  @Deprecated('Set animation instead')
  // The old name, kept as a method so existing calls still compile until it is removed.
  // ignore: use_setters_to_change_properties
  void setAnimation(Animation<Object?>? value) => animation = value;

  /// Returns the current animation completion future
  /// if the current route is animating
  ///
  /// If the current route is not animating, it returns null
  Future<void>? get animationCompletion {
    if (animation case final running?) {
      if (running.isAnimating) {
        // if the current route is animating, we wait for it to complete
        final completer = Completer<void>();
        void listener(AnimationStatus _) {
          if (!running.isAnimating) {
            completer.complete();
            running.removeStatusListener(listener);
          }
        }

        running.addStatusListener(listener);
        return completer.future;
      }
    }
    return null;
  }
}
