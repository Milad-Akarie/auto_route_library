import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/flutter/flutter/issues/148768
// Setup: a home page holding tabs and a loading page, both at the root.
// Steps: the home page replaces the stack with the loading page; 50 ms later,
// while the home page is still animating out, the loading page goes back to
// the home page.
// Should: no duplicate GlobalKey error; the home page and its tab show again.
void main() {
  // navigate pushes a page that isn't in the stack, so it keeps the loading
  // page below; replaceAll does what the report's go does.
  for (final (how, goHome, stack) in [
    ('replaceAll', (StackRouter router) => router.replaceAll([const _Route('HomeRoute')]), ['HomeRoute']),
    ('navigate', (StackRouter router) => router.navigate(const _Route('HomeRoute')), ['LoadingRoute', 'HomeRoute']),
    ('navigatePath', (StackRouter router) => router.navigatePath('/home'), ['LoadingRoute', 'HomeRoute']),
  ]) {
    testWidgets('Going back to the tabs with $how while they animate out shows them', (tester) async {
      late final RootStackRouter router;
      router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/home',
            initial: true,
            page: PageInfo('HomeRoute', builder: (_) => const AutoTabsRouter(routes: [_Route('TabRoute')])),
            children: [AutoRoute(path: '', page: _page('TabRoute'))],
          ),
          AutoRoute(
            path: '/loading',
            page: PageInfo('LoadingRoute', builder: (_) => _LoadingPage(() => goHome(router))),
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      expect(find.text('TabRoute'), findsOneWidget);

      unawaited(router.replaceAll([const _Route('LoadingRoute')]));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(router.stack.map((page) => page.name), stack);
      expect(find.text('TabRoute'), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });
  }
}

class _LoadingPage extends StatefulWidget {
  const _LoadingPage(this.goHome);

  final VoidCallback goHome;

  @override
  State<_LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<_LoadingPage> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 50), widget.goHome);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Loading'));
}

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}
