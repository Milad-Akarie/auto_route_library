import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, initial: true),
        AutoRoute(page: _FormRoute.page),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2017
  // The reporter's code: a page awaits a dialog, the dialog's button calls
  // context.router.maybePop(true), then the page starts an async call without
  // awaiting it and calls context.router.maybePop(true). The dialog and then
  // the page should close, without the '!_debugLocked' assertion.
  testWidgets('maybePop on the page after popping a dialog with maybePop closes the page', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const _FormRoute()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Close form'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(router.stack.map((p) => p.name), [_HomeRoute.name]);
    expect(find.text('Confirm'), findsNothing);
    expectCurrentPage(router, _HomeRoute.name);

    // Let the call the page started finish.
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}

class _HomeRoute extends PageRouteInfo<void> {
  const _HomeRoute() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}

class _FormRoute extends PageRouteInfo<void> {
  const _FormRoute() : super(name);

  static const String name = 'FormRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const _FormPage());
}

class _FormPage extends StatelessWidget {
  const _FormPage();

  // Stands for the reporter's cubit call that takes 5 seconds.
  Future<void> _callAsyncCubitMethod() => .delayed(const Duration(seconds: 5));

  Future<void> _closeForm(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: ElevatedButton(onPressed: () => context.router.maybePop(true), child: const Text('Confirm')),
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
      body: ElevatedButton(child: const Text('Close form'), onPressed: () => unawaited(_closeForm(context))),
    );
  }
}
