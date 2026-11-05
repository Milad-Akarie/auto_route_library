import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// Found while fixing the guard issues, no upstream issue.
// Steps: the router has a reevaluateListenable. ProfileRoute takes args and is
// guarded. Open HomeRoute, push ProfileRoute for 'u-1', then SettingsRoute
// over it, and fire the listenable; on the re-check the guard calls
// resolver.overrideNext(args: ProfileArgs(userId: 'guest')).
// Was: the profile page still showed 'u-1'. The re-check added the page back
// as it was, built from the old args.
// Should: the profile page shows 'guest', in its place under
// SettingsRoute, and keeps its state.
void main() {
  setUp(() => _profileStates = 0);

  testWidgets('a guard re-check overriding the args of a page shows them', (tester) async {
    final auth = ValueNotifier(0);
    addTearDown(auth.dispose);
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
    await pumpRouterApp(tester, router, reevaluationNotifier: auth);
    unawaited(router.push(_ProfileRoute(userId: 'u-1')));
    await tester.pumpAndSettle();
    unawaited(router.push(const _SettingsRoute()));
    await tester.pumpAndSettle();

    auth.value++;
    await tester.pumpAndSettle();

    expect(router.stack.map((page) => page.name), [_HomeRoute.name, _ProfileRoute.name, _SettingsRoute.name]);
    expect(router.stackData[1].argsAs<_ProfileArgs>().userId, 'guest');
    expect(find.text(_SettingsRoute.name), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Profile of guest'), findsOneWidget);
    expect(find.text('Profile of u-1'), findsNothing);
    expect(_profileStates, 1);
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
  static PageInfo page = PageInfo(name, builder: (data) => _ProfileView(userId: data.argsAs<_ProfileArgs>().userId));
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
