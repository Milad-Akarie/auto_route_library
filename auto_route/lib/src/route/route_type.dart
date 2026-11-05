import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// Signature for custom router builder used by
/// [CustomRouteType]
typedef CustomRouteBuilder = Route<T> Function<T>(BuildContext context, Widget child, AutoRoutePage<T> page);

/// An abstraction of route types used by
/// [AutoRoutePage.onCreateRoute] to decide transition animations
@immutable
abstract class RouteType {
  /// Builds a [MaterialRouteType] route type
  const factory material({
    bool enablePredictiveBackGesture,
    RouteTransitionsBuilder? predictiveBackPageTransitionsBuilder,
  }) = MaterialRouteType;

  /// Builds a [CupertinoRouteType] route type
  const factory cupertino() = CupertinoRouteType;

  /// Builds a [AdaptiveRouteType] route type
  const factory adaptive({
    bool opaque,
    bool enablePredictiveBackGesture,
    RouteTransitionsBuilder? predictiveBackPageTransitionsBuilder,
  }) = AdaptiveRouteType;

  /// Builds a [CustomRouteType] route type
  factory custom({
    RouteTransitionsBuilder? transitionsBuilder,
    CustomRouteBuilder? customRouteBuilder,
    Duration? duration,
    Duration? reverseDuration,
    bool opaque,
    bool barrierDismissible,
    String? barrierLabel,
    Color? barrierColor,
    bool enablePredictiveBackGesture,
    RouteTransitionsBuilder? predictiveBackPageTransitionsBuilder,
    bool enableCupertinoBackGesture,
  }) = CustomRouteType;
  const new _({this.opaque = true});

  /// Whether the target [Route] should be opaque
  /// see [ModalRoute.opaque]
  final bool opaque;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RouteType && runtimeType == other.runtimeType && opaque == other.opaque;

  @override
  int get hashCode => opaque.hashCode;
}

/// Generates a route that uses [MaterialRouteTransitionMixin]
class MaterialRouteType extends RouteType with PredictiveBackGestureMixin {
  /// Default constructor
  const new({this.enablePredictiveBackGesture = false, this.predictiveBackPageTransitionsBuilder})
    : super._(opaque: true);

  @override
  final bool enablePredictiveBackGesture;

  @override
  final RouteTransitionsBuilder? predictiveBackPageTransitionsBuilder;
}

/// Generates a route that uses `CupertinoRouteTransitionMixin`
class CupertinoRouteType extends RouteType {
  /// Default constructor
  const new() : super._(opaque: true);
}

/// Generates a route transitions based on platform
///
/// ios,macos => `CupertinoRouteTransitionMixin`
/// web => NoTransition
/// any other platform => [MaterialRouteTransitionMixin]
class AdaptiveRouteType extends RouteType with PredictiveBackGestureMixin {
  /// Default constructor
  const new({this.enablePredictiveBackGesture = false, this.predictiveBackPageTransitionsBuilder, super.opaque})
    : super._();

  @override
  final bool enablePredictiveBackGesture;

  @override
  final RouteTransitionsBuilder? predictiveBackPageTransitionsBuilder;
}

/// Generates a route with user-defined transitions
class CustomRouteType extends RouteType with PredictiveBackGestureMixin {
  /// Default constructor
  new({
    this.customRouteBuilder,
    this.barrierLabel,
    this.barrierColor,
    this.transitionsBuilder,
    super.opaque,
    this.barrierDismissible = false,
    this.enablePredictiveBackGesture = false,
    this.predictiveBackPageTransitionsBuilder,
    this.enableCupertinoBackGesture = false,
    this.duration,
    this.reverseDuration,
  }) : super._();

  /// this builder function is passed to the transition builder
  /// function in [PageRouteBuilder]
  ///
  /// I couldn't type this function from here but it should match
  /// typedef [RouteTransitionsBuilder] = Widget Function(BuildContext context, Animation&lt;double&gt; animation,
  /// Animation&lt;double&gt; secondaryAnimation, Widget child);
  ///
  /// you should only reference the function so
  /// the generator can import it into the generated file
  ///
  /// see [PageRouteBuilder.transitionsBuilder] for more details
  final RouteTransitionsBuilder? transitionsBuilder;

  /// this builder function is passed to customRouteBuilder property
  /// in `CustomPage`
  ///
  /// I couldn't type this function from here but it should match
  /// typedef [CustomRouteBuilder] = Route Function(BuildContext context, CustomPage page);
  ///
  /// this builder function accepts a BuildContext and a CustomPage
  /// that has all the other properties assigned to it
  /// so using them then is totally up to you.
  ///
  /// Make sure you pass the Return Type &lt;T&gt; to the Route&lt;T&gt; function
  /// ex:
  ///  CustomRoute(
  ///     path: '/user/:userID',
  ///     page: UserRoute.page,
  ///     customRouteBuilder: &lt;T&gt;(context, child, page) {
  ///     return PageRouteBuilder&lt;T&gt;(
  ///     settings: page,
  ///     pageBuilder: (context, _, __) => child,
  ///   );
  ///  },
  final CustomRouteBuilder? customRouteBuilder;

  /// route transition duration
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a `transitionBuilder` is provided
  final Duration? duration;

  /// route reverse transition duration
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a `transitionBuilder` is provided
  final Duration? reverseDuration;

  /// passed to the barrierDismissible property in [PageRouteBuilder]
  ///
  /// see [PageRouteBuilder.barrierDismissible] for more details
  final bool barrierDismissible;

  /// passed to the barrierLabel property in [PageRouteBuilder]
  ///
  /// see [PageRouteBuilder.barrierLabel] for more details
  final String? barrierLabel;

  /// passed to the barrierColor property in [PageRouteBuilder]
  ///
  /// see [PageRouteBuilder.barrierColor] for more details
  final Color? barrierColor;

  @override
  final bool enablePredictiveBackGesture;

  @override
  final RouteTransitionsBuilder? predictiveBackPageTransitionsBuilder;

  /// Whether the user can swipe from the screen's leading edge to go back on
  /// iOS and macOS, as on a [CupertinoRouteType] page.
  ///
  /// The page follows the finger through its own [transitionsBuilder], run
  /// backwards, and is popped when let go past the middle or flung. Off iOS
  /// and macOS, by the platform of the app's [Theme], this does nothing.
  /// Neither does it for a [PageRoute.fullscreenDialog], which iOS closes by
  /// its own button, or for a route built by [customRouteBuilder].
  ///
  /// Defaults to false: a custom transition has no back swipe unless it opts
  /// in.
  final bool enableCupertinoBackGesture;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is CustomRouteType &&
          runtimeType == other.runtimeType &&
          transitionsBuilder == other.transitionsBuilder &&
          customRouteBuilder == other.customRouteBuilder &&
          duration == other.duration &&
          reverseDuration == other.reverseDuration &&
          barrierDismissible == other.barrierDismissible &&
          barrierLabel == other.barrierLabel &&
          barrierColor == other.barrierColor &&
          enableCupertinoBackGesture == other.enableCupertinoBackGesture;

  @override
  int get hashCode =>
      super.hashCode ^
      transitionsBuilder.hashCode ^
      customRouteBuilder.hashCode ^
      duration.hashCode ^
      reverseDuration.hashCode ^
      barrierDismissible.hashCode ^
      barrierLabel.hashCode ^
      barrierColor.hashCode ^
      enableCupertinoBackGesture.hashCode;
}

/// A mixin that allows you to configure predictive back gesture for a route
mixin PredictiveBackGestureMixin {
  /// Whether to enable predictive back gesture on Android
  ///
  /// Make sure your app supports Android API 33 or higher, as predictive back won't work on older versions of Android.
  /// Then, set the flag android:enableOnBackInvokedCallback="true" in android/app/src/main/AndroidManifest.xml.
  /// read more here https://docs.flutter.dev/platform-integration/android/predictive-back
  ///
  /// make sure to also opt-in into this feature in your device settings
  /// Settings => System => Developer => Predictive back animations
  ///
  /// defaults to false
  bool get enablePredictiveBackGesture;

  /// The transitions builder to use for when the predictive back gesture is in progress
  RouteTransitionsBuilder? get predictiveBackPageTransitionsBuilder;
}
