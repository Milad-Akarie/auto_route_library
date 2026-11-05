import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// replace() and pushAndPopUntil() with the same parent route and new
// children show only those children.
// Headless test: auto_route/test/nested_router/replace_same_route_children_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: root routes '/' and '/app', a shell with the children 'users' and
  // 'other'. Tap to push AppRoute(children: [UsersRoute]), then tap to put
  // AppRoute(children: [OtherRoute]) over it with replace, or with
  // pushAndPopUntil down to HomeRoute. Then go back.
  // Should: the shell shows OtherRoute alone and the url is '/app/other', in
  // the browser's address bar too on web, and back leaves the shell.
  for (final (how, replace) in [
    ('replace()', true),
    ('pushAndPopUntil()', false),
  ]) {
    testWidgets('$how with the same parent route shows only its new children', (
      tester,
    ) async {
      final router = _buildRouter(replace: replace);
      await pumpRouterApp(tester, router);
      await tester.tap(find.text('Open users'));
      await tester.pumpAndSettle();
      expect(find.text('UsersRoute'), findsOneWidget);
      expect(router.urlState.url, '/app/users');
      await expectBrowserUrl('/app/users');

      await tester.tap(find.text('Show other'));
      await tester.pumpAndSettle();
      expect(find.text('OtherRoute'), findsOneWidget);
      expect(find.text('UsersRoute'), findsNothing);
      expect(router.stack.map((page) => page.name), ['HomeRoute', 'AppRoute']);
      expect(router.urlState.url, '/app/other');
      await expectBrowserUrl('/app/other');

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('HomeRoute'), findsOneWidget);
      expect(router.urlState.url, '/');
    });
  }
}

const _users = _Route('AppRoute', children: [_Route('UsersRoute')]);
const _other = _Route('AppRoute', children: [_Route('OtherRoute')]);

// HomeRoute's button pushes [_users]; UsersRoute's button puts [_other] over
// the shell's page with replace, or with pushAndPopUntil down to HomeRoute.
RootStackRouter _buildRouter({required bool replace}) => .build(
  routes: [
    AutoRoute(
      path: '/',
      page: _page(
        'HomeRoute',
        label: 'Open users',
        onPressed: (router) => router.push(_users),
      ),
    ),
    AutoRoute(
      path: '/app',
      page: const EmptyShellRoute('AppRoute'),
      children: [
        AutoRoute(
          path: 'users',
          page: _page(
            'UsersRoute',
            label: 'Show other',
            onPressed: (router) => replace
                ? router.replace(_other)
                : router.pushAndPopUntil(
                    _other,
                    predicate: (route) => route.settings.name == 'HomeRoute',
                  ),
          ),
        ),
        AutoRoute(path: 'other', page: _page('OtherRoute')),
      ],
    ),
  ],
);

// A page that shows its name and, given a [label], a button that calls
// [onPressed] with the root router.
PageInfo _page(
  String name, {
  String? label,
  void Function(StackRouter router)? onPressed,
}) => .new(
  name,
  builder: (context) => Scaffold(
    body: Column(
      children: [
        Text(name),
        if (label != null && onPressed != null)
          ElevatedButton(
            onPressed: () => onPressed(context.router.root),
            child: Text(label),
          ),
      ],
    ),
  ),
);

class _Route extends PageRouteInfo<void> {
  const new(super.name, {List<PageRouteInfo>? children})
    : super(initialChildren: children);
}
