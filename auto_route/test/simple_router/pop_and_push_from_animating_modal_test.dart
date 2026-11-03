import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      defaultRouteType: const RouteType.adaptive(),
      routes: [
        AutoRoute(path: '/', page: _First1Route.page),
        CustomRoute(path: '/', page: _Modal1Route.page, customRouteBuilder: _modalSheetBuilder),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1813
  // The reporter's app: First1Route pushes Modal1Route, a CustomRoute shown in
  // a ModalBottomSheetRoute. Tap the modal's button, which calls
  // context.router.popAndPush(First1Route()), while the sheet is still
  // sliding in. The sheet should close and a new First1Route open, without
  // the 'renderObject.child == child' and 'Future already completed' errors.
  for (final elapsed in const [Duration(milliseconds: 120), Duration(milliseconds: 170), Duration(milliseconds: 220)]) {
    testWidgets('popAndPush from a modal ${elapsed.inMilliseconds}ms into its animation', (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      await tester.tap(find.text('Open modal'));
      await tester.pump();
      await tester.pump(elapsed);
      expect(router.stack.map((p) => p.name), [_First1Route.name, _Modal1Route.name]);
      expect(ModalRoute.of(tester.element(find.text('Test')))!.animation!.status, AnimationStatus.forward);

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(router.stack.map((p) => p.name), [_First1Route.name, _First1Route.name]);
      expect(find.text('Test'), findsNothing);
    });
  }
}

Route<T> _modalSheetBuilder<T>(BuildContext _, Widget child, AutoRoutePage<T> page) {
  return ModalBottomSheetRoute(settings: page, builder: (context) => child, isScrollControlled: true);
}

class _First1Route extends PageRouteInfo<void> {
  const _First1Route() : super(name);

  static const String name = 'First1Route';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Builder(
      builder: (context) => Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 64),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.router.popAndPush(const _First1Route()),
              child: const Text('Test'),
            ),
          ),
        ],
      ),
    ),
  );
}
