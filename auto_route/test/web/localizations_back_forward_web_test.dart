@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../named_page.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  setUp(rewindBrowserHistory);

  // https://github.com/Milad-Akarie/auto_route_library/issues/964
  // Reported on web: with localizationsDelegates on MaterialApp.router, the
  // browser's back and forward stopped working after a reload.
  // Steps: an app with an async localizations delegate, as generated
  // localizations are, and the Material and Widgets delegates; HomeRoute
  // '/home_page' (initial), LoginRoute '/login_page' and RedirectRoute('*').
  // Navigate to LoginRoute, go back and forward; reload on LoginRoute, then
  // go back and forward again.
  // Should: each step shows the page of the url the browser moved to.
  testWidgets('On web, back and forward work with localizations delegates, before and after a reload', (tester) async {
    RootStackRouter buildRouter() => .build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/home_page',
          initial: true,
          builder: (_, _) => const NamedPage('HomeRoute'),
        ),
        NamedRouteDef(name: 'LoginRoute', path: '/login_page', builder: (_, _) => const NamedPage('LoginRoute')),
        RedirectRoute(path: '*', redirectTo: '/home_page'),
      ],
    );
    Future<RootStackRouter> startApp() async {
      final router = buildRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [
            _AsyncStrings.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          routerConfig: router.config(),
        ),
      );
      await settleBrowser(tester);
      return router;
    }

    final router = await startApp();
    expect(find.text('HomeRoute'), findsOneWidget);
    unawaited(router.navigate(const NamedRoute('LoginRoute')));
    await settleBrowser(tester);
    expect(browserPath, '/login_page');

    await pressBrowserBack(tester);
    expect(find.text('HomeRoute'), findsOneWidget, reason: 'after pressBrowserBack(tester)');
    expect(browserPath, '/home_page');
    await pressBrowserForward(tester);
    expect(find.text('LoginRoute'), findsOneWidget);
    expect(browserPath, '/login_page', reason: 'after pressBrowserForward(tester)');

    // A reload starts a new app at the browser's url, with the history kept.
    await tester.pumpWidget(const SizedBox());
    openBrowserAt(tester, '/login_page');
    await startApp();
    expect(find.text('LoginRoute'), findsOneWidget, reason: 'after startApp()');

    await pressBrowserBack(tester);
    expect(find.text('HomeRoute'), findsOneWidget, reason: 'after pressBrowserBack(tester) in the reloaded app');
    expect(browserPath, '/home_page', reason: 'after pressBrowserBack(tester)');
    await pressBrowserForward(tester);
    expect(find.text('LoginRoute'), findsOneWidget, reason: 'after pressBrowserForward(tester)');
    expect(browserPath, '/login_page', reason: 'after pressBrowserForward(tester) in the reloaded app');
    expect(tester.takeException(), isNull);
  });
}

// Loads after a delay, as generated localizations that read assets do.
class _AsyncStrings {
  static const delegate = _AsyncStringsDelegate();
}

class _AsyncStringsDelegate extends LocalizationsDelegate<_AsyncStrings> {
  const new();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<_AsyncStrings> load(Locale locale) => .delayed(const Duration(milliseconds: 50), _AsyncStrings.new);

  @override
  bool shouldReload(_AsyncStringsDelegate old) => false;
}
