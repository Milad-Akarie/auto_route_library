import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/40583:
// the back button of a CupertinoNavigationBar says "Back" whenever the
// previous page's title is longer than 12 characters, even when the title
// fits. Native iOS shows the title while there is room for it.
// Setup, without auto_route: a CupertinoApp on an 800 pixel wide screen, a
// first CupertinoPageRoute titled "Keyboard Settings" (17 characters) and a
// second one titled "Edit" whose CupertinoNavigationBar implies its leading.
// Steps: push the second page.
// Today, on Flutter 3.47.9 with cupertino_ui 1.1.6: the back button reads
// "Back" though half the bar is empty; a 12 character title is shown as is.
// The rule is in cupertino_ui lib/src/nav_bar.dart:2418,
// `_BackLabel._buildPreviousTitleWidget`.
// auto_route passes RouteData.title, by default the route's name, as the
// Cupertino route's title, so a page under "SettingsRoute" (13 characters)
// gets "Back" too. If this test fails after a Flutter upgrade, Flutter now
// measures the room for the title: drop this canary.
void main() {
  Future<void> pushOver(WidgetTester tester, String previousTitle) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      CupertinoApp(
        navigatorKey: navigatorKey,
        onGenerateRoute: (_) => CupertinoPageRoute<void>(
          title: previousTitle,
          builder: (_) => const CupertinoPageScaffold(child: SizedBox()),
        ),
      ),
    );
    navigatorKey.currentState!.push(
      CupertinoPageRoute<void>(
        title: 'Edit',
        builder: (_) => const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(),
          child: SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a previous title over 12 characters reads "Back" though it fits, until '
    'Flutter fixes flutter/flutter#40583',
    (tester) async {
      await pushOver(tester, 'Keyboard Settings');
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Keyboard Settings'), findsNothing);
    },
  );

  testWidgets('the control: a 12 character previous title is shown', (
    tester,
  ) async {
    await pushOver(tester, 'Keyboard Set');
    expect(find.text('Keyboard Set'), findsOneWidget);
    expect(find.text('Back'), findsNothing);
  });

  testWidgets(
    'an auto_route page under SettingsRoute reads "Back", since its default '
    'title is the route name',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = RootStackRouter.build(
        defaultRouteType: const RouteType.cupertino(),
        routes: [
          AutoRoute(page: _settings, path: '/'),
          AutoRoute(page: _edit, path: '/edit'),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        CupertinoApp.router(routerConfig: router.config()),
      );
      await tester.pumpAndSettle();
      unawaited(router.pushPath('/edit'));
      await tester.pumpAndSettle();
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('SettingsRoute'), findsNothing);
    },
  );
}

final _settings = PageInfo(
  'SettingsRoute',
  builder: (_) => const CupertinoPageScaffold(child: SizedBox()),
);

final _edit = PageInfo(
  'EditRoute',
  builder: (_) => const CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(),
    child: SizedBox(),
  ),
);
