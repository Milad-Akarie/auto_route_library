import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../details_args.dart';
import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1997
// Setup, as in the report: auto_route 8.3.0, VS Code. It failed on Windows
// only, not on Android, and the maintainer could not reproduce it. A page with
// a required argument is open when the widget inspector's select mode is
// turned on.
// Steps: push DetailsRoute with args, then turn the inspector on. That makes
// WidgetsApp wrap its tree in a WidgetInspector, a new ancestor that mounts
// the Router again. The select button turns on the binding's inspector
// override, which the test does directly.
// Reported: the error says PostRouteArgs can not be null because the page has
// a required parameter, thrown from RootStackRouter._pageBuilder.
// Should: the stack stays Home, Details, and Details still shows its args.
// remounted_app_keeps_args_test.dart covers a remount by a wrapper widget.
// This one turns on the real inspector wrapper.
void main() {
  testWidgets('Turning the widget inspector on keeps pages and their args', (
    tester,
  ) async {
    addTearDown(
      () =>
          WidgetsBinding
                  .instance
                  .debugShowWidgetInspectorOverrideNotifier
                  .value =
              false,
    );
    var detailsBuilds = 0;
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          initial: true,
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        NamedRouteDef(
          name: 'DetailsRoute',
          path: '/details',
          builder: (_, data) {
            detailsBuilds++;
            return Scaffold(
              body: Text('Details ${data.argsAs<DetailsArgs>().id}'),
            );
          },
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    unawaited(
      router.push(const NamedRoute('DetailsRoute', args: DetailsArgs(id: 7))),
    );
    await tester.pumpAndSettle();
    final buildsBefore = detailsBuilds;

    WidgetsBinding.instance.debugShowWidgetInspectorOverrideNotifier.value =
        true;
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(router.stack.map((page) => page.name), [
      'HomeRoute',
      'DetailsRoute',
    ]);
    expect(find.text('Details 7'), findsOneWidget);
    expect(
      detailsBuilds,
      buildsBefore,
      reason: 'after the inspector override was turned on',
    );
  });
}
