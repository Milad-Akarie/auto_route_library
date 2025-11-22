part of '../router/controller/routing_controller.dart';

/// Holds final information of presented routes
/// That's consumed by [AutoRoutePage]
///
/// It's also scoped by [RouteDataScope] to be used by clients
/// e.g RouteData.of(context).name
///
/// It also tracks ancestors by taking in a parent-route
class RouteData<R> {
  RouteMatch _match;
  RouteData? _parent;
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

  /// Default constructor
  RouteData({
    required RouteMatch route,
    required this.router,
    Completer<R?>? popCompleter,
    RouteData? parent,
    required this.stackKey,
    required List<RouteMatch> pendingChildren,
    required this.type,
  })  : _match = route,
        _popCompleter = popCompleter,
        _parent = parent,
        _pendingChildren = List<RouteMatch>.from(pendingChildren);

  /// Builds page title that's passed to [_PageBasedCupertinoPageRoute.title]
  /// where it can be used by [CupertinoNavigationBar]
  ///
  /// it can also be used manually by calling [RouteData.title] inside widgets
  String Function(BuildContext context) get title =>
      _match.titleBuilder == null ? (_) => _match.name : (context) => _match.titleBuilder!(context, this);

  /// Builds a String value that that's passed to
  /// [AutoRoutePage.restorationId]
  @internal
  String get restorationId => _match.restorationId == null ? _match.name : _match.restorationId!(_match);

  /// Whether is route is in the visible url-segments
  bool get isActive => router.isRouteActive(name);

  /// Whether this route has pending children
  bool get hasPendingChildren => _pendingChildren.isNotEmpty;

  List<RouteMatch> _pendingChildren;

  /// The pre-matched sub-routes of this route
  ///
  /// These are consumed by the sub-router once it's created
  List<RouteMatch> get pendingChildren => _pendingChildren;

  /// Looks up and returns the scoped instance
  ///
  /// throws an error if it does not find it
  static RouteData of(BuildContext context) {
    return RouteDataScope.of(context).routeData;
  }

  /// The pop completer that's used in navigation actions
  /// e.g [StackRouter.push]
  /// it completes when the built route is popped
  Future<R?> get popped {
    if (router.ignorePopCompleters || _popCompleter == null) {
      return SynchronousFuture(null);
    } else {
      return _popCompleter!.future;
    }
  }

  /// Validates and returns [args] casted as [T]
  ///
  /// if args is null and [orElse] is null an error is thrown
  /// otherwise [orElse] is called and args are built by it
  T argsAs<T>({T Function()? orElse}) {
    final args = _match.args;
    if (args == null) {
      if (orElse == null) {
        final messages = ['${T.toString()} can not be null because the corresponding page has a required parameter'];
        if (_match.autoFilled) {
          messages.add('${_match.name} is an auto created ancestor of target route ${_match.flattened.last.name}');
          messages.add(
              'This usually happens when you try to navigate to a route that is inside of a nested-router\nbefore adding the nested-router to the stack first');
          messages.add('try navigating to ${_match.flattened.map((e) => e.name).join(' -> ')}');
        }
        throw MissingRequiredParameterError('\n${messages.join('\n')}\n');
      } else {
        return orElse();
      }
    } else if (args is! T) {
      throw MissingRequiredParameterError('Expected [${T.toString()}],  found [${args.runtimeType}]');
    } else {
      return args;
    }
  }

  void _updateRoute(RouteMatch value) {
    if (_match != value) {
      _match = value;
    }
  }

  void _updateParentData(RouteData value) {
    _parent = value;
  }

  /// Reruns the raw [RouteMatch]
  RouteMatch get route => _match;

  /// Helper to access [RouteMatch.name]
  String get name => _match.name;

  /// Helper to access [RouteMatch.path]
  String get path => _match.path;

  /// Returns the parent [RouteData] of this instance
  ///
  /// Returns null if this is a root entry
  RouteData? get parent => _parent;

  /// Helper to access [RouteMatch.meta]
  Map<String, dynamic> get meta => _match.meta;

  /// Helper to access [RouteMatch.args]
  ///
  /// this method is unsafe prefer using [argsAs]
  Object? get args => _match.args;

  /// Helper to access [RouteMatch.stringMatch]
  String get match => _match.stringMatch;

  /// Helper to access [RouteMatch.id]
  LocalKey get matchId => _match.id;

  /// The track to the very first ancestor match
  ///
  /// This can be used to render visual breadcrumbs in UI
  List<RouteMatch> get breadcrumbs => List.unmodifiable([
        if (_parent != null) ..._parent!.breadcrumbs,
        _match,
      ]);

  /// Collects all path params form all previous ancestors
  Parameters get inheritedPathParams {
    final params = breadcrumbs.map((e) => e.params).reduce(
          (value, element) => value + element,
        );
    return params;
  }

  /// Helper to access [RouteMatch.params]
  @Deprecated('use the shorthand (params) instead')
  Parameters get pathParams => _match.params;

  /// Helper to access [RouteMatch.params]
  Parameters get params => _match.params;

  /// Helper to access [RouteMatch.queryParams]
  Parameters get queryParams => _match.queryParams;

  /// Helper to access [RouteMatch.fragment]
  String get fragment => _match.fragment;

  RouteMatch _getTopMatch(RouteMatch routeMatch) {
    if (routeMatch.hasChildren) {
      return _getTopMatch(routeMatch.children!.last);
    } else {
      return routeMatch;
    }
  }

  /// Returns the top most [RouteMatch] in the
  /// pending children, if it has not pending children
  /// this [_match] is returned
  RouteMatch get topMatch {
    if (hasPendingChildren) {
      return _getTopMatch(pendingChildren.last);
    }
    return _match;
  }

  /// Builds the [AutoRoutePage] page
  AutoRoutePage<T> buildPage<T>() {
    return _match.buildPage<T>(this);
  }

  // ignore: unused_field
  bool _isReevaluating = false;

  void _onStartReevaluating(RouteMatch newMatch) {
    _isReevaluating = true;
    _updateRoute(newMatch);
    _pendingChildren = newMatch.children ?? [];
  }

  void _onEndReevaluating(RouteMatch newMatch) {
    _isReevaluating = false;
  }

  /// Completes the pop completer with the given result
  void onPopInvoked(R? result) {
    if (router.ignorePopCompleters) {
      // if pop completers are ignored then we don't complete the pop completer
      return;
    }
    if (_popCompleter != null && !_popCompleter!.isCompleted) {
      _popCompleter?.complete(result);
    }
  }

  Animation<dynamic>? _animation;

  /// The main animation that is used by the Route
  void setAnimation(Animation<dynamic>? animation) {
    _animation = animation;
  }

  /// Returns the current animation completion future
  /// if the current route is animating
  ///
  /// If the current route is not animating, it returns null
  Future<void>? get animationCompletion {
    if (_animation case final animation?) {
      if (animation.isAnimating) {
        // if the current route is animating, we wait for it to complete
        final completer = Completer<void>();
        void listener(AnimationStatus status) {
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
