import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';

// https://github.com/flutter/flutter/issues/139398
// Setup: the app starts on a splash page, then goes to the home page, which
// holds four tabs; a profile page is pushed at the root above it.
// Steps: the splash page replaces itself with the home page, as the report's
// router.go does (auto_route's navigate keeps the splash page below); push the
// profile page and press back; press back again on the tab's first page.
// Should: the first back pops the profile page; the second leaves the app:
// Flutter tells Android it doesn't handle back, so Android closes the app.
void main() {
  for (final MapEntry(key: name, value: back) in {
    'system back': systemBack,
    'the predictive back gesture': predictiveBack,
  }.entries) {
    testWidgets('After the splash page, $name on a tab pops pushed pages, then leaves the app', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(path: '/splash', page: _page('SplashRoute'), initial: true),
          AutoRoute(
            path: '/home',
            page: PageInfo('HomeRoute', builder: (_) => AutoTabsRouter(routes: [for (final tab in _tabs) _Route(tab)])),
            children: [for (final tab in _tabs) AutoRoute(path: tab.toLowerCase(), page: _page(tab))],
          ),
          AutoRoute(path: '/profile', page: _page('ProfileRoute')),
        ],
      );
      addTearDown(router.dispose);
      final frameworkHandlesBack = FrameworkHandlesBackRecorder()..listen(tester);
      await tester.pumpWidget(MaterialApp.router(theme: androidTheme, routerConfig: router.config()));
      await tester.pumpAndSettle();
      expect(find.text('SplashRoute'), findsOneWidget);

      unawaited(router.replaceAll([const _Route('HomeRoute')]));
      await tester.pumpAndSettle();
      expect(find.text('Explore'), findsOneWidget);
      expect(router.stack.map((page) => page.name), ['HomeRoute']);
      expect(frameworkHandlesBack.last, isFalse);

      unawaited(router.push(const _Route('ProfileRoute')));
      await tester.pumpAndSettle();
      expect(frameworkHandlesBack.last, isTrue);
      await back(tester);
      expect(find.text('Explore'), findsOneWidget);
      expect(frameworkHandlesBack.last, isFalse);
      expect(router.canPop(), isFalse);
    }, skip: kIsWeb); // Android only: on web Flutter never tells the platform whether it handles back.
  }
}

const _tabs = ['Explore', 'Dialogs', 'Notifications', 'Settings'];

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}
