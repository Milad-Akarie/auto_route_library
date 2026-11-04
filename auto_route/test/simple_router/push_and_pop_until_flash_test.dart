import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1797
// With Home, B and C open, pushAndPopUntil(D, predicate: isHome) showed Home
// and B while D slid in: it popped C and B, and each popped page animated out.
// Like Navigator.pushAndRemoveUntil, it now removes the pages the predicate
// rejects, so only C shows under D until D covers it.
void main() {
  late RootStackRouter router;
  late List<String> observed;

  setUp(() {
    observed = [];
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Home'), initial: true),
        AutoRoute(page: _page('B')),
        AutoRoute(page: _page('C')),
        AutoRoute(page: _page('D')),
      ],
    );
  });

  Future<void> openHomeBC(WidgetTester tester, List<Future<Object?>> pushed) async {
    await pumpRouterApp(tester, router, observers: () => [_NamesObserver(observed)]);
    pushed.add(router.push(const PageRouteInfo('B')));
    await tester.pumpAndSettle();
    pushed.add(router.push(const PageRouteInfo('C')));
    await tester.pumpAndSettle();
    observed.clear();
  }

  bool isHome(Route<dynamic> route) => route.settings.name == 'Home';

  // The pages on screen, bottom to top.
  List<String> shown() => ['Home', 'B', 'C', 'D'].where((name) => find.text(name).evaluate().isNotEmpty).toList();

  // Steps: open Home, B and C on iOS, then call pushAndPopUntil(D) with a
  // predicate that keeps Home, and look at every frame while D slides in.
  testWidgets('The pages pushAndPopUntil removes never show while the new page slides in', (tester) async {
    final pushed = <Future<Object?>>[];
    await openHomeBC(tester, pushed);

    final pushedD = router.pushAndPopUntil(const PageRouteInfo('D'), predicate: isHome);
    final frames = <List<String>>[];
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      frames.add(shown());
    }
    expect(frames.where((frame) => frame.contains('Home') || frame.contains('B')), isEmpty, reason: 'frames: $frames');
    expect(frames.last, ['D']);
    expect(router.stack.map((page) => page.name), ['Home', 'D']);

    // The removed pages' push futures complete, and so does the new one's.
    var completed = 0;
    for (final future in pushed) {
      future.then((_) => completed++);
    }
    Object? resultOfD = 'unset';
    pushedD.then((result) => resultOfD = result);
    router.maybePop('done');
    await tester.pumpAndSettle();
    expect(completed, 2);
    expect(resultOfD, 'done');
    expectCurrentPage(router, 'Home');
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  // Steps: open Home, B and C, then call pushAndPopUntil(D) keeping Home.
  // Observers hear the removals, as with Navigator.pushAndRemoveUntil.
  testWidgets('Observers hear the pages pushAndPopUntil removes as removed', (tester) async {
    await openHomeBC(tester, []);

    router.pushAndPopUntil(const PageRouteInfo('D'), predicate: isHome);
    await tester.pumpAndSettle();
    expect(observed, containsAll(['push D', 'remove B', 'remove C']));
    expect(observed.where((event) => event.startsWith('pop')), isEmpty);
  });

  // Steps: open Home, B and C, call pushAndPopUntil(D) keeping Home, then
  // router.back(). The removed pages leave the history, as popped ones do.
  testWidgets('router.back() after pushAndPopUntil skips the pages it removed', (tester) async {
    await openHomeBC(tester, []);

    router.pushAndPopUntil(const PageRouteInfo('D'), predicate: isHome);
    await tester.pumpAndSettle();
    router.back();
    await tester.pumpAndSettle();
    expectCurrentPage(router, 'Home');
    expect(router.stack.map((page) => page.name), ['Home']);
    // on web, back() moves the browser's own history; test/web/push_and_pop_until_web_test.dart covers it
  }, skip: kIsWeb);

  // Steps: open Home, show a dialog on it, and from the dialog call
  // pushAndPopUntil(D) keeping Home. The dialog goes, Home stays under D.
  testWidgets('pushAndPopUntil removes a dialog above the page it keeps', (tester) async {
    await openHomeBC(tester, []);
    router.popUntilRoot();
    await tester.pumpAndSettle();
    final dialog = showDialog<Object?>(
      context: router.navigatorKey.currentContext!,
      builder: (_) => const Text('Dialog'),
    );
    await tester.pumpAndSettle();
    Object? dialogResult = 'unset';
    dialog.then((result) => dialogResult = result);

    router.pushAndPopUntil(const PageRouteInfo('D'), predicate: isHome);
    await tester.pumpAndSettle();
    expect(find.text('Dialog'), findsNothing);
    expect(dialogResult, isNull);
    expect(router.stack.map((page) => page.name), ['Home', 'D']);

    router.maybePop();
    await tester.pumpAndSettle();
    expectCurrentPage(router, 'Home');
    expect(find.text('Dialog'), findsNothing);
  });
}

PageInfo _page(String name) => PageInfo(
  name,
  builder: (_) => Scaffold(appBar: AppBar(), body: Text(name)),
);

class _NamesObserver extends NavigatorObserver {
  _NamesObserver(this.events);

  final List<String> events;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => events.add('push ${route.settings.name}');

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => events.add('pop ${route.settings.name}');

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => events.add('remove ${route.settings.name}');
}
