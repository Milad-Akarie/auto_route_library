import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// #2176 (auto_route 10.0.1, Flutter 3.29): two replaceAll calls fired close
// together broke the navigator with '!navigator._debugLocked' and
// 'route._navigator == navigator' assertions.
// Setup: a flat root with 'FirstRoute' (initial) and 'SecondRoute'. FirstRoute
// calls replaceAll([SecondRoute]) in a post-frame callback of its initState and
// again after a delay (0, 1, 2 and 16 ms).
// Steps: start the app and let the frames run.
// Should: no exception; SecondRoute is the only page.
void main() {
  for (final delay in [0, 1, 2, 16]) {
    testWidgets('Two replaceAll calls $delay ms apart leave SecondRoute', (
      tester,
    ) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            initial: true,
            page: PageInfo(
              'FirstRoute',
              builder: (_) =>
                  _ReplacesTwice(delay: Duration(milliseconds: delay)),
            ),
          ),
          AutoRoute(
            path: '/second',
            page: PageInfo(
              'SecondRoute',
              builder: (_) => const Scaffold(body: Text('SecondRoute')),
            ),
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      await tester.pump(Duration(milliseconds: delay));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expectTopPage(router, 'SecondRoute');
      expect(router.stack.map((page) => page.name), ['SecondRoute']);
    });
  }
}

class _ReplacesTwice extends StatefulWidget {
  const new({required this.delay});

  final Duration delay;

  @override
  State<_ReplacesTwice> createState() => _ReplacesTwiceState();
}

class _ReplacesTwiceState extends State<_ReplacesTwice> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.router.replaceAll([const NamedRoute('SecondRoute')]));
      }
      Future<void>.delayed(widget.delay, () {
        if (mounted) {
          unawaited(
            context.router.replaceAll([const NamedRoute('SecondRoute')]),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
