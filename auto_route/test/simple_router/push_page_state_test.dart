import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// Builds of each _CountingPage, by its label, and the pages that exist.
final _builds = <String, int>{};

class _CountingPage extends StatefulWidget {
  const _CountingPage(this.label);

  final String label;

  @override
  State<_CountingPage> createState() => _CountingPageState();
}

class _CountingPageState extends State<_CountingPage> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    _builds[widget.label] = (_builds[widget.label] ?? 0) + 1;
    return Scaffold(
      body: Column(
        children: [
          Text('${widget.label} taps $taps'),
          TextButton(onPressed: () => setState(() => taps++), child: Text('tap ${widget.label}')),
        ],
      ),
    );
  }
}

PageInfo _home = .new('HomeRoute', builder: (_) => const _CountingPage('home'));
PageInfo _detail = .new('DetailRoute', builder: (_) => const _CountingPage('detail'));

void main() {
  setUp(_builds.clear);

  RootStackRouter router() => .build(
    routes: [
      AutoRoute(page: _home, path: '/'),
      AutoRoute(page: _detail, path: '/detail'),
    ],
  );

  // flutter/flutter#165381: pushing then popping a route rebuilt the page
  // under it and lost its State.
  // Steps: on the home page tap its counter, push DetailRoute, pop it.
  // Should: the home page has the same State, with its count.
  testWidgets('A page keeps its State while another page is pushed over it and popped (flutter/flutter#165381)', (
    tester,
  ) async {
    final r = router();
    await pumpRouterApp(tester, r);
    await tester.tap(find.text('tap home'));
    await tester.pump();
    expect(find.text('home taps 1'), findsOneWidget);

    unawaited(r.push(const NamedRoute('DetailRoute')));
    await tester.pumpAndSettle();
    r.pop();
    await tester.pumpAndSettle();

    expect(find.text('home taps 1'), findsOneWidget, reason: 'after r.pop()');
  });

  // flutter/flutter#160173: pushNamed the same route again and again, each
  // push built every page of that route in the stack again.
  // Steps: push DetailRoute twice, then a third time; count the builds.
  // Should: a page built under a newer one is not built again by the
  // push, and each keeps its own State.
  testWidgets('Pushing a route again does not build the earlier copies again (flutter/flutter#160173)', (tester) async {
    final r = router();
    await pumpRouterApp(tester, r);

    unawaited(r.push(const NamedRoute('DetailRoute')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('tap detail'));
    await tester.pump();
    final afterFirst = _builds['detail']!;

    unawaited(r.push(const NamedRoute('DetailRoute')));
    await tester.pumpAndSettle();
    // The second copy is built; the first, now hidden, is not.
    expect(_builds['detail'], afterFirst + 1);

    unawaited(r.push(const NamedRoute('DetailRoute')));
    await tester.pumpAndSettle();
    expect(_builds['detail'], afterFirst + 2);
    expect(r.stack, hasLength(4));

    r.pop();
    r.pop();
    await tester.pumpAndSettle();
    expect(find.text('detail taps 1'), findsOneWidget);
  });
}
