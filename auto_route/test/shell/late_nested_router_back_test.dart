import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1126
  // Reported: after back from the first page of a nested router, that page
  // stayed in the tree (seen in the inspector, and a TV remote's OK still
  // activated its focused button).
  // Setup as reported: LoginRoute at '/login' (initial), SelectServerRoute at
  // '' and ServerRoute at 'server/:serverId', both guarded. ServerRoute
  // shows a loader until its data is ready, then its AutoRouter, whose
  // first page LibrarySelectRoute is at ''; LibraryRoute beside it is
  // guarded too.
  // Steps: sign in, open server 1, wait for its data, press OK (Enter) on
  // the focused library button, press system back, press OK again.
  // Should: SelectServerRoute shows, LibrarySelectRoute is gone from the
  // tree, and its button takes only the first OK.
  testWidgets(
    'Back from the first page of a nested router shown late removes it from '
    'the tree',
    (tester) async {
      final ready = Completer<void>();
      var libraryPresses = 0;
      final authGuard = AutoRouteGuard.simple((resolver, _) => resolver.next());
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'LoginRoute',
            path: '/login',
            initial: true,
            builder: (context, _) => TextButton(
              onPressed: () =>
                  context.router.replace(const NamedRoute('SelectServerRoute')),
              child: const Text('LoginRoute'),
            ),
          ),
          NamedRouteDef(
            name: 'SelectServerRoute',
            path: '/',
            guards: [authGuard],
            builder: (context, _) => TextButton(
              onPressed: () => context.router.push(
                const NamedRoute('ServerRoute', params: {'serverId': 1}),
              ),
              child: const Text('SelectServerRoute'),
            ),
          ),
          NamedRouteDef(
            name: 'ServerRoute',
            path: '/server/:serverId',
            guards: [authGuard],
            builder: (_, _) => FutureBuilder<void>(
              future: ready.future,
              builder: (_, snapshot) => snapshot.connectionState == .done
                  ? const AutoRouter()
                  : const Text('loading'),
            ),
            children: [
              NamedRouteDef(
                name: 'LibrarySelectRoute',
                path: '',
                builder: (_, _) => Scaffold(
                  body: TextButton(
                    autofocus: true,
                    onPressed: () => libraryPresses++,
                    child: const Text('LibrarySelectRoute'),
                  ),
                ),
              ),
              NamedRouteDef(
                name: 'LibraryRoute',
                path: 'library/:libraryId',
                guards: [authGuard],
                builder: (_, _) => const Text('LibraryRoute'),
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router, initialLink: '/login');
      await tester.tap(find.text('LoginRoute'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SelectServerRoute'));
      await tester.pumpAndSettle();
      final loadingShown = find.text('loading').evaluate().length;
      ready.complete();
      await tester.pumpAndSettle();
      final librarySelectShown = find
          .text('LibrarySelectRoute')
          .evaluate()
          .length;
      // OK on the remote: the focused library button takes it.
      await tester.sendKeyEvent(.enter);
      await tester.pump();
      final pressesBeforeBack = libraryPresses;

      await systemBack(tester);

      expect(tester.takeException(), isNull);
      expect(router.stack.map((page) => page.name), ['SelectServerRoute']);
      expect(find.text('SelectServerRoute'), findsOneWidget);
      expect(
        find.text('LibrarySelectRoute', skipOffstage: false),
        findsNothing,
      );
      expect(router.innerRouterOf<StackRouter>('ServerRoute'), isNull);
      // OK again: the popped page's button must not take it.
      await tester.sendKeyEvent(.enter);
      await tester.pump();
      expect((loadingShown, librarySelectShown, pressesBeforeBack), (1, 1, 1));
      expect(libraryPresses, 1);
    },
  );
}
