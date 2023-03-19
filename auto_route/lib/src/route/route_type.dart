import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

typedef CustomRouteBuilder = Route<T> Function<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<T> page,
);

abstract class RouteType {
  const RouteType._({this.opaque = true});

  final bool opaque;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteType &&
          runtimeType == other.runtimeType &&
          opaque == other.opaque;

  @override
  int get hashCode => opaque.hashCode;

  const factory RouteType.material() = MaterialRouteType;

  const factory RouteType.cupertino() = CupertinoRouteType;

  const factory RouteType.adaptive({bool opaque}) = AdaptiveRouteType;

  const factory RouteType.custom({
    RouteTransitionsBuilder? transitionsBuilder,
    CustomRouteBuilder? customRouteBuilder,
    int? durationInMilliseconds,
    int? reverseDurationInMilliseconds,
    bool opaque,
    bool barrierDismissible,
    String? barrierLabel,
    Color? barrierColor,
  }) = CustomRouteType;
}

class MaterialRouteType extends RouteType {
  const MaterialRouteType({super.opaque}) : super._();
}

class CupertinoRouteType extends RouteType {
  const CupertinoRouteType({super.opaque}) : super._();
}

class AdaptiveRouteType extends RouteType {
  const AdaptiveRouteType({super.opaque}) : super._();
}

class CustomRouteType extends RouteType {
  /// this builder function is passed to the transition builder
  /// function in [PageRouteBuilder]
  ///
  /// I couldn't type this function from here but it should match
  /// typedef [RouteTransitionsBuilder] = Widget Function(BuildContext context, Animation<double> animation,
  /// Animation<double> secondaryAnimation, Widget child);
  ///
  /// you should only reference the function so
  /// the generator can import it into the generated file
  final RouteTransitionsBuilder? transitionsBuilder;

  /// this builder function is passed to customRouteBuilder property
  /// in [CustomPage]
  ///
  /// I couldn't type this function from here but it should match
  /// typedef [CustomRouteBuilder] = Route Function(BuildContext context, CustomPage page);
  /// you should only reference the function when passing it so
  /// the generator can import it into the generated file
  ///
  /// this builder function accepts a BuildContext and a CustomPage
  /// that has all the other properties assigned to it
  /// so using them then is totally up to you.
  final CustomRouteBuilder? customRouteBuilder;

  /// route transition duration in milliseconds
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a [transitionBuilder] is provided
  final int? durationInMilliseconds;

  /// route reverse transition duration in milliseconds
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a [transitionBuilder] is provided
  final int? reverseDurationInMilliseconds;

  /// passed to the barrierDismissible property in [PageRouteBuilder]
  final bool barrierDismissible;

  /// passed to the barrierLabel property in [PageRouteBuilder]
  final String? barrierLabel;

  /// passed to the barrierColor property in [PageRouteBuilder]
  final Color? barrierColor;

  const CustomRouteType({
    this.customRouteBuilder,
    this.barrierLabel,
    this.barrierColor,
    this.transitionsBuilder,
    this.durationInMilliseconds,
    this.reverseDurationInMilliseconds,
    super.opaque,
    this.barrierDismissible = false,
  }) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is CustomRouteType &&
          runtimeType == other.runtimeType &&
          transitionsBuilder == other.transitionsBuilder &&
          customRouteBuilder == other.customRouteBuilder &&
          durationInMilliseconds == other.durationInMilliseconds &&
          reverseDurationInMilliseconds ==
              other.reverseDurationInMilliseconds &&
          barrierDismissible == other.barrierDismissible &&
          barrierLabel == other.barrierLabel &&
          barrierColor == other.barrierColor;

  @override
  int get hashCode =>
      super.hashCode ^
      transitionsBuilder.hashCode ^
      customRouteBuilder.hashCode ^
      durationInMilliseconds.hashCode ^
      reverseDurationInMilliseconds.hashCode ^
      barrierDismissible.hashCode ^
      barrierLabel.hashCode ^
      barrierColor.hashCode;
}
