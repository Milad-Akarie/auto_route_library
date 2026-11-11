import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1040
// Setup, as in the report (auto_route 3.2.4): Container > PageA > SubPageA
// (initial) and SubPageB (with SubsubpageA). PageA builds an AutoRouter, takes
// it out of its tree, and puts a new AutoRouter in its place later.
// Steps: open PageA, which shows SubPageA; replace its AutoRouter with a
// Container; put an AutoRouter back.
// Reported: the second AutoRouter is empty, SubPageA is not shown again.
// Should: SubPageA shows again. The maintainer's answer was that the
// AutoRouter builder is the way to hide the body, so the second test does
// that and expects the page the user was on to stay.
void main() {
  tearDownAll(_showSubRoutes.dispose);

  late RootStackRouter router;

  setUp(() {
    _showSubRoutes.value = true;
    _useBuilder = false;
    router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'ContainerRoute',
          path: '/',
          initial: true,
          builder: (_, _) => const AutoRouter(),
          children: [
            NamedRouteDef(
              name: 'PageARoute',
              path: 'a',
              initial: true,
              builder: (_, _) => ValueListenableBuilder<bool>(
                valueListenable: _showSubRoutes,
                builder: (_, show, _) => Scaffold(
                  appBar: AppBar(title: const Text('Page A')),
                  body: _useBuilder
                      ? AutoRouter(
                          builder: (_, body) =>
                              show ? body : const SizedBox.shrink(),
                        )
                      : show
                      ? const AutoRouter()
                      : const SizedBox(),
                ),
              ),
              children: [
                NamedRouteDef(
                  name: 'SubPageARoute',
                  path: 'sub-a',
                  initial: true,
                  builder: (_, _) => const Text('SubPageA'),
                ),
                NamedRouteDef(
                  name: 'SubPageBRoute',
                  path: 'sub-b',
                  builder: (_, _) => const AutoRouter(),
                  children: [
                    NamedRouteDef(
                      name: 'SubsubpageARoute',
                      path: 'subsub-a',
                      initial: true,
                      builder: (_, _) => const Text('SubsubpageA'),
                    ),
                  ],
                ),
              ],
            ),
            NamedRouteDef(
              name: 'PageBRoute',
              path: 'b',
              builder: (_, _) => const Text('PageB'),
            ),
          ],
        ),
      ],
    );
  });

  testWidgets('An AutoRouter put in again shows the initial page again', (
    tester,
  ) async {
    await pumpRouterConfigApp(tester, router.config());
    expect(find.text('SubPageA'), findsOneWidget);

    _showSubRoutes.value = false;
    await tester.pumpAndSettle();
    expect(find.text('SubPageA'), findsNothing);
    _showSubRoutes.value = true;
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('SubPageA'),
      findsOneWidget,
      reason: '_showSubRoutes.value = true',
    );
  });

  testWidgets('The AutoRouter builder hides the body and keeps the page', (
    tester,
  ) async {
    _useBuilder = true;
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.navigatePath('/a/sub-b'));
    await tester.pumpAndSettle();
    expect(find.text('SubsubpageA'), findsOneWidget);

    _showSubRoutes.value = false;
    await tester.pumpAndSettle();
    expect(find.text('SubsubpageA'), findsNothing);
    _showSubRoutes.value = true;
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('SubsubpageA'),
      findsOneWidget,
      reason: '_showSubRoutes.value = true',
    );
  });
}

final ValueNotifier<bool> _showSubRoutes = ValueNotifier(true);
bool _useBuilder = false;
