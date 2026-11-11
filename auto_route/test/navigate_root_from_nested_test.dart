import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

PageInfo _text(String name) => .new(name, builder: (_) => Text(name));

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1419
  // Steps (auto_route 6.0): LandingRoute at '/' holds a nested router with
  // Empty (path ''), Lessons and Experience; ExperienceRoute is a shell with
  // its own nested router holding Sessions (path '') and Own. Open
  // '/experience', then from the Experience page, outside its own nested
  // router, call context.router.navigatePath('/') or replaceNamed('/'); they
  // are navigatePath and replacePath now.
  // Reported: it showed Sessions, not Empty, the first page of Landing.
  // Should: '/' is Landing with its default child, Empty.
  late RootStackRouter router;
  late BuildContext experienceContext;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('LandingRoute', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(path: '', page: _text('EmptyRoute')),
            AutoRoute(path: 'lessons', page: _text('LessonsRoute')),
            AutoRoute(
              path: 'experience',
              page: PageInfo(
                'ExperienceRoute',
                builder: (_) => Builder(
                  builder: (context) {
                    experienceContext = context;
                    return const Column(
                      children: [
                        Text('ExperienceRoute'),
                        Expanded(child: AutoRouter()),
                      ],
                    );
                  },
                ),
              ),
              children: [
                AutoRoute(path: '', page: _text('SessionsRoute')),
                AutoRoute(path: 'user-sessions', page: _text('OwnRoute')),
              ],
            ),
          ],
        ),
      ],
    );
  });

  Future<void> openSessions(WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.navigatePath('/experience'));
    await tester.pumpAndSettle();
    expect(find.text('SessionsRoute'), findsOneWidget);
  }

  testWidgets(
    "navigatePath('/') from a page above a nested router shows the default child of '/'",
    (tester) async {
      await openSessions(tester);

      unawaited(experienceContext.router.navigatePath('/'));
      await tester.pumpAndSettle();

      expect(find.text('EmptyRoute'), findsOneWidget);
      expect(find.text('SessionsRoute'), findsNothing);
      expect(router.currentPath, '/');
    },
  );

  testWidgets(
    "replacePath('/') from a page above a nested router shows the default child of '/'",
    (tester) async {
      await openSessions(tester);

      unawaited(experienceContext.router.replacePath('/'));
      await tester.pumpAndSettle();

      expect(find.text('EmptyRoute'), findsOneWidget);
      expect(find.text('SessionsRoute'), findsNothing);
    },
  );
}
