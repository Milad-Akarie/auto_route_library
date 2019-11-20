import 'package:flutter/material.dart';

Widget slideFromRight(context, Animation<double> anim, Animation<double> secondAnim, Widget child) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(anim),
    child: child,
  );
}
