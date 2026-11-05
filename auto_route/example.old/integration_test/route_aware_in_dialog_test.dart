import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A widget with AutoRouteAwareStateMixin shows in a dialog without throwing.
// flutter/flutter#62023
// Headless test: auto_route/test/route_aware_in_dialog_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('route aware in dialog', () {
    // Steps: an app with an AutoRouteObserver taps a button that opens a
    // dialog showing a route aware widget, then closes the dialog.
    // Should: the widget shows, the dialog closes, and nothing throws.
    testWidgets('a route aware widget in a dialog shows without throwing', (
      tester,
    ) async {
      final router = RootStackRouter.build(
        routes: [AutoRoute(page: _HomeRoute.page, path: '/', initial: true)],
      );
      await pumpRouterApp(
        tester,
        router,
        navigatorObservers: () => [AutoRouteObserver()],
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Aware'), findsOneWidget);

      router.navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expectCurrentPage(router, _HomeRoute.name);
    });
  });
}

class _HomeRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Builder(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const Text(name),
              ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _AwareText(),
                ),
                child: const Text('Open dialog'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AwareText extends StatefulWidget {
  const new();

  @override
  State<_AwareText> createState() => _AwareTextState();
}

class _AwareTextState extends State<_AwareText>
    with AutoRouteAwareStateMixin<_AwareText> {
  @override
  Widget build(BuildContext context) => const Text('Aware');
}
