import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/158136
  // In go_router, going back to a page with a Hero right after closing a
  // dialog left that page's Hero invisible. A Navigator alone didn't.
  // Steps: Home and Detail share a Hero; push Detail, open a dialog on
  // it, close the dialog and, as soon as its future completes, while it still
  // fades out, go to Home with [label].
  // Should: the Hero flies back and shows on Home.
  for (final (label, goHome) in [
    (
      'navigate',
      (StackRouter router) => router.navigate(const NamedRoute('Home')),
    ),
    (
      'replaceAll',
      (StackRouter router) => router.replaceAll([const NamedRoute('Home')]),
    ),
    (
      'pop',
      (StackRouter router) {
        router.pop();
      },
    ),
  ]) {
    testWidgets(
      'A Hero shows again after $label right after a dialog closes (flutter/flutter#158136)',
      (tester) async {
        Widget hero() => const Hero(
          tag: 'logo',
          child: SizedBox.square(dimension: 50, child: Text('Logo')),
        );
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              page: PageInfo(
                'Home',
                builder: (_) => Scaffold(
                  body: Align(alignment: .topLeft, child: hero()),
                ),
              ),
              path: '/',
            ),
            AutoRoute(
              page: PageInfo(
                'Detail',
                builder: (_) => Scaffold(
                  body: Align(alignment: .bottomRight, child: hero()),
                ),
              ),
              path: '/detail',
            ),
          ],
        );
        await pumpRouterApp(tester, router);
        unawaited(router.push(const NamedRoute('Detail')));
        await tester.pumpAndSettle();

        final dialogContext = tester.element(find.text('Logo'));
        unawaited(
          showDialog<void>(
            context: dialogContext,
            builder: (_) => const AlertDialog(content: Text('Dialog')),
          ).then((_) => goHome(router)),
        );
        await tester.pumpAndSettle();
        Navigator.of(dialogContext).pop();
        await tester.pumpAndSettle();

        expect(router.stack.map((page) => page.name), ['Home']);
        // A Hero still in flight, or left as a placeholder, keeps its child
        // offstage or drops it.
        expect(find.text('Logo'), findsOneWidget);
        expect(tester.getTopLeft(find.text('Logo')), Offset.zero);
      },
    );
  }
}
