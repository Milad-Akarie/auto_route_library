@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  late RootStackRouter router;
  setUp(() async {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(page: _SignInRoute.page, path: '/sign-in'),
        AutoRoute(page: SecondRoute.page, path: '/forgot-password'),
      ],
    );
    await rewindBrowserHistory();
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1842
  // Push a sign-in page that takes a required argument the url can't hold,
  // push another page on top, then press the browser's back button.
  // The sign-in page should show again with its argument, not fail to build.
  testWidgets(
    'The browser back button on web returns to a page with its required '
    'argument',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      unawaited(router.push(_SignInRoute(email: 'sam@example.com')));
      await settleBrowser(tester);
      expect(find.text('Sign in as sam@example.com'), findsOneWidget);
      unawaited(router.push(const SecondRoute()));
      await settleBrowser(tester);

      await pressBrowserBack(tester);
      expect(tester.takeException(), isNull);
      expect(router.current.name, _SignInRoute.name);
      expect(
        find.text('Sign in as sam@example.com'),
        findsOneWidget,
        reason: 'after pressBrowserBack(tester)',
      );
      expect(browserPath, '/sign-in');
    },
  );

  testWidgets(
    'The browser forward button on web reopens a page with its required '
    'argument',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      unawaited(router.push(_SignInRoute(email: 'sam@example.com')));
      await settleBrowser(tester);
      await pressBrowserBack(tester);
      expectCurrentPage(router, FirstRoute.name);

      await browserMove(tester, router.navigationHistory.forward);
      expect(tester.takeException(), isNull);
      expect(find.text('Sign in as sam@example.com'), findsOneWidget);
    },
  );
}

class _SignInArgs {
  const new(this.email);

  final String email;
}

class _SignInRoute extends PageRouteInfo<_SignInArgs> {
  new({required String email}) : super(name, args: _SignInArgs(email));

  static const String name = 'SignInRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (data) =>
        Scaffold(body: Text('Sign in as ${data.argsAs<_SignInArgs>().email}')),
  );
}
