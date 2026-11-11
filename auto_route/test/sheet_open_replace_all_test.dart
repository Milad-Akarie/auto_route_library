import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#174206: apps saw a LateInitializationError on a route's
// _modalScope when the stack was replaced, or a deep link landed, while a
// modal bottom sheet or a dialog was open. The thread has no
// reproduction; its trace runs through didPopNext and changedInternalState on a
// route not yet installed.
// Steps: on P2 with a modal bottom sheet open, replaceAll with P3; then the
// same with a dialog and navigatePath.
// Should: P3 shows alone, the sheet or dialog closes with P2, and nothing
// throws.
void main() {
  final opens = <String, void Function(BuildContext)>{
    'bottom sheet': (context) => showModalBottomSheet<void>(
      context: context,
      builder: (_) => const Text('Over'),
    ),
    'dialog': (context) =>
        showDialog<void>(context: context, builder: (_) => const Text('Over')),
  };
  final lands = <String, void Function(StackRouter)>{
    'replaceAll': (router) =>
        unawaited(router.replaceAll([const PageRouteInfo('P3')])),
    'navigatePath': (router) => unawaited(router.navigatePath('/p3')),
  };

  for (final MapEntry(key: over, value: open) in opens.entries) {
    for (final MapEntry(key: how, value: land) in lands.entries) {
      testWidgets(
        '$how with a $over open replaces the stack without an error',
        (tester) async {
          final router = RootStackRouter.build(
            routes: [
              for (final page in ['P1', 'P2', 'P3'])
                AutoRoute(
                  path: page == 'P1' ? '/' : '/${page.toLowerCase()}',
                  page: PageInfo(
                    page,
                    builder: (_) => Scaffold(body: Text(page)),
                  ),
                ),
            ],
          );
          await pumpRouterApp(tester, router);
          unawaited(router.pushPath('/p2'));
          await tester.pumpAndSettle();
          open(router.navigatorKey.currentContext!);
          await tester.pumpAndSettle();
          expect(find.text('Over'), findsOneWidget);

          land(router);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Over'), findsNothing);
          expect(find.text('P3'), findsOneWidget);
          expect(router.stack.lastOrNull?.name, 'P3');
        },
      );
    }
  }
}
