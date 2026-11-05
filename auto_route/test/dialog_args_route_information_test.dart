import 'dart:async';
import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

/// An argument that, like the reporter's ProfileEntity, has no toJson.
class _Profile {
  const new(this.name);
  final String name;
}

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1390
  // Steps (web, auto_route 6.0.0-rc-2): a route shown as a dialog, through a
  // customRouteBuilder that returns a DialogRoute, opened with an argument
  // that is an app class without toJson.
  // Reported: "Converting object to an encodable object failed: Instance of
  // 'ProfileEntity'", thrown when the router told the platform the new
  // route, because the route information's state held the argument. The
  // dialog still opened.
  // Should: the platform is told a state that encodes as JSON, as the
  // channel does, and the dialog opens with its argument.
  testWidgets(
    'A dialog route opened with an argument reports a state that encodes',
    (tester) async {
      final reported = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.navigation,
        (call) async {
          if (call.method == 'routeInformationUpdated') {
            reported.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.navigation,
          null,
        ),
      );
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
              builder: (data) =>
                  AlertDialog(content: Text('Profile ${_profileName(data)}')),
            ),
            customRouteBuilder: <T>(context, child, page) => DialogRoute<T>(
              context: context,
              settings: page,
              builder: (_) => child,
            ),
          ),
        ],
      );
      await pumpRouterApp(tester, router);

      unawaited(
        router.push(
          const NamedRoute('ProfileDialogRoute', args: _Profile('Sam')),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Profile Sam'), findsOneWidget);
      expect(reported, isNotEmpty);
      for (final arguments in reported) {
        expect(() => jsonEncode(arguments), returnsNormally);
      }
    },
  );
}

String _profileName(RouteData<Object?> data) {
  final args = data.args;
  return args is _Profile ? args.name : 'none';
}
