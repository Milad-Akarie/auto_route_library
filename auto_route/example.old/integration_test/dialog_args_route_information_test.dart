import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

/// An argument that, like the reporter's ProfileEntity, has no toJson.
class _Profile {
  const _Profile(this.name);
  final String name;
}

// A dialog route opened with an argument reports a route state the platform
// can encode.
// https://github.com/Milad-Akarie/auto_route_library/issues/1390
// Headless test: auto_route/test/dialog_args_route_information_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps (web): a route shown as a dialog, through a customRouteBuilder
  // that returns a DialogRoute, opened with an argument that is an app class
  // without toJson.
  // Reported: "Converting object to an encodable object failed", thrown when
  // the router told the browser the new route. The dialog still opened.
  // Should: the dialog opens with its argument, nothing is thrown, and the
  // browser shows the dialog's url.
  testWidgets(
    'A dialog route opened with an argument reports a state the platform encodes',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HomeRoute',
              builder: (_) => const Text('HomeRoute'),
            ),
          ),
          CustomRoute(
            path: '/profile',
            page: PageInfo(
              'ProfileDialogRoute',
              builder: (data) => AlertDialog(
                content: Text(
                  'Profile ${data.args is _Profile ? (data.args! as _Profile).name : 'none'}',
                ),
              ),
            ),
            customRouteBuilder: <T>(context, child, page) => DialogRoute<T>(
              context: context,
              settings: page,
              builder: (_) => child,
            ),
          ),
        ],
      );
      await pumpRouterAppWithConfig(tester, router);

      unawaited(
        router.push(
          const NamedRoute('ProfileDialogRoute', args: _Profile('Sam')),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Profile Sam'), findsOneWidget);
      await expectBrowserUrl('/profile');
    },
  );
}
