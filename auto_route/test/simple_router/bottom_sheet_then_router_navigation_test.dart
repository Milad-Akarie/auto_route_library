import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  late RootStackRouter router;

  setUp(() {
    router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (sheet) => Column(
                  mainAxisSize: .min,
                  children: [
                    TextButton(
                      onPressed: () => unawaited(sheet.router.push(const NamedRoute('Page2Route'))),
                      child: const Text('push'),
                    ),
                    TextButton(
                      onPressed: () => unawaited(sheet.router.navigate(const NamedRoute('Page2Route'))),
                      child: const Text('navigate'),
                    ),
                  ],
                ),
              ),
              child: const Text('Options'),
            ),
          ),
        ),
        NamedRouteDef(
          name: 'Page2Route',
          path: '/page2',
          builder: (_, _) => const Scaffold(body: Text('Page2Route')),
        ),
      ],
    );
  });

  // https://github.com/flutter/flutter/issues/100933
  // The reporter opened a modal bottom sheet and, from its button, went to
  // Page2 with the router. With go_router that threw "have popped the last
  // page off of the stack". Steps: open the sheet, tap a button that pushes
  // Page2 (or navigates to it). Page2 shows, nothing throws, and popping it
  // lands on Home.
  for (final label in ['push', 'navigate']) {
    testWidgets('A bottom sheet button can $label to a page with the router (flutter/flutter#100933)', (tester) async {
      await pumpRouterApp(tester, router);
      await tester.tap(find.text('Options'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(router.current.name, 'Page2Route');
      expect(find.text('Page2Route'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'after router.pop()');
      expect(router.current.name, 'HomeRoute');
    });
  }
}
