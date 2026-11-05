import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/pages.dart';

// A link that comes while the first page waits on its guard keeps its pages:
// the first navigation, once its guard lets it through, no longer opens its
// page over them.
// https://github.com/Milad-Akarie/auto_route_library/issues/1668
// Headless test: auto_route/test/guards/link_during_initial_guard_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('link during initial guard', () {
    // Steps: the app starts at '/', whose MainRoute guard waits 2 seconds the
    // first time; meanwhile the platform sends '/info?id=1', which an async
    // deepLinkBuilder turns into DeepLink([MainRoute, InfoRoute]).
    // Should: the stack ends as [MainRoute, InfoRoute] with InfoRoute on
    // screen.
    testWidgets(
      'A link that comes while the first page waits on its guard keeps its '
      'pages',
      (tester) async {
        var mainGuardCalls = 0;
        final router = RootStackRouter.build(
          routes: [
            NamedRouteDef(
              name: 'MainRoute',
              path: '/',
              guards: [
                AutoRouteGuard.simple((resolver, _) async {
                  final wait = mainGuardCalls++ == 0 ? 2000 : 100;
                  await Future<void>.delayed(Duration(milliseconds: wait));
                  resolver.next();
                }),
              ],
              builder: (_, _) => const TextPage('Main'),
            ),
            NamedRouteDef(
              name: 'InfoRoute',
              path: '/info',
              builder: (_, data) => TextPage(
                'Info ${data.queryParams.optString('id') ?? 'null'}',
              ),
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp.router(
            routeInformationParser: router.defaultRouteParser(),
            routerDelegate: router.delegate(
              deepLinkBuilder: (link) async {
                if (link.initial) return DeepLink.defaultPath;
                if (link.path != '/info') return link;
                return DeepLink([
                  const NamedRoute('MainRoute'),
                  NamedRoute(
                    'InfoRoute',
                    queryParams: link.uri.queryParameters,
                  ),
                ]);
              },
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        const codec = JSONMethodCodec();
        unawaited(
          tester.binding.defaultBinaryMessenger.handlePlatformMessage(
            SystemChannels.navigation.name,
            codec.encodeMethodCall(
              const MethodCall('pushRouteInformation', {
                'location': '/info?id=1',
                'state': null,
              }),
            ),
            null,
          ),
        );
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(router.stack.map((p) => p.name), ['MainRoute', 'InfoRoute']);
        expect(find.text('Info 1'), findsOneWidget);
      },
    );
  });
}
