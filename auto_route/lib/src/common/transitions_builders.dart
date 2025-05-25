import 'package:flutter/material.dart';

/// all of the methods in this file map to existing, already-tested flutter widgets
/// so no-need to include them in test-coverage

// coverage:ignore-file
/// a class that holds presets of common route transition builder
class TransitionsBuilders {
  const TransitionsBuilders._();

  /// creates an animation when the route slides from right direction
  static const RouteTransitionsBuilder slideRight = _slideRight;

  static Widget _slideRight(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  /// creates an animation when the route slides from left direction
  static const RouteTransitionsBuilder slideLeft = _slideLeft;

  static Widget _slideLeft(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  /// creates an animation when the route slides from right direction with fade
  static const RouteTransitionsBuilder slideRightWithFade = _slideRightWithFade;

  static Widget _slideRightWithFade(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  /// creates an animation when the route slides from left direction with fade
  static const RouteTransitionsBuilder slideLeftWithFade = _slideLeftWithFade;

  static Widget _slideLeftWithFade(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  /// creates an animation when the route slides to top direction
  static const RouteTransitionsBuilder slideTop = _slideTop;

  static Widget _slideTop(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, -1.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  /// creates an animation when the route slides to bottom direction
  static const RouteTransitionsBuilder slideBottom = _slideBottom;

  static Widget _slideBottom(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  /// creates an animation when the route fades in
  static const RouteTransitionsBuilder fadeIn = _fadeIn;

  static Widget _fadeIn(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }

  /// creates an animation when the route zooms in
  static const RouteTransitionsBuilder zoomIn = _zoomIn;

  static Widget _zoomIn(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return ScaleTransition(scale: animation, child: child);
  }

  /// returns the passed in widget with animations
  static const RouteTransitionsBuilder noTransition = _noTransition;

  static Widget _noTransition(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}
