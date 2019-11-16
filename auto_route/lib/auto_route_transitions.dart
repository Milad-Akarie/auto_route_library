import 'package:flutter/material.dart';

class RouteTransitions {
  static Widget slideFromRight(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }
}