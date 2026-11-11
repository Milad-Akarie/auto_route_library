import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Reported as https://github.com/Milad-Akarie/auto_route_library/issues/1820
// Setup: a pushed page wrapped in PopScope(canPop: false) whose
// onPopInvokedWithResult calls context.router.pop() when the pop was blocked.
// Steps: open the page, press its back button.
// Happened: onPopInvoked ran again and again and the page never popped.
// Should: the callback runs a bounded number of times (the test stops the
// loop after 20 calls so a runaway fails instead of hanging). The reporter
// expects the page to pop; a comment on the report says the fix is to pop
// with a forced pop, so if the page stays, check whether that is intended.
void main() {
  testWidgets('router.pop() inside a blocked PopScope does not loop', (
    tester,
  ) async {
    var calls = 0;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Home'), path: '/', initial: true),
        AutoRoute(
          page: PageInfo(
            'Guarded',
            builder: (_) => Builder(
              builder: (context) => PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (didPop) return;
                  calls++;
                  if (calls > 20) throw StateError('onPopInvoked looped');
                  context.router.pop();
                },
                child: const Scaffold(
                  body: Text('Guarded'),
                  appBar: _GuardedBar(),
                ),
              ),
            ),
          ),
          path: '/guarded',
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('Guarded')));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(calls, lessThanOrEqualTo(2));
    expectCurrentPage(router, 'Home');
  });
}

class _GuardedBar extends StatelessWidget implements PreferredSizeWidget {
  const new();

  @override
  Size get preferredSize => const .fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) =>
      AppBar(leading: const AutoLeadingButton());
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
