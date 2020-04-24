import 'dart:html';

import 'package:auto_route/auto_route.dart';
import 'package:device_preview/device_preview.dart';
import 'package:example/router/route_guards.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class CupertionPageTrans extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return CupertinoPageRoute.buildPageTransitions(
        route, context, animation, secondaryAnimation, child);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (ctx, __) => Theme(
        data: Theme.of(ctx).copyWith(
            pageTransitionsTheme: PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertionPageTrans(),
        })),
        child: ExtendedNavigator<Router>(
          router: Router(),
          guards: [AuthGuard()],
        ),
      ),
    );
  }
}

// class AdaptivePageRoute<T> {
//   _getRout() {
//     MaterialPageRoute();
//     CupertinoPageRoute();
//   }
// }
