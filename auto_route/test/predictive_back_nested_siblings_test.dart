import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';
import 'router_test_utils.dart';

// Reported as https://github.com/Milad-Akarie/auto_route_library/issues/2249
// (auto_route 10.1.2; the maintainer asked for a retest on 10.2.2).
// Setup, as in the report: Android with predictive back
// (enablePredictiveBackGesture), a root route '/' (LoggedIn) holding a nested
// router with Home (initial, path '') and siblings Settings and Details.
// Steps: push Settings, then Details in the nested router; make the
// predictive back gesture, once up to and past the threshold without
// letting go, and once letting go.
// Happened: (1) past the threshold the page being popped vanished and the
// page behind it was a black screen; (2) back always ended on Home however
// deep the stack.
// Should: (1) while the gesture is held, both Details and Settings are on
// screen; (2) the gesture pops only Details, leaving Home, Settings.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      defaultRouteType: const RouteType.material(
        enablePredictiveBackGesture: true,
      ),
      routes: [
        AutoRoute(
          page: PageInfo('LoggedIn', builder: (_) => const AutoRouter()),
          path: '/',
          children: [
            AutoRoute(page: _page('Home'), path: '', initial: true),
            AutoRoute(page: _page('Settings'), path: 'settings'),
            AutoRoute(page: _page('Details'), path: 'details'),
          ],
        ),
      ],
    );
  });

  Future<void> openDetails(WidgetTester tester) async {
    await pumpRouterConfigApp(tester, router.config());
    final nested = router.innerRouterOf<StackRouter>('LoggedIn')!;
    unawaited(nested.push(const NamedRoute('Settings')));
    await tester.pumpAndSettle();
    unawaited(nested.push(const NamedRoute('Details')));
    await tester.pumpAndSettle();
  }

  List<String?> nestedNames() => router
      .innerRouterOf<StackRouter>('LoggedIn')!
      .stack
      .map((page) => page.routeData.name)
      .toList();

  Future<void> sendBackGesture(
    WidgetTester tester,
    String method, [
    Map<String, Object?>? arguments,
  ]) => tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.backGesture.name,
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
    null,
  );

  Map<String, Object?> event(double x, double progress) => {
    'touchOffset': [x, 300.0],
    'progress': progress,
    'swipeEdge': 0,
  };

  testWidgets('past the threshold the page behind is still on screen', (
    tester,
  ) async {
    await openDetails(tester);

    await sendBackGesture(tester, 'startBackGesture', event(5, 0));
    await tester.pump();
    await sendBackGesture(tester, 'updateBackGestureProgress', event(200, 0.8));
    await tester.pump();

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await sendBackGesture(tester, 'cancelBackGesture');
    await tester.pumpAndSettle();
    expect(nestedNames(), ['Home', 'Settings', 'Details']);
  });

  testWidgets('the gesture pops only the top page of the nested router', (
    tester,
  ) async {
    await openDetails(tester);

    await predictiveBack(tester);

    expect(nestedNames(), ['Home', 'Settings']);
    expect(find.text('Settings'), findsOneWidget);
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
