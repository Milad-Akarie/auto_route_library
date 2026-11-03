import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// The args a guard sets with resolver.overrideNext(args: ...) on a guard
// re-check show on the page, which keeps its place and its state.
// Found while fixing the guard issues, no upstream issue.
// Headless test: auto_route/test/guards/override_args_on_reevaluate_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => _profileStates = 0);

  // Steps: open the app with reevaluateListenable set, push ProfileRoute for
  // 'u-1', then SettingsRoute over it, and fire the listenable; the guard's
  // re-check overrides ProfileRoute's args with 'guest'. Then pop SettingsRoute.
  // Should: the profile page shows 'guest' and was not created again.
  testWidgets('a guard re-check overriding the args of a page shows them', (tester) async {
    final auth = ValueNotifier(0);
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/'),
        AutoRoute(
          page: _ProfileRoute.page,
          path: '/profile',
          guards: [
            AutoRouteGuard.simple((resolver, _) {
              if (resolver.isReevaluating) {
                resolver.overrideNext(args: const _ProfileArgs(userId: 'guest'));
              } else {
                resolver.next();
              }
            }),
          ],
        ),
        AutoRoute(page: _SettingsRoute.page, path: '/settings'),
      ],
    );
    await pumpRouterConfigApp(
      tester,
      router.config(
        reevaluateListenable: auth,
        deepLinkBuilder: (link) => link.initial ? DeepLink.path('/') : link,
      ),
    );
    unawaited(router.push(_ProfileRoute(userId: 'u-1')));
    await tester.pumpAndSettle();
    unawaited(router.push(const _SettingsRoute()));
    await tester.pumpAndSettle();

    auth.value++;
    await tester.pumpAndSettle();

    expect(router.stack.map((page) => page.name), [_HomeRoute.name, _ProfileRoute.name, _SettingsRoute.name]);
    expectTopPage(router, _SettingsRoute.name);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Profile of guest'), findsOneWidget);
    expect(find.text('Profile of u-1'), findsNothing);
    expect(_profileStates, 1);
    await expectBrowserUrl('/profile');
  });
}

class _HomeRoute extends PageRouteInfo<void> {
  const _HomeRoute() : super(name);

  static const String name = '_HomeRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}

class _ProfileArgs {
  const _ProfileArgs({required this.userId});

  final String userId;
}

class _ProfileRoute extends PageRouteInfo<_ProfileArgs> {
  _ProfileRoute({required String userId}) : super(name, args: _ProfileArgs(userId: userId));

  static const String name = '_ProfileRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => _ProfileView(userId: data.argsAs<_ProfileArgs>().userId),
  );
}

var _profileStates = 0;

class _ProfileView extends StatefulWidget {
  const _ProfileView({required this.userId});

  final String userId;

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  @override
  void initState() {
    super.initState();
    _profileStates++;
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: Text('Profile of ${widget.userId}'));
}

class _SettingsRoute extends PageRouteInfo<void> {
  const _SettingsRoute() : super(name);

  static const String name = '_SettingsRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}
