import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A page closed right after its dialog animates out with it.
// flutter/flutter#111137
// Headless test: auto_route/test/dialog_then_page_animates_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/', initial: true),
        AutoRoute(page: _EditorRoute.page, path: '/editor'),
      ],
    );
  });

  // Steps: on a pushed editor page, open a 'discard changes?' dialog whose
  // button pops the dialog and calls router.removeLast() in the same frame.
  // Should: the page animates out while the dialog does, then the home page
  // shows, with no assertion.
  testWidgets('a page left right after popping its dialog animates out', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const _EditorRoute()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close editor'));
    await tester.pumpAndSettle();
    final editorRoute = ModalRoute.of(
      tester.element(find.text('Close editor')),
    )!;
    // Recorded rather than sampled at a fixed time: on a slow device the
    // exit animation can be over before any later frame is pumped.
    final statuses = <AnimationStatus>[];
    editorRoute.animation!.addStatusListener(statuses.add);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(
      statuses,
      containsAllInOrder([AnimationStatus.reverse, AnimationStatus.dismissed]),
    );
    expect(tester.takeException(), isNull);
    expect(router.stack.map((p) => p.name), [_HomeRoute.name]);
    expectCurrentPage(router, _HomeRoute.name);
  });
}

class _HomeRoute extends PageRouteInfo<void> {
  const _HomeRoute() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: SafeArea(child: Text(name))),
  );
}

class _EditorRoute extends PageRouteInfo<void> {
  const _EditorRoute() : super(name);

  static const String name = 'EditorRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const _EditorPage());
}

class _EditorPage extends StatelessWidget {
  const _EditorPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ElevatedButton(
          child: const Text('Close editor'),
          onPressed: () {
            final router = context.router;
            showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                content: TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    router.removeLast();
                  },
                  child: const Text('Discard'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
