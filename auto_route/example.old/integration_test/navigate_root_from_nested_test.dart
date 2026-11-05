import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// navigatePath('/') and replacePath('/') from a page above a nested router
// show the default child of '/'.
// https://github.com/Milad-Akarie/auto_route_library/issues/1419
// Headless test: auto_route/test/navigate_root_from_nested_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('navigate root from nested', () {
    // Steps: '/' is a Landing page with a nested router holding Empty (path
    // ''), Lessons and Experience; Experience is a shell with its own nested
    // router holding Sessions (path '') and Own. Open '/experience', then tap
    // the button on the Experience page, outside its nested router, that calls
    // context.router.navigatePath('/') or replacePath('/').
    // Should: Empty, the default child of '/', shows, not Sessions.
    for (final shouldReplace in [false, true]) {
      final call = shouldReplace ? 'replacePath' : 'navigatePath';
      testWidgets(
        "$call('/') from a page above a nested router shows the default child of '/'",
        (tester) async {
          final router = RootStackRouter.build(
            routes: [
              AutoRoute(
                path: '/',
                page: PageInfo(
                  'LandingRoute',
                  builder: (_) => const AutoRouter(),
                ),
                children: [
                  AutoRoute(path: '', page: _page('EmptyRoute')),
                  AutoRoute(path: 'lessons', page: _page('LessonsRoute')),
                  AutoRoute(
                    path: 'experience',
                    page: PageInfo(
                      'ExperienceRoute',
                      builder: (_) =>
                          _ExperiencePage(shouldReplace: shouldReplace),
                    ),
                    children: [
                      AutoRoute(path: '', page: _page('SessionsRoute')),
                      AutoRoute(path: 'user-sessions', page: _page('OwnRoute')),
                    ],
                  ),
                ],
              ),
            ],
          );
          await pumpRouterAppWithConfig(tester, router);
          unawaited(router.navigatePath('/experience'));
          await tester.pumpAndSettle();
          expect(find.text('SessionsRoute'), findsOneWidget);
          await expectBrowserUrl('/experience');

          await tester.tap(find.text('Go to the root'));
          await tester.pumpAndSettle();

          expect(find.text('EmptyRoute'), findsOneWidget);
          expect(find.text('SessionsRoute'), findsNothing);
          expect(router.currentPath, '/');
          await expectBrowserUrl('/');
        },
      );
    }
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(body: Center(child: Text(name))),
);

class _ExperiencePage extends StatelessWidget {
  const new({required this.shouldReplace});

  final bool shouldReplace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('ExperienceRoute'),
          TextButton(
            onPressed: () => shouldReplace
                ? context.router.replacePath('/')
                : context.router.navigatePath('/'),
            child: const Text('Go to the root'),
          ),
          const Expanded(child: AutoRouter()),
        ],
      ),
    );
  }
}
