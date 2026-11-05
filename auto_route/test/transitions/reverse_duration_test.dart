import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/603
  // Setup, as reported: a CustomRoute with a fade-in transition, a duration and
  // a reverseDuration of zero ("essentially disable any animation").
  // Reported: popping the page still animated, the reverse duration was
  // ignored. Should: the page is gone right after a pop when reverseDuration is
  // zero, while the push still takes its own duration.
  late RootStackRouter router;

  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/'),
        CustomRoute(
          page: _SlowRoute.page,
          path: '/slow',
          transitionsBuilder: TransitionsBuilders.fadeIn,
          duration: const Duration(milliseconds: 600),
          reverseDuration: .zero,
        ),
        CustomRoute(
          page: _InstantRoute.page,
          path: '/instant',
          duration: .zero,
          reverseDuration: .zero,
        ),
      ],
    );
  });

  testWidgets('a pop takes the reverseDuration, not the duration', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);

    unawaited(router.push(const _SlowRoute()));
    await tester.pumpAndSettle();
    expect(find.text('Slow'), findsOneWidget);

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Slow'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('the push keeps its duration while the reverse is zero', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);

    unawaited(router.push(const _SlowRoute()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
    'the milliseconds spelling of both durations disables the animation',
    (tester) async {
      await pumpRouterApp(tester, router);

      unawaited(router.push(const _InstantRoute()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('Instant'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);

      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('Instant'), findsNothing);
    },
  );
}

abstract final class _HomeRoute {
  static const String name = 'HomeRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text('Home')),
  );
}

class _SlowRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'SlowRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text('Slow')),
  );
}

class _InstantRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'InstantRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text('Instant')),
  );
}
