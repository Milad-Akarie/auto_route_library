import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../centered_named_page.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/99096
  // The reporter pushed '/chat' from '/chat_list' with no query param, and
  // wanted to stay on '/chat_list': the stack ['/', '/chat_list'] unchanged,
  // not ['/', '/chat_list', '/chat_list'].
  // In auto_route a guard that doesn't want the navigation calls reject(),
  // which leaves the stack and the url as they are. redirectUntil() is not it:
  // it opens the route it is given on top, so redirecting to the page already
  // on top shows that page twice, as push() does.
  testWidgets(
    'A guard rejecting a push from the top page leaves the stack as it was (flutter/flutter#99096)',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const CenteredNamedPage('HomeRoute'),
          ),
          NamedRouteDef(
            name: 'ChatListRoute',
            path: '/chat_list',
            builder: (_, _) => const CenteredNamedPage('ChatListRoute'),
          ),
          NamedRouteDef.guarded(
            name: 'ChatRoute',
            path: '/chat',
            onNavigation: (resolver, _) {
              if (resolver.route.queryParams.optString('user') != null) {
                return resolver.next();
              }
              resolver.reject();
            },
            builder: (_, _) => const CenteredNamedPage('ChatRoute'),
          ),
        ],
      );
      await pumpRouterApp(tester, router, initialLink: '/chat_list');
      expect(router.stack.map((e) => e.name), ['HomeRoute', 'ChatListRoute']);

      unawaited(router.pushPath('/chat'));
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.name), [
        'HomeRoute',
        'ChatListRoute',
      ], reason: 'after router.pushPath(/chat))');
      expect(router.urlState.url, '/chat_list');

      unawaited(router.pushPath('/chat?user=1'));
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.name), [
        'HomeRoute',
        'ChatListRoute',
        'ChatRoute',
      ]);
    },
  );
}
