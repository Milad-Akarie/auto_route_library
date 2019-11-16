import 'package:flutter/material.dart';

Widget rotationTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  return RotationTransition(
    turns: Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.linear,
      ),
    ),
    child: child,
  );
}
