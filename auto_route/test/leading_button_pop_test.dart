import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/1837
  // Setup, as in the reporter's web demo: a home page, and a user page whose
  // AppBar has an AutoLeadingButton above a nested AutoRouter that starts on
  // a profile page. A posts route in that nested router has a guard that
  // redirects to a verify page on the root router until the user is
  // verified.
  late bool verified;
  late RootStackRouter router;

  setUp(() {
    verified = false;
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/', initial: true),
        AutoRoute(page: _VerifyRoute.page, path: '/verify'),
        AutoRoute(
          page: _UserRoute.page,
          path: '/user',
          children: [
            AutoRoute(page: _ProfileRoute.page, path: '', initial: true),
            AutoRoute(
              page: _PostsRoute.page,
              path: 'posts',
              guards: [
                AutoRouteGuard.simple((resolver, _) {
                  if (verified) {
                    resolver.next();
                  } else {
                    unawaited(resolver.redirectUntil(const _VerifyRoute()));
                  }
                }),
              ],
            ),
          ],
        ),
      ],
    );
  });

  Future<void> tapLeadingButton(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  // Steps: push the user page, then tap its leading button.
  // Should: the home page shows again.
  testWidgets('AutoLeadingButton on a page holding a nested router goes back to the previous page', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const _UserRoute()));
    await tester.pumpAndSettle();
    expect(find.text(_ProfileRoute.name), findsOneWidget);

    await tapLeadingButton(tester);
    expect(find.text(_HomeRoute.name), findsOneWidget);
    expect(router.stack.map((p) => p.name), [_HomeRoute.name]);
  });

  // Steps: push the user page, push the guarded posts route from the
  // profile page, which opens the verify page on the root router. Tap the
  // leading button on the verify page, then on the user page.
  // Happens: the first tap shows the user page; the second does nothing.
  // Should: the first tap shows the user page, the second the home page.
  testWidgets('AutoLeadingButton goes back to the previous page after a guard redirect was popped', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const _UserRoute()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Posts'));
    await tester.pumpAndSettle();
    expect(find.text(_VerifyRoute.name), findsOneWidget);

    await tapLeadingButton(tester);
    expect(find.text(_ProfileRoute.name), findsOneWidget);
    expect(find.text(_VerifyRoute.name), findsNothing);

    await tapLeadingButton(tester);
    expect(find.text(_HomeRoute.name), findsOneWidget);
    expect(router.stack.map((p) => p.name), [_HomeRoute.name]);
  });
}

abstract final class _HomeRoute {
  static const String name = '_HomeRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      appBar: AppBar(leading: const AutoLeadingButton()),
      body: const Text(name),
    ),
  );
}

class _VerifyRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_VerifyRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      appBar: AppBar(leading: const AutoLeadingButton()),
      body: const Text(name),
    ),
  );
}

class _UserRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_UserRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      appBar: AppBar(leading: const AutoLeadingButton()),
      body: const AutoRouter(),
    ),
  );
}

abstract final class _ProfileRoute {
  static const String name = '_ProfileRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => Builder(
      builder: (context) => Column(
        children: [
          const Text(name),
          TextButton(onPressed: () => context.pushRoute(const _PostsRoute()), child: const Text('Posts')),
        ],
      ),
    ),
  );
}

class _PostsRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_PostsRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}
