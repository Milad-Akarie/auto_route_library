import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

const _duration = Duration(milliseconds: 400);

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

RootStackRouter _router({CustomRouteBuilder? customRouteBuilder}) {
  return RootStackRouter.build(
    routes: [
      AutoRoute(path: '/', page: _page('HomeRoute')),
      CustomRoute(
        path: '/a',
        page: _page('ARoute'),
        transitionsBuilder: TransitionsBuilders.fadeIn,
        duration: _duration,
        reverseDuration: _duration,
      ),
      CustomRoute(
        path: '/b',
        page: _page('BRoute'),
        transitionsBuilder: TransitionsBuilders.fadeIn,
        duration: _duration,
        reverseDuration: _duration,
      ),
      CustomRoute(path: '/built', page: _page('BuiltRoute'), customRouteBuilder: customRouteBuilder),
      AutoRoute(
        path: '/host',
        page: PageInfo('HostRoute', builder: (_) => const AutoRouter()),
        children: [
          AutoRoute(path: '', page: _page('FirstChildRoute')),
          CustomRoute(
            path: 'second',
            page: _page('SecondChildRoute'),
            transitionsBuilder: TransitionsBuilders.fadeIn,
            duration: _duration,
          ),
        ],
      ),
    ],
  );
}

// The animation of the route that shows [name].
Animation<double> _animationOf(WidgetTester tester, String name) {
  return ModalRoute.of(tester.element(find.text(name, skipOffstage: false)))!.animation!;
}

// Pumps frames until [done] completes, and returns the value then of the
// animation of [name]'s route; fails if it doesn't complete within twice the
// transition's duration.
Future<double> _pumpUntilDone(WidgetTester tester, Future<void> done, String name) async {
  var isDone = false;
  unawaited(done.then((_) => isDone = true));
  for (var elapsed = Duration.zero; elapsed < _duration * 2; elapsed += const Duration(milliseconds: 16)) {
    await tester.pump(const Duration(milliseconds: 16));
    if (isDone) return _animationOf(tester, name).value;
  }
  fail('waitForTransitions() did not complete');
}

void main() {
  // https://github.com/flutter/flutter/issues/162789, asked of go_router.
  // Asked: code that pushes a page can wait until its transition has ended,
  // for example to open a bottom sheet over it, which a transition still
  // running would close. The push future completes only when the page is
  // popped.
  // Steps: push ARoute without awaiting it, then await
  // router.waitForTransitions().
  // Should: it completes once ARoute's route animation has completed, not
  // before.
  testWidgets('waitForTransitions() after a push completes when the page has come in', (tester) async {
    final router = _router();
    await pumpRouterApp(tester, router);

    unawaited(router.push(const NamedRoute('ARoute')));
    final value = await _pumpUntilDone(tester, router.waitForTransitions(), 'ARoute');

    expect(value, 1.0);
    expect(_animationOf(tester, 'ARoute').status, AnimationStatus.completed);
  });

  testWidgets('waitForTransitions() after a replace completes when the new page has come in', (tester) async {
    final router = _router();
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('ARoute')));
    await tester.pumpAndSettle();

    unawaited(router.replace(const NamedRoute('BRoute')));
    final value = await _pumpUntilDone(tester, router.waitForTransitions(), 'BRoute');

    expect(value, 1.0);
    expect(router.stack.map((page) => page.name), ['HomeRoute', 'BRoute']);
  });

  // The go_router issue's own case: the push future completes as the page
  // starts to leave; a sheet opened then would land under its exit.
  testWidgets('waitForTransitions() after a pop completes when the page has left', (tester) async {
    final router = _router();
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('ARoute')));
    await tester.pumpAndSettle();
    final animation = _animationOf(tester, 'ARoute');

    router.pop();
    var isDone = false;
    unawaited(router.waitForTransitions().then((_) => isDone = true));
    await tester.pump();
    await tester.pump(_duration ~/ 2);
    expect(animation.isAnimating, isTrue);
    expect(isDone, isFalse);
    await tester.pump(_duration ~/ 2 + const Duration(milliseconds: 16));

    expect(animation.status, AnimationStatus.dismissed);
    expect(isDone, isTrue);
  });

  testWidgets('waitForTransitions() waits for a push in a nested router', (tester) async {
    final router = _router();
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('HostRoute')));
    await tester.pumpAndSettle();

    unawaited(router.push(const NamedRoute('SecondChildRoute')));
    final value = await _pumpUntilDone(tester, router.waitForTransitions(), 'SecondChildRoute');

    expect(value, 1.0);
  });

  testWidgets('waitForTransitions() waits for a page built by a customRouteBuilder', (tester) async {
    final router = _router(
      customRouteBuilder: <T>(context, child, page) => PageRouteBuilder<T>(
        settings: page,
        transitionDuration: _duration,
        pageBuilder: (_, _, _) => child,
        transitionsBuilder: TransitionsBuilders.fadeIn,
      ),
    );
    await pumpRouterApp(tester, router);

    unawaited(router.push(const NamedRoute('BuiltRoute')));
    final value = await _pumpUntilDone(tester, router.waitForTransitions(), 'BuiltRoute');

    expect(value, 1.0);
  });

  testWidgets('waitForTransitions() with nothing moving completes on the next frame', (tester) async {
    final router = _router();
    await pumpRouterApp(tester, router);

    var isDone = false;
    unawaited(router.waitForTransitions().then((_) => isDone = true));
    await tester.pump();

    expect(isDone, isTrue);
  });
}
