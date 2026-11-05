import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../named_page.dart';
import '../no_op.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1668
  // On a cold start from a link, iOS first hands the app '/' and then the
  // link. The app opened the link's pages, then _MainRoute came back on top
  // of them once the guard of the first '/' navigation, still waiting,
  // called resolver.next().
  // Steps: an async deepLinkBuilder returns '/' as it is and turns
  // '/info?id=1' into DeepLink([_MainRoute, InfoRoute]); MainRoute's guard
  // waits 10 seconds the first time and 1 second after; the link comes while
  // the first wait runs.
  // Should: the stack ends as [_MainRoute, InfoRoute] with InfoRoute on screen.
  testWidgets('A link that comes while the first page waits on its guard keeps its pages', (tester) async {
    var mainGuardCalls = 0;
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'MainRoute',
          path: '/',
          guards: [
            AutoRouteGuard.simple((resolver, _) async {
              final wait = mainGuardCalls++ == 0 ? 10 : 1;
              await Future<void>.delayed(Duration(seconds: wait));
              resolver.next();
            }),
          ],
          builder: (_, _) => const NamedPage('MainRoute'),
        ),
        NamedRouteDef(
          name: 'InfoRoute',
          path: '/info',
          guards: [
            AutoRouteGuard.simple((resolver, _) async {
              await Future<void>.delayed(const Duration(seconds: 1));
              resolver.next();
            }),
          ],
          builder: (_, data) => NamedPage('InfoRoute ${data.queryParams.optString('id') ?? 'null'}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routeInformationParser: router.defaultRouteParser(),
        routerDelegate: router.delegate(
          deepLinkBuilder: (link) async {
            if (link.path != '/info') return link;
            return DeepLink([const _MainRoute(), NamedRoute('InfoRoute', queryParams: link.uri.queryParameters)]);
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    _sendPlatformLink(tester, '/info?id=1');
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(router.stack.map((p) => p.name), ['MainRoute', 'InfoRoute']);
    expect(find.text('InfoRoute 1'), findsOneWidget);
  });
}

class _MainRoute extends PageRouteInfo<void> {
  const new() : super('MainRoute');
}

// Hands [location] to the app the way the engine does when the platform
// opens a link, without waiting for the app to finish with it.
void _sendPlatformLink(WidgetTester tester, String location) {
  const codec = JSONMethodCodec();
  unawaited(
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.navigation.name,
      codec.encodeMethodCall(MethodCall('pushRouteInformation', {'location': location, 'state': null})),
      ignoreArgument,
    ),
  );
}
