import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// popAndPush from a bottom sheet route while it slides in.
// https://github.com/Milad-Akarie/auto_route_library/issues/1813
// Headless test: auto_route/test/simple_router/pop_and_push_from_animating_modal_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      defaultRouteType: const RouteType.adaptive(),
      routes: [
        AutoRoute(path: '/', page: _First1Route.page),
        CustomRoute(
          path: '/modal',
          page: _Modal1Route.page,
          customRouteBuilder: _modalSheetBuilder,
        ),
      ],
    );
  });

  // Steps: First1Route pushes Modal1Route, a CustomRoute shown in a
  // ModalBottomSheetRoute. While the sheet slides in, tap its button, which
  // calls context.router.popAndPush(First1Route()).
  // Should: the sheet closes and a new First1Route opens, with no error.
  testWidgets('popAndPush from a modal while it slides in', (tester) async {
    await pumpRouterApp(tester, router);
    await tester.tap(find.text('Open modal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    await tester.tap(find.text('Test'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (router.stack.length == 2 && router.current.name == _Modal1Route.name) {
      // The sheet wasn't under the finger yet on this device; tap it once it's up.
      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();
    }
    expect(router.stack.map((p) => p.name), [
      _First1Route.name,
      _First1Route.name,
    ]);
    expect(find.text('Test'), findsNothing);
  });
}

Route<T> _modalSheetBuilder<T>(
  BuildContext _,
  Widget child,
  AutoRoutePage<T> page,
) {
  return ModalBottomSheetRoute(
    settings: page,
    builder: (context) => child,
    isScrollControlled: true,
  );
}

class _First1Route extends PageRouteInfo<void> {
  const _First1Route() : super(name);

  static const String name = 'First1Route';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Builder(
      builder: (context) => Scaffold(
        body: Align(
          child: FilledButton(
            onPressed: () => context.pushRoute(const _Modal1Route()),
            child: const Text('Open modal'),
          ),
        ),
      ),
    ),
  );
}

class _Modal1Route extends PageRouteInfo<void> {
  const _Modal1Route() : super(name);

  static const String name = 'Modal1Route';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Builder(
      builder: (context) => Column(
        mainAxisSize: .min,
        children: [
          const SizedBox(height: 64),
          SizedBox(
            width: .infinity,
            child: FilledButton(
              onPressed: () => context.router.popAndPush(const _First1Route()),
              child: const Text('Test'),
            ),
          ),
          const SizedBox(height: 64),
        ],
      ),
    ),
  );
}
