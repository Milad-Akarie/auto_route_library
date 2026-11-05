import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// The predictive back gesture pops the root page above a nested stack.
// https://github.com/flutter/flutter/issues/152323 (interleaved nested
// Navigators and predictive back).
// Headless test: auto_route/test/predictive_back_nested_under_root_test.dart
//
// Setup, as in the report: predictive back on, a host page whose nested
// router starts on a first page, and a root page pushed on top of the host.
// Steps: push a second page into the nested router, push the root page, then
// make the back gesture the way the engine sends it.
// Reported (Flutter): the nested router's second page took the gesture, so
// the user saw nothing happen.
// Should: the gesture pops the root page, and the nested router keeps its
// two pages.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the predictive back gesture pops the root page above a nested stack',
    (tester) async {
      final router = RootStackRouter.build(
        defaultRouteType: const RouteType.material(
          enablePredictiveBackGesture: true,
        ),
        routes: [
          AutoRoute(
            page: PageInfo('HostRoute', builder: (_) => const AutoRouter()),
            path: '/',
            children: [
              AutoRoute(page: _page('FirstRoute'), path: '', initial: true),
              AutoRoute(page: _page('SecondRoute'), path: 'second'),
            ],
          ),
          AutoRoute(page: _page('TopRoute'), path: '/top'),
        ],
      );
      await pumpRouterApp(tester, router, theme: ThemeData(platform: .android));
      final host = router.innerRouterOf<StackRouter>('HostRoute')!;
      unawaited(host.push(const _Route('SecondRoute')));
      await tester.pumpAndSettle();
      unawaited(router.push(const _Route('TopRoute')));
      await tester.pumpAndSettle();

      Future<void> send(String method, [Map<String, Object?>? arguments]) {
        final message = const StandardMethodCodec().encodeMethodCall(
          MethodCall(method, arguments),
        );
        return tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          SystemChannels.backGesture.name,
          message,
          (_) {},
        );
      }

      Map<String, Object?> event(double x, double progress) => {
        'touchOffset': [x, 300.0],
        'progress': progress,
        'swipeEdge': 0,
      };
      await send('startBackGesture', event(5, 0));
      await tester.pump();
      await send('updateBackGestureProgress', event(150, 0.5));
      await tester.pump();
      await send('commitBackGesture');
      await tester.pumpAndSettle();

      expect(router.stack.map((page) => page.routeData.name), ['HostRoute']);
      expect(host.stack.map((page) => page.routeData.name), [
        'FirstRoute',
        'SecondRoute',
      ]);
      expectTopPage(router, 'SecondRoute');
    },
  );
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
