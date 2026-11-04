import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/129892.
// Setup, as in the Flutter report: two pages with a FloatingActionButton, so
// both have a Hero with the button's default tag. Here they are auto_route
// pages; plain Flutter fails the same way.
// Steps: push SecondRoute, hide its button, show it again 100 ms later, and
// pop the page in the next frame, before the button's switch animation ends.
// Today the pop's hero flight finds two heroes with the default tag in
// SecondRoute, the button leaving and the button coming back, and Flutter
// asserts "There are multiple heroes that share the same tag within a
// subtree". auto_route cannot tell Scaffold's button switcher to drop the
// leaving Hero; the reporter avoids it by popping after the animation ends.
// If this test fails after a Flutter upgrade, Flutter no longer asserts here:
// drop this canary.
void main() {
  testWidgets('popping a page while its FloatingActionButton comes back asserts on two heroes', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HomeRoute',
            builder: (_) => Scaffold(
              body: const Text('HomeRoute'),
              floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Text('home button')),
            ),
          ),
        ),
        AutoRoute(
          path: '/second',
          page: PageInfo('SecondRoute', builder: (_) => const _SecondPage()),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('SecondRoute')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(router.topRoute.name, 'HomeRoute');
    expect(
      tester.takeException(),
      isA<FlutterError>().having(
        (error) => error.message,
        'message',
        startsWith('There are multiple heroes that share the same tag within a subtree.'),
      ),
    );
  });
}

class _SecondPage extends StatefulWidget {
  const _SecondPage();

  @override
  State<_SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<_SecondPage> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _saving = false);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.router.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OutlinedButton(onPressed: _save, child: const Text('save')),
      floatingActionButton: _saving ? null : FloatingActionButton(onPressed: () {}, child: const Text('second button')),
    );
  }
}
