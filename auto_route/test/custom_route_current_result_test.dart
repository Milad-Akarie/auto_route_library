import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';
import 'router_test_utils.dart';

// flutter/flutter#171130: a page whose route sets currentResult, popped by
// the back swipe or system back, completed its push with null.
// Steps: Details is a CustomRoute whose customRouteBuilder returns a
// CupertinoPageRoute that reports currentResult 'picked'. Push it, then go
// back by the iOS swipe, or by system back. The push should complete with
// 'picked', as Navigator.push does.
void main() {
  final backs = <String, (Future<void> Function(WidgetTester), ThemeData)>{
    'the iOS back swipe': (swipeBack, iosTheme),
    'system back': (systemBack, androidTheme),
  };

  for (final MapEntry(key: name, value: (back, theme)) in backs.entries) {
    testWidgets("$name completes the push with the route's currentResult", (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: PageInfo('Home', builder: (_) => const Scaffold(body: Text('Home'))),
            initial: true,
          ),
          CustomRoute(
            page: PageInfo('Details', builder: (_) => const Scaffold(body: Text('Details'))),
            customRouteBuilder: <T>(context, child, page) =>
                _ResultRoute<T>(settings: page, result: 'picked' as T, builder: (_) => child),
          ),
        ],
      );
      tester.binding.handleAppLifecycleStateChanged(.resumed);
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(theme: theme, routerConfig: router.config()));
      await tester.pumpAndSettle();
      Object? result = 'unset';
      unawaited(router.push<String>(const PageRouteInfo('Details')).then((value) => result = value));
      await tester.pumpAndSettle();

      await back(tester);

      expectTopPage(router, 'Home');
      expect(result, 'picked');
    });
  }
}

class _ResultRoute<T> extends CupertinoPageRoute<T> {
  _ResultRoute({required super.builder, required super.settings, required this.result});

  final T result;

  @override
  T? get currentResult => result;
}
