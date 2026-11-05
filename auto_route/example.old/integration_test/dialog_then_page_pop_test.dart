import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// maybePop on a page right after popping its dialog with maybePop closes the
// page.
// https://github.com/Milad-Akarie/auto_route_library/issues/2017
// Headless test: auto_route/test/simple_router/dialog_then_page_pop_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/', initial: true),
        AutoRoute(page: _FormRoute.page, path: '/form'),
      ],
    );
  });

  // Steps: on a pushed page, open a dialog whose button calls
  // context.router.maybePop(true). Once the dialog returns true, the page
  // starts an async call without awaiting it and calls
  // context.router.maybePop(true).
  // Should: the dialog and then the page close, with no assertion.
  testWidgets(
    'maybePop on the page after popping a dialog with maybePop closes the page',
    (tester) async {
      await pumpRouterApp(tester, router);
      unawaited(router.push(const _FormRoute()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close form'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(router.stack.map((p) => p.name), [_HomeRoute.name]);
      expectCurrentPage(router, _HomeRoute.name);
    },
  );
}

class _HomeRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: SafeArea(child: Text(name))),
  );
}

class _FormRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'FormRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const _FormPage());
}

class _FormPage extends StatelessWidget {
  const new();

  // Stands for the reporter's cubit call that takes a while.
  Future<void> _callAsyncCubitMethod() =>
      .delayed(const Duration(milliseconds: 500));

  Future<void> _closeForm(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: ElevatedButton(
          onPressed: () => context.router.maybePop(true),
          child: const Text('Confirm'),
        ),
      ),
    );

    unawaited(_callAsyncCubitMethod());

    if (result == true && context.mounted) {
      unawaited(context.router.maybePop(true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ElevatedButton(
          child: const Text('Close form'),
          onPressed: () => unawaited(_closeForm(context)),
        ),
      ),
    );
  }
}
