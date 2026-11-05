import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/40514: a
// CupertinoThemeData whose navActionTextStyle keeps the default
// `inherit: true` breaks the navigation bar transition between two pages.
// Setup, without auto_route: a CupertinoApp whose theme sets
// `navActionTextStyle: TextStyle(color: red)`, two CupertinoPageRoutes, each
// with a CupertinoNavigationBar.
// Steps: push the second page.
// Today, on Flutter 3.47.9 with cupertino_ui 1.1.6: the nav bar's flight
// lerps the first page's title style (inherit: false) into the back label's
// navActionTextStyle (inherit: true), and TextStyle.lerp asserts that both
// have the same inherit (flutter/lib/src/painting/text_style.dart,
// `TextStyle.lerp`). The workaround in the thread is `inherit: false`.
// auto_route's RouteType.cupertino pages run the same nav bar transition. If
// this test fails after a Flutter upgrade, the transition now copes with the
// style: drop this canary.
void main() {
  // Pushes the second page and returns what its transition threw.
  Future<List<Object>> pushWithNavActionStyle(
    WidgetTester tester, {
    required bool isInherited,
  }) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      CupertinoApp(
        navigatorKey: navigatorKey,
        theme: CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            navActionTextStyle: TextStyle(
              color: const Color(0xFFFF0000),
              inherit: isInherited,
            ),
          ),
        ),
        home: const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(middle: Text('First')),
          child: SizedBox(),
        ),
      ),
    );
    navigatorKey.currentState!.push(
      CupertinoPageRoute<void>(
        builder: (_) => const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text('Second'),
            previousPageTitle: 'First',
          ),
          child: SizedBox(),
        ),
      ),
    );
    // A frame can throw more than once, which the test binding reports as a
    // failure of its own, so the errors are collected here instead.
    final thrown = <Object>[];
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) => thrown.add(details.exception);
    try {
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = reportError;
    }
    return thrown;
  }

  testWidgets(
    'a navActionTextStyle with inherit true makes the nav bar transition '
    'assert, until Flutter fixes flutter/flutter#40514',
    (tester) async {
      final thrown = await pushWithNavActionStyle(tester, isInherited: true);
      expect(thrown.map((error) => '$error'), anyElement(contains('inherit')));
    },
    // The nav bar throws while it builds, so Flutter never disposes what that
    // build made.
    experimentalLeakTesting: LeakTesting.settings.withIgnoredAll(),
  );

  testWidgets('the control: inherit false throws nothing', (tester) async {
    expect(await pushWithNavActionStyle(tester, isInherited: false), isEmpty);
  });
}
