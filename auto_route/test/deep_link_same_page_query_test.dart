import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';
import 'universal_link_test.dart' show sendPlatformLink;

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/608
  // Reported: a deep link to the page already open, with new query params,
  // as '/login?otp=1' then '/login?otp=2', had no effect.
  // Steps: send '/login?otp=1', then '/login?otp=2' from the platform, then
  // navigatePath('/login?otp=3').
  // Should: the open LoginRoute shows each new otp and the url carries it.
  testWidgets('A link to the open page with new query params updates the page', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(name: 'HomeRoute', path: '/', builder: (_, _) => _page('HomeRoute')),
        NamedRouteDef(
          name: 'LoginRoute',
          path: '/login',
          builder: (_, data) => _page('otp ${data.queryParams.optString('otp') ?? 'null'}'),
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());

    await sendPlatformLink(tester, '/login?otp=1');
    expect(find.text('otp 1'), findsOneWidget);

    await sendPlatformLink(tester, '/login?otp=2');
    expect(find.text('otp 2'), findsOneWidget);
    expect(router.urlState.url, '/login?otp=2');

    unawaited(router.navigatePath('/login?otp=3'));
    await tester.pumpAndSettle();
    expect(find.text('otp 3'), findsOneWidget);
    expect(router.urlState.url, '/login?otp=3');
    expect(router.stack.map((p) => p.name), ['HomeRoute', 'LoginRoute']);
  });
}

Widget _page(String text) => Scaffold(body: Text(text));
