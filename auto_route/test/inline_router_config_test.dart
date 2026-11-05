import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';
import 'no_op.dart';

void main() {
  late RootStackRouter router;
  late StateSetter rebuildApp;

  setUp(() {
    _CounterPageState.created = 0;
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/', initial: true),
        AutoRoute(
          page: PageInfo('CounterRoute', builder: (_) => const _CounterPage()),
          path: '/counter',
        ),
      ],
    );
    addTearDown(router.dispose);
  });

  // The router is a field kept for the app's life; its config is asked for
  // inline in a build method that runs again.
  Future<void> pumpInlineConfigApp(WidgetTester tester) async {
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          rebuildApp = setState;
          return MaterialApp.router(routerConfig: router.config());
        },
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('CounterRoute')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(find.text('count 1'), findsOneWidget);
  }

  void expectStackAndStateKept() {
    expect(router.stack.map((p) => p.name), [FirstRoute.name, 'CounterRoute']);
    expect(find.text('count 1'), findsOneWidget);
    expect(_CounterPageState.created, 1);
  }

  // flutter/flutter#115379: go_router's docs left open where the router
  // should live. In auto_route the stack lives in the RootStackRouter, so an
  // app that keeps the router in a field may call
  // `MaterialApp.router(routerConfig: router.config())` in a build method
  // that runs again. Creating the RootStackRouter itself in build is not
  // supported: each build would start a new, empty stack.
  // Steps: push CounterRoute, count to 1, then rebuild the widget above
  // MaterialApp.router.
  // Should: the stack and the page's State are kept.
  testWidgets(
    'config() called again in a rebuilt build keeps the stack and page state',
    (tester) async {
      await pumpInlineConfigApp(tester);
      rebuildApp(noOp);
      await tester.pumpAndSettle();
      expectStackAndStateKept();
    },
  );

  // flutter/flutter#127206: go_router asked how to handle a router config
  // created inline in MaterialApp.router, which a hot reload builds again.
  // With the router kept in a field, a hot reload keeps the stack and state.
  // Steps: push CounterRoute, count to 1, then reassemble the app as a hot
  // reload does.
  // Should: the stack and the page's State are kept.
  testWidgets(
    'config() called inline keeps the stack and page state through a hot '
    'reload',
    (tester) async {
      await pumpInlineConfigApp(tester);
      unawaited(tester.binding.reassembleApplication());
      await tester.pumpAndSettle();
      expectStackAndStateKept();
    },
  );
}

class _CounterPage extends StatefulWidget {
  const new();

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  static int created = 0;
  var _count = 0;

  @override
  void initState() {
    super.initState();
    created++;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('count $_count'),
        TextButton(
          onPressed: () => setState(() => _count++),
          child: const Text('add'),
        ),
      ],
    ),
  );
}
