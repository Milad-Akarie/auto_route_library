import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1797
// pushAndPopUntil(scopedPopUntil: false) asks its predicate about the
// routers from the top-most one down, removing what it rejects, until one
// accepts. These tests pin what that leaves across a multi-step flow in a
// nested router, the history case flutter/flutter#193950 raises for
// go_router.
// Steps, on iOS so pages slide: open Home, then a shell whose nested router holds S1 and S2. From
// inside the nested router, call pushAndPopUntil(Done, scopedPopUntil: false)
// with Done a root route.
// Should: with a predicate that keeps Home, the nested pages and the shell
// go, leaving Home and Done. With one that keeps S1, only S2 goes: the root keeps
// Home and the shell, which holds S1, and Done goes on top. Back retraces it.
// Happened: S2 animated out and observers heard it popped, not removed; and
// when the shell went too, its nested router was emptied first, so one frame
// was blank and Done slid in over an empty shell instead of over S2.
void main() {
  late RootStackRouter router;
  late List<String> observed;

  setUp(() {
    observed = [];
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Home'), initial: true),
        AutoRoute(
          page: const EmptyShellRoute('Shell'),
          children: [
            AutoRoute(page: _page('S1'), initial: true),
            AutoRoute(page: _page('S2')),
          ],
        ),
        AutoRoute(page: _page('Done')),
      ],
    );
  });

  List<String> namesOf(StackRouter activeRouter) => activeRouter.stack.map((page) => page.routeData.name).toList();

  // Opens Home, then the shell with S1 and S2, and returns the shell's
  // nested router.
  Future<StackRouter> openShellWithS1S2(WidgetTester tester) async {
    await pumpRouterApp(tester, router, observers: () => [_NamesObserver(observed)]);
    unawaited(router.push(const PageRouteInfo('Shell')));
    await tester.pumpAndSettle();
    final nested = router.innerRouterOf<StackRouter>('Shell')!;
    unawaited(nested.push(const PageRouteInfo('S2')));
    await tester.pumpAndSettle();
    expect(namesOf(router), ['Home', 'Shell']);
    expect(namesOf(nested), ['S1', 'S2']);
    observed.clear();
    return nested;
  }

  // Calls pushAndPopUntil(Done) from [nested], keeping the route named
  // [kept], and returns the pages on screen, with their left edge, in each
  // frame while Done slides in.
  Future<List<String>> pushDoneKeeping(WidgetTester tester, StackRouter nested, String kept) async {
    unawaited(
      nested.pushAndPopUntil(
        const PageRouteInfo('Done'),
        predicate: (route) => route.settings.name == kept,
        scopedPopUntil: false,
      ),
    );
    final frames = <String>[];
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      frames.add(
        ['Home', 'S1', 'S2', 'Done']
            .where((name) => find.text(name).evaluate().isNotEmpty)
            .map((name) => '$name@${tester.getTopLeft(find.text(name)).dx.round()}')
            .join(', '),
      );
    }
    await tester.pumpAndSettle();
    return frames;
  }

  testWidgets('A predicate that keeps Home removes the nested pages and their shell', (tester) async {
    final nested = await openShellWithS1S2(tester);

    final frames = await pushDoneKeeping(tester, nested, 'Home');
    expect(tester.takeException(), isNull);
    // S2, the page on screen, stays under Done until Done covers it.
    expect(frames.firstOrNull, startsWith('S2'), reason: 'frames: $frames');
    expect(frames.takeWhile((frame) => !frame.endsWith('Done@0')), everyElement(startsWith('S2')));
    expect(frames.where((frame) => frame.contains('S1') || frame.contains('Home')), isEmpty);
    expect(observed, ['push Done', 'remove Shell']);
    expect(namesOf(router), ['Home', 'Done']);
    expectTopPage(router, 'Done');
    expect(router.innerRouterOf<StackRouter>('Shell'), isNull);

    unawaited(router.maybePop());
    await tester.pumpAndSettle();
    expectTopPage(router, 'Home');
    expect(namesOf(router), ['Home']);
  }, variant: TargetPlatformVariant.only(.iOS));

  testWidgets('A predicate that keeps S1 removes only S2 and pushes Done above the shell', (tester) async {
    final nested = await openShellWithS1S2(tester);

    final frames = await pushDoneKeeping(tester, nested, 'S1');
    expect(tester.takeException(), isNull);
    // S2 is removed, not animated out, and S1 is under Done while it slides in.
    expect(frames.where((frame) => frame.contains('S2')), isEmpty, reason: 'frames: $frames');
    expect(observed, containsAll(['push Done', 'remove S2']));
    expect(observed.where((event) => event.startsWith('pop')), isEmpty);
    expect(namesOf(router), ['Home', 'Shell', 'Done']);
    expect(namesOf(nested), ['S1']);
    expectTopPage(router, 'Done');

    unawaited(router.maybePop());
    await tester.pumpAndSettle();
    expectTopPage(router, 'S1');
    expect(find.text('S2'), findsNothing);

    unawaited(router.maybePop());
    await tester.pumpAndSettle();
    expectTopPage(router, 'Home');
  }, variant: TargetPlatformVariant.only(.iOS));
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(appBar: AppBar(), body: Text(name)),
);

class _NamesObserver extends AutoRouterObserver {
  _NamesObserver(this.events);

  final List<String> events;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) =>
      events.add('push ${route.settings.name ?? 'null'}');

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) =>
      events.add('pop ${route.settings.name ?? 'null'}');

  @override
  void didRemove(Route<Object?> route, Route<Object?>? previousRoute) =>
      events.add('remove ${route.settings.name ?? 'null'}');
}
