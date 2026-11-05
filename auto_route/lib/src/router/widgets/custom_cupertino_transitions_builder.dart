// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The adjustments made to this code is to disable unwanted shadow
// of routes when used as nested routes, e.g inside of a TabsRouter

// Copied from Flutter: the code stays as Flutter wrote it, so the two can
// still be compared line by line.

import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoDynamicColor, CupertinoRouteTransitionMixin;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

part 'cupertino_fullscreen_dialog_transition.dart';

/// Barrier color for a Cupertino modal barrier.
///
/// Extracted from https://developer.apple.com/design/resources/.
const Color kCupertinoModalBarrierColor = CupertinoDynamicColor.withBrightness(
  color: Color(0x33000000),
  darkColor: Color(0x7A000000),
);

// Offset from offscreen to the right to fully on screen.
final Animatable<Offset> _kRightMiddleTween = Tween(
  begin: const Offset(1, 0),
  end: Offset.zero,
);

// Offset from fully on screen to 1/3 offscreen to the left.
final Animatable<Offset> _kMiddleLeftTween = Tween(
  begin: Offset.zero,
  end: const Offset(-1.0 / 3.0, 0),
);

// Offset from offscreen below to fully on screen.
final Animatable<Offset> _kBottomUpTween = Tween(
  begin: const Offset(0, 1),
  end: Offset.zero,
);

/// A mixin that implements methods and/or parameters of a [PageRoute].
///
/// Meant to be used as an override of methods/parameters implemented in
/// [CupertinoRouteTransitionMixin].
mixin CupertinoRouteTransitionOverrideMixin<T> on PageRoute<T> {
  // fixes https://github.com/flutter/flutter/issues/105738
  @override
  Color? get barrierColor => null;

  @override
  RoutePopDisposition get popDisposition {
    if (willHandlePopInternally) {
      return .pop;
    }
    return super.popDisposition;
  }
}

/// Provides an iOS-style page transition animation.
///
/// The page slides in from the right and exits in reverse. It also shifts to
/// the left in a parallax motion when another page enters to cover it.
class CupertinoPageTransition extends StatelessWidget {
  /// Creates an iOS-style page transition.
  ///
  ///  * `primaryRouteAnimation` is a linear route animation from 0.0 to 1.0
  ///    when this screen is being pushed.
  ///  * `secondaryRouteAnimation` is a linear route animation from 0.0 to 1.0
  ///    when another screen is being pushed on top of this one.
  ///  * `linearTransition` is whether to perform the transitions linearly.
  ///    Used to precisely track back gesture drags.
  new({
    required Animation<double> primaryRouteAnimation,
    required Animation<double> secondaryRouteAnimation,
    required this.child,
    required bool linearTransition,
    super.key,
  }) : _primaryPositionAnimation =
           (linearTransition
                   ? primaryRouteAnimation
                   : CurvedAnimation(
                       // The curves below have been rigorously derived from
                       // plots of native iOS animation frames. Specifically, a
                       // video was taken of a page transition animation and the
                       // distance in each frame that the page moved was
                       // measured. A best fit bezier curve was the fitted to
                       // the point set, which is linearToEaseIn. Conversely,
                       // easeInToLinear is the reflection over the origin of
                       // linearToEaseIn.
                       parent: primaryRouteAnimation,
                       curve: Curves.linearToEaseOut,
                       reverseCurve: Curves.easeInToLinear,
                     ))
               .drive(_kRightMiddleTween),
       _secondaryPositionAnimation =
           (linearTransition
                   ? secondaryRouteAnimation
                   : CurvedAnimation(
                       parent: secondaryRouteAnimation,
                       curve: Curves.linearToEaseOut,
                       reverseCurve: Curves.easeInToLinear,
                     ))
               .drive(_kMiddleLeftTween),
       _primaryShadowAnimation =
           (linearTransition
                   ? primaryRouteAnimation
                   : CurvedAnimation(
                       parent: primaryRouteAnimation,
                       curve: Curves.linearToEaseOut,
                     ))
               .drive(
                 _CupertinoEdgeShadowDecoration.tween(
                   withShadow: linearTransition,
                 ),
               );

  // When this page is coming in to cover another page.
  final Animation<Offset> _primaryPositionAnimation;

  // When this page is becoming covered by another page.
  final Animation<Offset> _secondaryPositionAnimation;
  final Animation<Decoration> _primaryShadowAnimation;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(
      debugCheckHasDirectionality(context),
      'A Directionality ancestor is required.',
    );
    final textDirection = Directionality.of(context);
    return SlideTransition(
      position: _secondaryPositionAnimation,
      textDirection: textDirection,
      transformHitTests: false,
      child: SlideTransition(
        position: _primaryPositionAnimation,
        textDirection: textDirection,
        child: DecoratedBoxTransition(
          decoration: _primaryShadowAnimation,
          child: child,
        ),
      ),
    );
  }
}

// A custom [Decoration] used to paint an extra shadow on the start edge of the
// box it's decorating. It's like a [BoxDecoration] with only a gradient except
// it paints on the start side of the box instead of behind the box.
class _CupertinoEdgeShadowDecoration extends Decoration {
  const new _([this._colors]);

  static DecorationTween tween({required bool withShadow}) => .new(
    begin: const _CupertinoEdgeShadowDecoration._(), // No decoration initially.
    end: _CupertinoEdgeShadowDecoration._(
      // Eyeballed gradient used to mimic a drop shadow on the start side only.
      withShadow
          ? const [
              Color(0x38000000),
              Color(0x12000000),
              Color(0x04000000),
              Color(0x00000000),
            ]
          : const [],
    ),
  );

  // Colors used to paint a gradient at the start edge of the box it is
  // decorating.
  //
  // The first color in the list is used at the start of the gradient, which
  // is located at the start edge of the decorated box.
  //
  // If this is null, no shadow is drawn.
  //
  // The list must have at least two colors in it (otherwise it would not be a
  // gradient).
  final List<Color>? _colors;

  // Linearly interpolate between two edge shadow decorations decorations.
  //
  // The `t` argument represents position on the timeline, with 0.0 meaning
  // that the interpolation has not started, returning `a` (or something
  // equivalent to `a`), 1.0 meaning that the interpolation has finished,
  // returning `b` (or something equivalent to `b`), and values in between
  // meaning that the interpolation is at the relevant point on the timeline
  // between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
  // 1.0, so negative values and values greater than 1.0 are valid (and can
  // easily be generated by curves such as [Curves.elasticInOut]).
  //
  // Values for `t` are usually obtained from an [Animation<double>], such as
  // an [AnimationController].
  //
  // See also:
  //
  //  * [Decoration.lerp].
  static _CupertinoEdgeShadowDecoration? lerp(
    _CupertinoEdgeShadowDecoration? a,
    _CupertinoEdgeShadowDecoration? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final aColors = a?._colors;
    final bColors = b?._colors;
    if (a == null) {
      return bColors == null
          ? b
          : _CupertinoEdgeShadowDecoration._(
              bColors
                  .map<Color>((color) => Color.lerp(null, color, t)!)
                  .toList(),
            );
    }
    if (b == null) {
      return aColors == null
          ? a
          : _CupertinoEdgeShadowDecoration._(
              aColors
                  .map<Color>((color) => Color.lerp(null, color, 1.0 - t)!)
                  .toList(),
            );
    }
    assert(
      bColors != null || aColors != null,
      'At least one decoration has colors.',
    );
    // If it ever becomes necessary, we could allow decorations with different
    // length' here, similarly to how it is handled in [LinearGradient.lerp].
    assert(
      bColors == null || aColors == null || aColors.length == bColors.length,
      'Both decorations have the same number of colors.',
    );
    return _CupertinoEdgeShadowDecoration._([
      for (int i = 0; i < bColors!.length; i += 1)
        Color.lerp(a._colors?[i], bColors[i], t)!,
    ]);
  }

  @override
  _CupertinoEdgeShadowDecoration lerpFrom(Decoration? a, double t) {
    if (a is _CupertinoEdgeShadowDecoration) {
      return _CupertinoEdgeShadowDecoration.lerp(a, this, t)!;
    }
    return _CupertinoEdgeShadowDecoration.lerp(null, this, t)!;
  }

  @override
  _CupertinoEdgeShadowDecoration lerpTo(Decoration? b, double t) {
    if (b is _CupertinoEdgeShadowDecoration) {
      return _CupertinoEdgeShadowDecoration.lerp(this, b, t)!;
    }
    return _CupertinoEdgeShadowDecoration.lerp(this, null, t)!;
  }

  @override
  _CupertinoEdgeShadowPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CupertinoEdgeShadowPainter(this, onChanged);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _CupertinoEdgeShadowDecoration && other._colors == _colors;
  }

  @override
  int get hashCode => _colors.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Color>('colors', _colors));
  }
}

/// A [BoxPainter] used to draw the page transition shadow using gradients.
class _CupertinoEdgeShadowPainter extends BoxPainter {
  new(this._decoration, VoidCallback? onChange) : super(onChange);

  final _CupertinoEdgeShadowDecoration _decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final colors = _decoration._colors;
    if (colors == null || colors.isEmpty) {
      return;
    }

    // The following code simulates drawing a [LinearGradient] that begins at
    // AlignmentDirectional(0.90, 0.0), so it spans 5% of the page, with
    // `_decoration._colors` as its colors.
    //
    // A performance evaluation on Feb 8, 2021 showed, that drawing the gradient
    // manually as implemented below is more performant than relying on
    // [LinearGradient.createShader] because compiling that shader takes a long
    // time. On an iPhone XR, the implementation below reduced the worst frame
    // time for a cupertino page transition of a newly installed app from ~95ms
    // down to ~30ms, mainly because there's no longer a need to compile a
    // shader for the LinearGradient.
    //
    // The implementation below divides the width of the shadow into multiple
    // bands of equal width, one for each color interval defined by
    // `_decoration._colors`. Band x is filled with a gradient going from
    // `_decoration._colors[x]` to `_decoration._colors[x + 1]` by drawing a
    // bunch of 1px wide rects. The rects change their color by lerping between
    // the two colors that define the interval of the band.

    // Shadow spans 5% of the page.
    final shadowWidth = 0.05 * configuration.size!.width;
    final shadowHeight = configuration.size!.height;
    final bandWidth = shadowWidth / (colors.length - 1);

    final textDirection = configuration.textDirection;
    assert(
      textDirection != null,
      'The shadow is painted for a text direction.',
    );
    final double start;
    final double shadowDirection; // -1 for ltr, 1 for rtl.
    switch (textDirection!) {
      case .rtl:
        start = offset.dx + configuration.size!.width;
        shadowDirection = 1;
      case .ltr:
        start = offset.dx;
        shadowDirection = -1;
    }

    var bandColorIndex = 0;
    for (var dx = 0; dx < shadowWidth; dx += 1) {
      if (dx ~/ bandWidth != bandColorIndex) {
        bandColorIndex += 1;
      }
      final paint = Paint()
        ..color = Color.lerp(
          colors[bandColorIndex],
          colors[bandColorIndex + 1],
          (dx % bandWidth) / bandWidth,
        )!;
      final x = start + shadowDirection * dx;
      canvas.drawRect(
        Rect.fromLTWH(x - 1.0, offset.dy, 1, shadowHeight),
        paint,
      );
    }
  }
}
