import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../centered_named_page.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/101183
  // Route 'bar' redirects while a switch is off, and a deep link to its child
  // 'bar/baz' went through anyway. Steps: with bar's guard rejecting, push
  // '/bar' and '/bar/baz'. Neither opens. With the guard letting through,
  // '/bar/baz' opens and each guard on its way ran.
  testWidgets(
    "A parent's guard runs for a deep link to its child (flutter/flutter#101183)",
    (tester) async {
      var isOpen = false;
      final calls = <String>[];
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'FooRoute',
            path: '/',
            builder: (_, _) => const CenteredNamedPage('FooRoute'),
          ),
          NamedRouteDef.guarded(
            name: 'BarRoute',
            path: '/bar',
            onNavigation: (resolver, _) {
              calls.add('bar');
              isOpen ? resolver.next() : resolver.reject();
            },
            builder: (_, _) => const AutoRouter(),
            children: [
              NamedRouteDef(
                name: 'BarHomeRoute',
                path: '',
                builder: (_, _) => const CenteredNamedPage('BarHomeRoute'),
              ),
              NamedRouteDef.guarded(
                name: 'BazRoute',
                path: 'baz',
                onNavigation: (resolver, _) {
                  calls.add('baz');
                  resolver.next();
                },
                builder: (_, _) => const CenteredNamedPage('BazRoute'),
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);

      unawaited(router.pushPath('/bar'));
      await tester.pumpAndSettle();
      unawaited(router.pushPath('/bar/baz'));
      await tester.pumpAndSettle();
      expectCurrentPage(router, 'FooRoute');
      expect(find.text('BazRoute'), findsNothing);
      expect(calls.where((e) => e == 'baz'), isEmpty);

      isOpen = true;
      unawaited(router.pushPath('/bar/baz'));
      await tester.pumpAndSettle();
      expect(find.text('BazRoute'), findsOneWidget);
      expect(calls.lastOrNull, 'baz');
      expect(calls, contains('bar'));
    },
  );
}
