import 'dart:async';

import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// How many shells a link goes through before its page, each with a nested
// router of its own.
const _depth = 3;

AutoRoute _page(String name, String path) => .new(
  page: PageInfo(name, builder: (_) => Text(name)),
  path: path,
);

// Level0 holds Level1 and so on; the last level is a page.
AutoRoute _level(int depth) {
  final path = '${depth == 0 ? '/' : ''}level$depth/:id$depth';
  if (depth == _depth - 1) return _page('Level$depth', path);
  return .new(
    page: PageInfo.emptyShell('Level$depth'),
    path: path,
    children: [_level(depth + 1)],
  );
}

RootStackRouter _buildRouter() => .build(
  routes: [
    _page('HomeRoute', '/'),
    _page('DetailsRoute', '/details'),
    _level(0),
  ],
);

String _link(int id) =>
    '/${[for (var depth = 0; depth < _depth; depth++) 'level$depth/$id'].join('/')}';

/// Allocates garbage until the VM has run two full collections.
///
/// The VM raises [reachabilityBarrier] after each full collection, which
/// clears weak references to objects nothing else holds.
Future<void> _collectGarbage() async {
  final barrier = reachabilityBarrier;
  final garbage = <List<DateTime>>[];
  while (reachabilityBarrier < barrier + 2) {
    garbage.add(List.generate(30000, DateTime.new));
    if (garbage.length > 100) garbage.removeAt(0);
    await Future<void>.delayed(.zero);
  }
}

void main() {
  // A memory probe found the Dart heap growing by one set of nested routers,
  // with their navigators and page widgets, on every link through nested
  // routers, and by one page on every replaceAll.
  // Steps: open a link through three nested routers, navigate to '/', then
  // do the same with a second link, and collect garbage.
  // Happened: the first link's nested routers stayed in memory for good. The
  // future of each navigation never completed once a later navigation removed
  // its page, so the calls awaiting it stayed suspended, holding the pages and
  // routers they worked with, and each held the one before.
  // Should: nothing holds the nested routers of a link the app left.
  testWidgets(
    'The nested routers of a link are garbage collected once the app leaves it',
    (tester) async {
      final router = _buildRouter();
      await pumpRouterApp(tester, router);
      late final WeakReference<RoutingController> nested;
      unawaited(router.navigatePath(_link(1)));
      await tester.pumpAndSettle();
      expect(find.text('Level${_depth - 1}'), findsOneWidget);
      // In a closure, so no local variable of this test holds the router.
      () {
        nested = WeakReference(router.innerRouterOf<StackRouter>('Level0')!);
      }();
      unawaited(router.navigatePath('/'));
      await tester.pumpAndSettle();
      unawaited(router.navigatePath(_link(2)));
      await tester.pumpAndSettle();
      unawaited(router.navigatePath('/'));
      await tester.pumpAndSettle();
      expect(find.text('HomeRoute'), findsOneWidget);

      await tester.runAsync(_collectGarbage);
      expect(nested.target, isNull);
    },
    // Web has no reachabilityBarrier to wait for a full collection on.
    skip: kIsWeb,
  );

  // Steps: replaceAll with DetailsRoute, then HomeRoute, twice, and collect
  // garbage.
  // Happened: the first DetailsRoute page stayed in memory for good, held by
  // the replaceAll that replaced it, which waited on a page that never told it
  // it was gone.
  // Should: nothing holds a page replaceAll replaced.
  testWidgets('The pages replaceAll replaces are garbage collected', (
    tester,
  ) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    late final WeakReference<AutoRoutePage<Object?>> replaced;
    unawaited(router.replaceAll([const NamedRoute('DetailsRoute')]));
    await tester.pumpAndSettle();
    () {
      replaced = WeakReference(router.topPage!);
    }();
    for (final name in ['HomeRoute', 'DetailsRoute', 'HomeRoute']) {
      unawaited(router.replaceAll([NamedRoute(name)]));
      await tester.pumpAndSettle();
    }
    expect(find.text('HomeRoute'), findsOneWidget);

    await tester.runAsync(_collectGarbage);
    expect(replaced.target, isNull);
  }, skip: kIsWeb);

  // Steps: keep the futures of a link through nested routers, of a navigation
  // to '/' and of a replaceAll; then navigate to '/' once more, and replaceAll
  // with DetailsRoute and then HomeRoute.
  // Happened: none completed, though each one's page had left the stack.
  // Should: each completes once its page leaves the stack, as a removed
  // route's future does in Flutter. A navigation that reaches the screen
  // already shown keeps it, so its future stays pending until the screen
  // leaves, as Flutter's Navigator keeps a route, with its future, for a page
  // of the same type and key.
  testWidgets(
    'The future of a navigation completes once its page leaves the stack',
    (tester) async {
      final router = _buildRouter();
      await pumpRouterApp(tester, router);
      final completed = <String>[];
      void track(String name, Future<void> future) =>
          unawaited(future.then((_) => completed.add(name)));

      track('link', router.navigatePath(_link(1)));
      await tester.pumpAndSettle();
      track('home', router.navigatePath('/'));
      await tester.pumpAndSettle();
      expect(completed, ['link']);

      track('home again', router.navigatePath('/'));
      await tester.pumpAndSettle();
      expect(completed, isNot(contains('home')));

      track(
        'replaceAll',
        router.replaceAll([const NamedRoute('DetailsRoute')]),
      );
      await tester.pumpAndSettle();
      expect(completed, ['link', 'home', 'home again']);
      unawaited(router.replaceAll([const NamedRoute('HomeRoute')]));
      await tester.pumpAndSettle();
      expect(completed, ['link', 'home', 'home again', 'replaceAll']);
    },
  );
}
