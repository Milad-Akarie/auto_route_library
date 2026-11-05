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
  RouteData({
    required RouteMatch<dynamic> route,
    required this.router,
    this._popCompleter,
    this._parent,
    required this.stackKey,
    required List<RouteMatch<dynamic>> pendingChildren,
    required this.type,
  }) : _match = route,
       _ownQueryParams = route.queryParams,
       _ownFragment = route.fragment,
       _pendingChildren = List<RouteMatch<dynamic>>.of(pendingChildren);
  RouteMatch<dynamic> _match;
  RouteData<dynamic>? _parent;
  final Completer<R?>? _popCompleter;

  /// The router this instance was created by
  final RoutingController router;

  /// The type of [PageRoute] this entity will be attached to
  ///
  /// This is ignored if [router] is a [TabsRouter]
  final RouteType type;

  /// The key used by [AutoRoutePage.canUpdate]
  ///
  /// This is ignored if [router] is a [TabsRouter]
  LocalKey get key => _match.key;

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
      _match.titleBuilder == null ? (_) => _match.name : (context) => _match.titleBuilder!(context, this);

  /// Builds a String value that that's passed to
  /// [AutoRoutePage.restorationId]
  ///
  /// It's [AutoRoute.restorationId], or the route name, and unique among the
  /// pages of [router]: the pages of a Navigator can't share a restoration
  /// id, so a second page with the same one gets '#1' appended, a third '#2'.
  @internal
  String get restorationId => _restorationId ?? _baseRestorationId;

  String get _baseRestorationId => _match.restorationId == null ? _match.name : _match.restorationId!(_match);

  // Assigned in routing_controller.dart, a part of this library.
  // ignore: avoid-unassigned-fields
  String? _restorationId;

  /// Whether is route is in the visible url-segments
  bool get isActive => router.isRouteActive(name);

  /// Whether this route has pending children
  bool get hasPendingChildren => _pendingChildren.isNotEmpty;

  List<RouteMatch<dynamic>> _pendingChildren;

  /// The pre-matched sub-routes of this route
  ///
  /// These are consumed by the sub-router once it's created
  List<RouteMatch<dynamic>> get pendingChildren => _pendingChildren;

  /// Looks up and returns the scoped instance
  ///
  /// throws an error if it does not find it
  static RouteData<dynamic> of(BuildContext context) {
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
    final args = _match.args;
    if (args == null) {
      if (orElse == null) {
        final messages = ['$T can not be null because the corresponding page has a required parameter'];
        if (_match.autoFilled) {
          messages.add('${_match.name} is an auto created ancestor of target route ${_match.flattened.last.name}');
          messages.add(
            'This usually happens when you try to navigate to a route that is inside of a nested-router\nbefore adding the nested-router to the stack first',
          );
          messages.add('try navigating to ${_match.flattened.map((e) => e.name).join(' -> ')}');
        }
        throw MissingRequiredParameterError('\n${messages.join('\n')}\n');
      }
      return orElse();
    } else if (args is! T) {
      throw MissingRequiredParameterError('Expected [$T],  found [${args.runtimeType}]');
    }
    return args;
  }

  // The query params and fragment this route was opened with. A route pushed
  // on top shares its own with every route in the stack, so these are kept
  // apart to be shared again once that route is popped.
  Parameters _ownQueryParams;
  String _ownFragment;

  void _updateRoute(RouteMatch<dynamic> value) {
    if (_match != value) {
      _match = value;
    }
  }

  /// Reruns the raw [RouteMatch]
  RouteMatch<dynamic> get route => _match;

  /// Helper to access [RouteMatch.name]
  String get name => _match.name;

  /// Helper to access [RouteMatch.path]
  String get path => _match.path;

  /// Returns the parent [RouteData] of this instance
  ///
  /// Returns null if this is a root entry
  RouteData<dynamic>? get parent => _parent;

  /// Helper to access [RouteMatch.meta]
  Map<String, dynamic> get meta => _match.meta;

  /// Helper to access [RouteMatch.args]
  ///
  /// this method is unsafe prefer using [argsAs]
  // Null for a route pushed without args. The rule reads RouteMatch<dynamic>'s args as never null.
  // ignore: avoid-unnecessary-nullable-return-type
  Object? get args => _match.args;

  /// Helper to access [RouteMatch.stringMatch]
  String get match => _match.stringMatch;

  /// Helper to access [RouteMatch.id]
  LocalKey get matchId => _match.id;

  /// The track to the very first ancestor match
  ///
  /// This can be used to render visual breadcrumbs in UI
  List<RouteMatch<dynamic>> get breadcrumbs => .unmodifiable([if (_parent != null) ..._parent!.breadcrumbs, _match]);

  /// Collects all path params form all previous ancestors
  Parameters get inheritedPathParams {
    final params = breadcrumbs.map((e) => e.params).reduce((value, element) => value + element);
    return params;
  }

  /// Helper to access [RouteMatch.params]
  Parameters get params => _match.params;

  /// Helper to access [RouteMatch.queryParams]
  Parameters get queryParams => _match.queryParams;

  /// Helper to access [RouteMatch.fragment]
  String get fragment => _match.fragment;

  RouteMatch<dynamic> _getTopMatch(RouteMatch<dynamic> routeMatch) {
    if (routeMatch.hasChildren) {
      return _getTopMatch(routeMatch.children!.last);
    }
    return routeMatch;
  }

  /// Returns the top most [RouteMatch] in the
  /// pending children, if it has not pending children
  /// this [_match] is returned
  RouteMatch<dynamic> get topMatch {
    if (hasPendingChildren) {
      return _getTopMatch(pendingChildren.last);
    }
    return _match;
  }

  /// Builds the [AutoRoutePage] page
  AutoRoutePage<T> buildPage<T>() {
    return _match.buildPage<T>(this);
  }

  // Set while a guard reevaluates this route; kept for debugging.
  // ignore: unused_field
  bool _isReevaluating = false;

  void _onStartReevaluating(RouteMatch<dynamic> newMatch) {
    _isReevaluating = true;
    _updateRoute(newMatch);
    _ownQueryParams = newMatch.queryParams;
    _ownFragment = newMatch.fragment;
    _pendingChildren = List<RouteMatch<dynamic>>.from(newMatch.children ?? []);
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
  void onPoppedByNavigator() => _isPoppedByNavigator = true;

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
  /// The page's route sets it when it builds; [animationCompletion] reads it.
  Animation<dynamic>? animation;

  /// Sets [animation].
  @Deprecated('Set animation instead')
  // The old name, kept as a method so existing calls still compile until it is removed.
  // ignore: use_setters_to_change_properties
  void setAnimation(Animation<dynamic>? animation) => this.animation = animation;

  /// Returns the current animation completion future
  /// if the current route is animating
  ///
  /// If the current route is not animating, it returns null
  Future<void>? get animationCompletion {
    if (animation case final animation?) {
      if (animation.isAnimating) {
        // if the current route is animating, we wait for it to complete
        final completer = Completer<void>();
        void listener(AnimationStatus _) {
          if (!animation.isAnimating) {
            completer.complete();
            animation.removeStatusListener(listener);
          }
        }

        animation.addStatusListener(listener);
        return completer.future;
      }
    }
    return null;
  }
}
