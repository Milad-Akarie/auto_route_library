import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// The browser's back button returns to a page with its required argument.
// https://github.com/Milad-Akarie/auto_route_library/issues/1842
// Headless test: auto_route/test/web/required_args_web_test.dart
//
// Runs only on web, the one platform with a browser back button.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(page: _SignInRoute.page, path: '/sign-in'),
        AutoRoute(page: SecondRoute.page, path: '/forgot-password'),
      ],
    );
  });

  // Steps: push a sign-in page with a required argument the url can't hold,
  // push another page on top, then press the browser's back button.
  // Should: the sign-in page shows again with its argument.
  testWidgets(
    'The browser back button returns to a page with its required argument',
    (tester) async {
      await pumpRouterAppWithConfig(tester, router);
      unawaited(router.push(_SignInRoute(email: 'sam@example.com')));
      await tester.pumpAndSettle();
      unawaited(router.push(const SecondRoute()));
      await tester.pumpAndSettle();
      await expectBrowserUrl('/forgot-password');

      pressBrowserBack();
      await expectBrowserUrl('/sign-in');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Sign in as sam@example.com'), findsOneWidget);
    },
    skip: !kIsWeb,
  );
}

class _SignInArgs {
  const new(this.email);

  final String email;
}

class _SignInRoute extends PageRouteInfo<_SignInArgs> {
  new({required String email}) : super(name, args: _SignInArgs(email));

  static const String name = 'SignInRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) =>
        Scaffold(body: Text('Sign in as ${data.argsAs<_SignInArgs>().email}')),
  );
}
