import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#131154, #132824: an app reads the page's location from a
// dialog (GoRouterState.of threw), and from a plain Navigator inside a page.
// Steps: open a dialog from the second page; read the url from the dialog's
// context. On another page, nest a Navigator and read RouteData in its route.
// Should: the router (and its url) is reachable from the dialog; the nested
// Navigator's route finds the page's RouteData. RouteData.of from the dialog
// is not under a page, so it throws, as documented.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Scaffold(body: Text('HomeRoute'))),
        ),
        AutoRoute(
          path: '/templates',
          page: PageInfo('TemplatesRoute', builder: (_) => const _Templates()),
        ),
        AutoRoute(
          path: '/nested',
          page: PageInfo('NestedRoute', builder: (_) => const _Nested()),
        ),
      ],
    );
  });

  testWidgets('A dialog reads the page url from its context.router', (tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('TemplatesRoute')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();

    expect(find.text('dialog at /templates'), findsOneWidget);
    expect(find.text('RouteData.of threw'), findsOneWidget);
  });

  testWidgets('A route of a Navigator inside a page finds the page RouteData', (tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('NestedRoute')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('nested in NestedRoute'), findsOneWidget);
  });
}

class _Templates extends StatelessWidget {
  const _Templates();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (dialogContext) {
          var threw = false;
          try {
            RouteData.of(dialogContext);
            // RouteData.of reports a missing scope with a FlutterError.
            // ignore: avoid_catching_errors
          } on FlutterError {
            threw = true;
          }
          return AlertDialog(
            content: Column(
              mainAxisSize: .min,
              children: [
                Text('dialog at ${dialogContext.router.currentUrl}'),
                if (threw) const Text('RouteData.of threw'),
              ],
            ),
          );
        },
      ),
      child: const Text('Open dialog'),
    ),
  );
}

class _Nested extends StatelessWidget {
  const _Nested();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Navigator(
      onGenerateRoute: (_) =>
          MaterialPageRoute<void>(builder: (inner) => Text('nested in ${RouteData.of(inner).name}')),
    ),
  );
}
