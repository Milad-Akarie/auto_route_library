import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// A page that listens with AutoRouteAwareStateMixin hears that it shows again
// when a page pushed over it opens a dialog, closes it, and goes back to it,
// on every round and whatever the timing.
// The same scenario as flutter/flutter#155415 in go_router.
void main() {
  // Not awaited: navigate()'s future completes when the page it opens is
  // popped (Milad-Akarie/auto_route_library#2154).
  final navigations = <String, void Function(StackRouter)>{
    'navigate': (router) => unawaited(router.navigatePath('/')),
    'replaceAll': (router) => unawaited(router.replaceAll([const PageRouteInfo('HomeRoute')])),
  };

  for (final MapEntry(key: navigation, value: navigate) in navigations.entries) {
    for (final withDialog in [false, true]) {
      for (final delayed in [false, true]) {
        final how = [if (withDialog) 'closing a dialog', if (delayed) 'a 1 ms delay'].join(' and ');
        // Steps: HomeRoute has AutoRouteAwareStateMixin. Twice: push
        // ProfilesRoute; in the dialog runs, open a dialog there and close it
        // with Navigator.pop; in the delayed runs, wait 1 ms; then navigate or
        // replaceAll back to HomeRoute.
        // Should: on each round, the HomeRoute shown hears didPopNext, or
        // didPush when it is a new page.
        testWidgets('$navigation back to an aware page${how.isEmpty ? '' : ' after $how'} tells it each time', (
          tester,
        ) async {
          final events = <String>[];
          final router = RootStackRouter.build(
            routes: [
              AutoRoute(
                path: '/',
                page: PageInfo('HomeRoute', builder: (_) => _AwarePage(events)),
              ),
              AutoRoute(
                path: '/profiles',
                page: PageInfo('ProfilesRoute', builder: (_) => const Text('ProfilesRoute')),
              ),
            ],
          );
          await pumpRouterApp(tester, router, observers: () => [AutoRouteObserver()]);

          for (var round = 1; round <= 2; round++) {
            events.clear();
            unawaited(router.pushPath('/profiles'));
            await tester.pumpAndSettle();
            expectCurrentPage(router, 'ProfilesRoute');

            if (withDialog) {
              final context = router.navigatorKey.currentContext!;
              showDialog<void>(
                context: context,
                builder: (_) => const AlertDialog(content: Text('Confirm')),
              );
              await tester.pumpAndSettle();
              Navigator.of(tester.element(find.text('Confirm'))).pop();
            }
            if (delayed) {
              await tester.pump(const Duration(milliseconds: 1));
            }
            navigate(router);
            await tester.pumpAndSettle();

            expect(router.stack.map((page) => page.name), ['HomeRoute'], reason: 'round $round');
            expect(find.byType(AlertDialog), findsNothing);
            expect(events, anyOf(contains('didPopNext'), contains('didPush')), reason: 'round $round');
          }
        });
      }
    }
  }
}

class _AwarePage extends StatefulWidget {
  const _AwarePage(this.events);

  final List<String> events;

  @override
  State<_AwarePage> createState() => _AwarePageState();
}

class _AwarePageState extends State<_AwarePage> with AutoRouteAwareStateMixin {
  @override
  void didPush() => widget.events.add('didPush');

  @override
  void didPopNext() => widget.events.add('didPopNext');

  @override
  Widget build(BuildContext context) => const Text('HomeRoute');
}
