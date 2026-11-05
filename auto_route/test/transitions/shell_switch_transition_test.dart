import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../named_page.dart';
import '../router_test_utils.dart';

// flutter/flutter#121355 and #130327: in go_router, moving between two shell
// routes animated the new page in but cut the old one out at once, and a
// custom transition did not run in the shell.
// Setup: two sibling shells '/a' and '/b' with a fade CustomRoute each, and a
// shell with two CustomRoute children.
// Steps: navigate from '/a' to '/b'; replace a child inside a shell by its
// sibling. Look at the tree halfway through the 400 ms transition.
// Should: the old page is still in the tree halfway, and gone at the end.
CustomRoute _fade(String path, PageInfo page, {List<AutoRoute>? children}) =>
    .new(
      path: path,
      page: page,
      children: children,
      transitionsBuilder: TransitionsBuilders.fadeIn,
      duration: const Duration(milliseconds: 400),
    );

PageInfo _shell(String name) => .new(name, builder: (_) => const AutoRouter());
PageInfo _leaf(String name) => .new(name, builder: (_) => NamedPage(name));

void main() {
  testWidgets(
    'Navigating between two shells keeps the old page while the new one fades '
    'in',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(path: '/', page: _leaf('HomePage')),
          _fade('/a', _shell('AShell'), children: [_fade('', _leaf('APage'))]),
          _fade('/b', _shell('BShell'), children: [_fade('', _leaf('BPage'))]),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.push(const NamedRoute('AShell')));
      await tester.pumpAndSettle();
      expect(find.text('APage'), findsOneWidget);

      unawaited(router.replace(const NamedRoute('BShell')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('BPage', skipOffstage: false), findsOneWidget);
      expect(
        find.text('APage', skipOffstage: false),
        findsOneWidget,
        reason: 'the old page animates out',
      );

      await tester.pumpAndSettle();
      expect(find.text('BPage'), findsOneWidget);
      expect(find.text('APage', skipOffstage: false), findsNothing);
    },
  );

  testWidgets(
    'Replacing a page inside a shell keeps the old page halfway through the '
    'transition',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(path: '/home', initial: true, page: _leaf('HomePage')),
          AutoRoute(
            path: '/',
            page: _shell('Shell'),
            children: [
              _fade('one', _leaf('OnePage')),
              _fade('two', _leaf('TwoPage')),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.navigatePath('/one'));
      await tester.pumpAndSettle();
      expect(find.text('OnePage'), findsOneWidget);

      unawaited(
        router
            .innerRouterOf<StackRouter>('Shell')!
            .replace(const NamedRoute('TwoPage')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('TwoPage', skipOffstage: false), findsOneWidget);
      expect(
        find.text('OnePage', skipOffstage: false),
        findsOneWidget,
        reason: 'the old page animates out',
      );

      await tester.pumpAndSettle();
      expect(find.text('TwoPage'), findsOneWidget);
      expect(find.text('OnePage', skipOffstage: false), findsNothing);
    },
  );
}
