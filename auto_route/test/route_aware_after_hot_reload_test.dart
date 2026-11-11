import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1313
// Setup: a router kept in a field. The app asks for its delegate, or its
// config, inline in a build method, and writes the observers builder inline
// too, returning a new AutoRouteObserver, so each build makes a new observer.
// The first page's State uses AutoRouteAwareStateMixin and counts the
// didPushNext and didPopNext calls.
// Steps: push a second page and pop it, hot reload the app, then push the
// second page and pop it again.
// Reported: the events arrived before the reload and stopped after it.
// Should: they keep arriving, once per push and pop.
void main() {
  late RootStackRouter router;
  late _Counts counts;

  setUp(() {
    counts = _Counts();
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo('FirstRoute', builder: (_) => _AwarePage(counts)),
          path: '/',
          initial: true,
        ),
        AutoRoute(
          page: PageInfo(
            'SecondRoute',
            builder: (_) => const Scaffold(body: Text('Second')),
          ),
          path: '/second',
        ),
      ],
    );
    addTearDown(router.dispose);
  });

  Future<void> pushAndPop(WidgetTester tester) async {
    unawaited(router.push(const NamedRoute('SecondRoute')));
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
  }

  Future<void> expectEventsSurviveReload(WidgetTester tester) async {
    await pushAndPop(tester);
    expect(counts.pushNext, 1, reason: 'didPushNext before the reload');
    expect(counts.popNext, 1, reason: 'didPopNext before the reload');

    unawaited(tester.binding.reassembleApplication());
    await tester.pumpAndSettle();

    await pushAndPop(tester);
    expect(counts.pushNext, 2, reason: 'didPushNext after the reload');
    expect(counts.popNext, 2, reason: 'didPopNext after the reload');
  }

  testWidgets(
    'A page keeps hearing push and pop after a hot reload with an inline '
    'delegate',
    (tester) async {
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp.router(
            routeInformationParser: router.defaultRouteParser(),
            routerDelegate: router.delegate(
              navigatorObservers: () => [AutoRouteObserver()],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectEventsSurviveReload(tester);
    },
  );

  testWidgets(
    'A page keeps hearing push and pop after a hot reload with an inline '
    'config',
    (tester) async {
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp.router(
            routerConfig: router.config(
              navigatorObservers: () => [AutoRouteObserver()],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectEventsSurviveReload(tester);
    },
  );
}

class _Counts {
  int pushNext = 0;
  int popNext = 0;
}

class _AwarePage extends StatefulWidget {
  const new(this.counts);

  final _Counts counts;

  @override
  State<_AwarePage> createState() => _AwarePageState();
}

class _AwarePageState extends State<_AwarePage> with AutoRouteAwareStateMixin {
  @override
  void didPushNext() => widget.counts.pushNext++;

  @override
  void didPopNext() => widget.counts.popNext++;

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('First'));
}
