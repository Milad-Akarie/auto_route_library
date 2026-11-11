part of 'routing_controller.dart';

/// Calls [onLeave] each time the page this widget sits in is left, with how
/// it was left.
///
/// Guards run when a page is entered and [PopScope] decides whether a pop may
/// happen; this widget tells a page that it is being left, by any way, and
/// which way. Use it to save a draft when the page is covered, to log a
/// screen exit, or to tell a back from a navigation elsewhere, as
/// "ask before discarding on back, save silently on navigate" needs.
///
/// Each leave is reported once, right when the router's stack changes: a pop
/// as the page starts its exit animation, while this widget is still mounted.
/// To block a pop, wrap the page in a [PopScope] that refuses it; a refused
/// pop is never reported. Leaves other than pops come from the app's own
/// calls, so the app decides whether to make them; a guard on the route
/// being opened can also stop them.
///
/// It reports the changes of the stack of the router that shows its page.
/// When a nested router goes away with its parent page, the listener in the
/// parent page hears of it, not one in the nested pages. In a router built by
/// [AutoRouter.declarative] only pops are reported, since the app's list
/// decides the pages. Switching tabs is not a leave; [AutoRouteAware] reports
/// tab changes.
///
/// ```dart
/// AutoRouteLeaveListener(
///   onLeave: (kind) {
///     if (kind == RouteLeaveKind.covered) draft.save();
///   },
///   child: const EditorForm(),
/// )
/// ```
class AutoRouteLeaveListener extends StatefulWidget {
  /// Listens for leaves of the page whose [RouteData] is closest above this
  /// widget; throws if there is none.
  const new({required this.onLeave, required this.child, super.key});

  /// Called with how the page was left, synchronously while the router
  /// updates its stack.
  ///
  /// A pop is reported while the navigator updates its routes, so a
  /// navigation in response is started after the frame, as with
  /// [SchedulerBinding.addPostFrameCallback].
  final RouteLeaveCallback onLeave;

  /// The page content, built as it is.
  final Widget child;

  @override
  State<AutoRouteLeaveListener> createState() => _AutoRouteLeaveListenerState();
}

class _AutoRouteLeaveListenerState extends State<AutoRouteLeaveListener> {
  RouteData<Object?>? _routeData;

  void _onLeave(RouteLeaveKind kind) => widget.onLeave(kind);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeData = RouteData.of(context);
    if (routeData == _routeData) return;
    _routeData?._leaveCallbacks.remove(_onLeave);
    _routeData = routeData.._leaveCallbacks.add(_onLeave);
  }

  @override
  void dispose() {
    _routeData?._leaveCallbacks.remove(_onLeave);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// How the user, or the app, left a page.
///
/// [AutoRouteLeaveListener] reports one of these each time the page it sits
/// in stops being the top page of its router.
enum RouteLeaveKind {
  /// The page was popped: by the back button, system back, a back swipe, the
  /// browser's back button, or a call such as [StackRouter.pop],
  /// [StackRouter.maybePop] or [StackRouter.popUntil].
  ///
  /// The only kind an app can block: a [PopScope] that refuses the pop keeps
  /// the page, and nothing is reported.
  popped,

  /// A page was pushed over this one, which stays in the stack under it.
  ///
  /// The page is on top again once the pages over it are popped, and is
  /// reported again if another page covers it later.
  covered,

  /// The page was taken off the stack for the page that took its place, by
  /// [StackRouter.replace], [StackRouter.replaceAll],
  /// [StackRouter.pushAndPopUntil] or a push over a route with
  /// `keepHistory: false`.
  replaced,

  /// The page was taken off the stack without a pop: by a navigation to a
  /// page below it or elsewhere, such as [RoutingController.navigate] or a
  /// deep link, by [StackRouter.removeRoute], [StackRouter.removeWhere],
  /// [StackRouter.removeUntil] or [StackRouter.removeLast], or by a guard
  /// that closes it when the guards are reevaluated.
  removed,
}

/// Signature of [AutoRouteLeaveListener.onLeave]: [kind] says how the page
/// was left.
typedef RouteLeaveCallback = void Function(RouteLeaveKind kind);
