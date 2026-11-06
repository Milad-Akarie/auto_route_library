part of 'cupertino_route_transition_override_mixin.dart';

/// An iOS-style transition used for summoning fullscreen dialogs.
///
/// For example, used when creating a new calendar event by bringing in the next
/// screen from the bottom.
class CupertinoFullscreenDialogTransition extends StatelessWidget {
  /// Creates an iOS-style transition used for summoning fullscreen dialogs.
  ///
  ///  * `primaryRouteAnimation` is a linear route animation from 0.0 to 1.0
  ///    when this screen is being pushed.
  ///  * `secondaryRouteAnimation` is a linear route animation from 0.0 to 1.0
  ///    when another screen is being pushed on top of this one.
  /// * `linearTransition` is whether to perform the secondary transition
  /// linearly.
  ///    Used to precisely track back gesture drags.
  new({
    required Animation<double> primaryRouteAnimation,
    required Animation<double> secondaryRouteAnimation,
    required this.child,
    required bool linearTransition,
    super.key,
  }) : _positionAnimation = CurvedAnimation(
         parent: primaryRouteAnimation,
         curve: Curves.linearToEaseOut,
         // The curve must be flipped so that the reverse animation doesn't play
         // an ease-in curve, which iOS does not use.
         reverseCurve: Curves.linearToEaseOut.flipped,
       ).drive(_kBottomUpTween),
       _secondaryPositionAnimation =
           (linearTransition
                   ? secondaryRouteAnimation
                   : CurvedAnimation(
                       parent: secondaryRouteAnimation,
                       curve: Curves.linearToEaseOut,
                       reverseCurve: Curves.easeInToLinear,
                     ))
               .drive(_kMiddleLeftTween);

  final Animation<Offset> _positionAnimation;

  // When this page is becoming covered by another page.
  final Animation<Offset> _secondaryPositionAnimation;

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
      child: SlideTransition(position: _positionAnimation, child: child),
    );
  }
}
