import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';
import 'router_test_utils.dart';

void main() {
  // flutter/flutter#139144: in go_router, pushing a page right after an
  // awaited push returned, because that page popped itself, threw "Bad
  // state: Future already completed" and left an empty screen.
  // Steps: from the home page, await push(TwoRoute); TwoRoute pops itself
  // after a delay; once the await returns, push(ThreeRoute). Repeat with
  // delays from 0 to 200 ms.
  // Should: no exception, the stack is home then ThreeRoute.
  for (final delay in [0, 1, 16, 100, 200]) {
    testWidgets(
      'push right after an awaited push returns, popped after $delay ms',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(page: FirstRoute.page, path: '/', initial: true),
            AutoRoute(
              page: PageInfo(
                'TwoRoute',
                builder: (data) =>
                    _PopsItselfPage(delay: Duration(milliseconds: delay)),
              ),
              path: '/two',
            ),
            AutoRoute(page: ThirdRoute.page, path: '/three'),
          ],
        );
        await pumpRouterApp(tester, router);
        Object? error;
        unawaited(
          router
              .push<void>(const NamedRoute('TwoRoute'))
              .then((_) => router.push(const ThirdRoute()))
              .catchError((Object e) => error = e),
        );
        await tester.pumpAndSettle();
        await tester.pump(Duration(milliseconds: delay));
        await tester.pumpAndSettle();
        expect(error, isNull);
        expect(tester.takeException(), isNull);
        expect(router.stack.map((p) => p.name), [
          FirstRoute.name,
          ThirdRoute.name,
        ]);
        expectTopPage(router, ThirdRoute.name);
      },
    );
  }
}

class _PopsItselfPage extends StatefulWidget {
  const new({required this.delay});

  final Duration delay;

  @override
  State<_PopsItselfPage> createState() => _PopsItselfPageState();
}

class _PopsItselfPageState extends State<_PopsItselfPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) unawaited(context.router.maybePop());
    });
  }

  @override
  Widget build(BuildContext context) => const Text('TwoRoute');
}
