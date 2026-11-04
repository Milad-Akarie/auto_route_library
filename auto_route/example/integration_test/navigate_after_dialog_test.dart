import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// navigateTo() back to a page right after closing a dialog tells that page didPopNext.
// Regression of https://github.com/Milad-Akarie/auto_route_library/issues/1774
// Headless test: auto_route/test/auto_route_observer_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: ListRoute has AutoRouteAwareStateMixin. Push DetailRoute, open a
  // dialog, and tap its button, which closes the dialog with
  // `await context.maybePop()` and then calls `context.navigateTo(ListRoute)`.
  // Should: ListRoute shows again and gets didPopNext.
  testWidgets('navigateTo() back to a page after closing a dialog tells it didPopNext', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('ListRoute', builder: (_) => const RouteAwarePage()),
        ),
        AutoRoute(
          path: '/detail',
          page: PageInfo('DetailRoute', builder: (_) => const _DetailPage()),
        ),
      ],
    );
    await pumpRouterApp(tester, router, navigatorObservers: () => [AutoRouteObserver()]);
    unawaited(router.push(const NamedRoute('DetailRoute')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    routeAwareEvents.clear();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expectTopPage(router, 'ListRoute');
    expect(router.stack.map((page) => page.name), ['ListRoute']);
    expect(routeAwareEvents, ['ListRoute.didPopNext']);
  });
}

class _DetailPage extends StatelessWidget {
  const _DetailPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              actions: [
                TextButton(
                  onPressed: () async {
                    await dialogContext.maybePop();
                    // The page's context: the dialog's is gone once it pops.
                    // ignore: use-closest-build-context
                    if (context.mounted) unawaited(context.navigateTo(const NamedRoute('ListRoute')));
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
          child: const Text('Delete'),
        ),
      ),
    );
  }
}
