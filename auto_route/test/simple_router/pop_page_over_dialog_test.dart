import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#160696: popping a page pushed over a loading dialog, then
// closing the dialog, threw "Bad state: Future already completed".
// Steps: on Home, open a loading dialog without awaiting it; push Cancel; pop
// Cancel with true; then close the dialog. Both close, Cancel's push
// completes with true, and nothing throws. Once with a frame between each
// step, once all in one frame.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Home'), initial: true),
        AutoRoute(page: _page('Cancel')),
      ],
    );
  });

  void openLoadingDialog(WidgetTester tester) {
    showDialog<void>(
      context: tester.element(find.text('Home')),
      builder: (_) => const Dialog(child: Text('Loading')),
    );
  }

  testWidgets('pop the page, then the dialog, a frame apart', (tester) async {
    await pumpRouterApp(tester, router);
    Object? result;

    openLoadingDialog(tester);
    await tester.pumpAndSettle();
    unawaited(
      router
          .push<bool>(const PageRouteInfo('Cancel'))
          .then((value) => result = value),
    );
    await tester.pumpAndSettle();
    router.pop(true);
    await tester.pumpAndSettle();
    expect(find.text('Loading'), findsOneWidget);
    Navigator.of(tester.element(find.text('Loading'))).pop();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(result, isTrue);
    expect(find.text('Loading'), findsNothing);
    expect(router.stack.map((page) => page.routeData.name), ['Home']);
    expectTopPage(router, 'Home');
  });

  testWidgets('all in one frame', (tester) async {
    await pumpRouterApp(tester, router);
    Object? result;

    openLoadingDialog(tester);
    unawaited(
      router
          .push<bool>(const PageRouteInfo('Cancel'))
          .then((value) => result = value),
    );
    router.pop(true);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(result, isTrue);
    expect(find.text('Loading'), findsNothing);
    expect(router.stack.map((page) => page.routeData.name), ['Home']);
    expectTopPage(router, 'Home');
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
