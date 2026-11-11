import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/194447.
// Setup: the deep link /details stacks DetailsRoute on HomeRoute at once, as
// auto_route does with prefix matches, so HomeRoute is never laid out. Both
// pages have a Scaffold. Plain Flutter with initialRoute: '/details' fails
// the same way.
// Steps: on Android, show a SnackBar on DetailsRoute, then start a
// predictive back gesture.
// Today ScaffoldMessenger builds the SnackBar into HomeRoute's Scaffold too,
// inside a Hero that flies on user gestures. The gesture starts a hero flight
// that measures that Hero, never laid out, and Flutter asserts
// 'box.hasSize && box.size.isFinite' (in release: "RenderBox was not laid
// out"). auto_route cannot lay out a covered page without building its
// whole subtree on screen; an app avoids it by opening the deep link without
// prefix matches, so no page sits under it.
// If this test fails after a Flutter upgrade, Flutter no longer measures a
// Hero that was never laid out: drop this canary.
void main() {
  testWidgets(
    'a predictive back over a page never laid out asserts on the SnackBar hero',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HomeRoute',
              builder: (_) => const Scaffold(body: Text('HomeRoute')),
            ),
          ),
          AutoRoute(
            path: '/details',
            page: PageInfo(
              'DetailsRoute',
              builder: (_) => Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Hello'))),
                    child: const Text('show'),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
      await pumpRouterApp(tester, router, initialLink: '/details');
      expect(router.stack.map((page) => page.name), [
        'HomeRoute',
        'DetailsRoute',
      ]);
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();

      await _sendBackGesture(tester, 'startBackGesture');
      await tester.pump();
      expect(
        tester.takeException(),
        isA<AssertionError>().having(
          (error) => '$error',
          'text',
          contains('box.hasSize && box.size.isFinite'),
        ),
      );
      await _sendBackGesture(tester, 'cancelBackGesture');
      await tester.pumpAndSettle();
      expect(router.topRoute.name, 'DetailsRoute');
    },
    variant: TargetPlatformVariant.only(.android),
  );
}

Future<void> _sendBackGesture(WidgetTester tester, String method) {
  final arguments = method == 'startBackGesture'
      ? <String, Object>{
          'touchOffset': <double>[5, 300],
          'progress': 0.0,
          'swipeEdge': 0,
        }
      : null;
  return tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
    null,
  );
}
