part of '../auto_route_page.dart';

/// This is the exact copy of the original file from the flutter repository

typedef _PredictiveBackGestureDetectorWidgetBuilder = Widget Function(
  BuildContext context,
  _PredictiveBackPhase phase,
  PredictiveBackEvent? startBackEvent,
  PredictiveBackEvent? currentBackEvent,
);

/// The phases of a predictive back gesture.
enum _PredictiveBackPhase {
  /// There is no active predictive back gesture in progress.
  idle,

  /// The user pointer has contacted the screen.
  start,

  /// The user pointer has moved.
  update,

  /// The user pointer has released in a position in which Android has
  /// determined that the back gesture is successful and the current route
  /// should be popped.
  commit,

  /// The user pointer has released in a position in which Android has
  /// determined that the back gesture should be canceled and the original route
  /// should be shown.
  cancel,
}

class _PredictiveBackGestureDetector extends StatefulWidget {
  const new({required this.route, required this.builder});

  final _PredictiveBackGestureDetectorWidgetBuilder builder;
  final PageRoute<Object?> route;

  @override
  State<_PredictiveBackGestureDetector> createState() =>
      _PredictiveBackGestureDetectorState();
}

class _PredictiveBackGestureDetectorState
    extends State<_PredictiveBackGestureDetector>
    with WidgetsBindingObserver {
  /// True when the predictive back gesture is enabled.
  bool get _isEnabled {
    return widget.route.isCurrent && widget.route.popGestureEnabled;
  }

  _PredictiveBackPhase get phase => _phase;
  _PredictiveBackPhase _phase = .idle;
  set phase(_PredictiveBackPhase value) {
    if (_phase != value && mounted) {
      setState(() => _phase = value);
    }
  }

  /// The back event when the gesture first started.
  PredictiveBackEvent? get startBackEvent => _startBackEvent;
  PredictiveBackEvent? _startBackEvent;
  set startBackEvent(PredictiveBackEvent? value) {
    if (_startBackEvent != value && mounted) {
      setState(() => _startBackEvent = value);
    }
  }

  /// The most recent back event during the gesture.
  PredictiveBackEvent? get currentBackEvent => _currentBackEvent;
  PredictiveBackEvent? _currentBackEvent;
  set currentBackEvent(PredictiveBackEvent? value) {
    if (_currentBackEvent != value && mounted) {
      setState(() => _currentBackEvent = value);
    }
  }

  // Begin WidgetsBindingObserver.

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    phase = .start;
    final gestureInProgress = !backEvent.isButtonEvent && _isEnabled;
    if (!gestureInProgress) {
      return false;
    }

    widget.route.handleStartBackGesture(progress: 1 - backEvent.progress);
    startBackEvent = backEvent;
    currentBackEvent = backEvent;
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    phase = .update;

    widget.route.handleUpdateBackGestureProgress(
      progress: 1 - backEvent.progress,
    );
    currentBackEvent = backEvent;
  }

  @override
  void handleCancelBackGesture() {
    phase = .cancel;

    widget.route.handleCancelBackGesture();
    startBackEvent = null;
    currentBackEvent = null;
  }

  @override
  void handleCommitBackGesture() {
    phase = .commit;
    widget.route.handleCommitBackGesture();
    startBackEvent = null;
    currentBackEvent = null;
  }

  // End WidgetsBindingObserver.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectivePhase = widget.route.popGestureInProgress
        ? phase
        : _PredictiveBackPhase.idle;
    return widget.builder(
      context,
      effectivePhase,
      startBackEvent,
      currentBackEvent,
    );
  }
}
