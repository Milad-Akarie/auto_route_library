import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

// When a navigation reaches a screen the navigator already shows, a new page
// takes over the screen's route. The code that opened the screen keeps
// waiting for it, as native navigation keeps it: Flutter's Navigator keeps
// the route, with its pending future, for a page of the same type and key,
// and Android's Navigation keeps the back stack entry of a screen that a
// single-top navigation reaches again.

Widget _label(String name, RouteData<Object?> data) {
  final query = data.queryParams.optString('q');
  return Text(query == null ? name : '$name q=$query');
}

AutoRoute _page(String name, String path) => .new(
  page: PageInfo(name, builder: (data) => _label(name, data)),
  path: path,
);

RootStackRouter _buildRouter() => .build(
  routes: [
    _page('HomeRoute', '/'),
    _page('PickerRoute', '/picker'),
    _page('OtherRoute', '/other'),
    AutoRoute(
      page: PageInfo('ShellRoute', builder: (_) => const AutoRouter()),
      path: '/shell',
      children: [_page('ChildARoute', 'a'), _page('ChildBRoute', 'b')],
    ),
  ],
);

const NamedRoute<Object?> _picker = NamedRoute('PickerRoute');
const NamedRoute<Object?> _pickerAgain = NamedRoute(
  'PickerRoute',
  queryParams: {'q': '1'},
);

// What the code that opened a screen got, or that it still waits.
class _Caller {
  new(Future<int?> future) {
    unawaited(future.then((value) => result = 'got ${value ?? 'null'}'));
  }

  String result = 'waiting';
}

void main() {
  // Steps: push PickerRoute with push<int>, navigate to it with a new query
  // param, as a link to it does, then close it with 7.
  // Happened: since 12.6.0, the push answered null when the navigation
  // reached the picker, though the picker stayed on screen, and the 7 went to
  // no one.
  // Should: the push waits while the picker shows, and gets 7.
  testWidgets(
    'The caller of a screen reached again waits for the result it closes with',
    (tester) async {
      final router = _buildRouter();
      await pumpRouterApp(tester, router);
      final caller = _Caller(router.push<int>(_picker));
      await tester.pumpAndSettle();

      unawaited(router.navigate(_pickerAgain));
      await tester.pumpAndSettle();
      expect(find.text('PickerRoute q=1'), findsOneWidget);
      expect(caller.result, 'waiting');

      router.pop(7);
      await tester.pumpAndSettle();
      expect(find.text('HomeRoute'), findsOneWidget);
      expect(caller.result, 'got 7');
    },
  );

  // Steps: push PickerRoute with push<int> and OtherRoute over it, navigate
  // to PickerRoute, then press system back.
  // Happened: since 12.6.0, the push answered null when the navigation went
  // back down to the picker.
  // Should: OtherRoute's push answers null as it leaves, the picker's push
  // waits until back closes the picker, and then gets null, as back gives no
  // result.
  testWidgets('The caller of a screen navigated back down to keeps waiting', (
    tester,
  ) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    final caller = _Caller(router.push<int>(_picker));
    await tester.pumpAndSettle();
    final other = _Caller(router.push<int>(const NamedRoute('OtherRoute')));
    await tester.pumpAndSettle();

    unawaited(router.navigate(_picker));
    await tester.pumpAndSettle();
    expect(find.text('PickerRoute'), findsOneWidget);
    expect(other.result, 'got null');
    expect(caller.result, 'waiting');

    await systemBack(tester);
    expect(find.text('HomeRoute'), findsOneWidget);
    expect(caller.result, 'got null');
  });

  // Steps: push PickerRoute with push<int>, replaceAll with HomeRoute and
  // PickerRoute with a new query param, then close the picker with 7.
  // Happened: since 12.6.0, the push answered null at the replaceAll, though
  // the picker kept its screen.
  // Should: the push waits while the picker shows, and gets 7.
  testWidgets('The caller of a screen that replaceAll keeps waits for it', (
    tester,
  ) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    final caller = _Caller(router.push<int>(_picker));
    await tester.pumpAndSettle();

    unawaited(router.replaceAll([const NamedRoute('HomeRoute'), _pickerAgain]));
    await tester.pumpAndSettle();
    expect(find.text('PickerRoute q=1'), findsOneWidget);
    expect(caller.result, 'waiting');

    router.pop(7);
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute'), findsOneWidget);
    expect(caller.result, 'got 7');
  });

  // Steps: push ShellRoute showing ChildARoute with push<int>, then navigate
  // to ShellRoute showing ChildBRoute.
  // Happened: since 12.6.0, the push answered null, though the shell stayed.
  // Should: the shell shows ChildBRoute, and its push waits.
  testWidgets('The caller of a shell keeps waiting when a link opens another '
      'of its children', (tester) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    final caller = _Caller(
      router.push<int>(
        const NamedRoute('ShellRoute', children: [NamedRoute('ChildARoute')]),
      ),
    );
    await tester.pumpAndSettle();

    unawaited(
      router.navigate(
        const NamedRoute('ShellRoute', children: [NamedRoute('ChildBRoute')]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ChildBRoute'), findsOneWidget);
    expect(caller.result, 'waiting');
  });

  // Steps: push ShellRoute showing ChildARoute, push ChildBRoute in the
  // shell's router with push<int>, then navigate from the root to ShellRoute
  // showing ChildARoute and ChildBRoute with a new query param.
  // Happened: since 12.6.0, the nested push answered null.
  // Should: ChildBRoute shows the new query param, and its push waits.
  testWidgets('The caller of a nested screen reached again keeps waiting', (
    tester,
  ) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    unawaited(
      router.push(
        const NamedRoute('ShellRoute', children: [NamedRoute('ChildARoute')]),
      ),
    );
    await tester.pumpAndSettle();
    final shell = router.innerRouterOf<StackRouter>('ShellRoute')!;
    final caller = _Caller(shell.push<int>(const NamedRoute('ChildBRoute')));
    await tester.pumpAndSettle();

    unawaited(
      router.navigate(
        const NamedRoute(
          'ShellRoute',
          children: [
            NamedRoute('ChildARoute'),
            NamedRoute('ChildBRoute', queryParams: {'q': '1'}),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ChildBRoute q=1'), findsOneWidget);
    expect(caller.result, 'waiting');
  });

  // Steps: start an app whose home page has a guard that shows WelcomeRoute
  // with redirectUntil and never lets the home page in, then open a link to
  // WelcomeRoute.
  // Happened: since 12.6.0, the screen went blank. The link's page took over
  // WelcomeRoute's screen, the redirect's wait ended as if WelcomeRoute had
  // closed, the guard rejected the home page, and removing the redirect took
  // the link's page off.
  // Should: WelcomeRoute stays on screen, and the guard keeps waiting.
  testWidgets('A link to the redirect a guard shows keeps it on screen', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        _page('WelcomeRoute', '/welcome'),
        AutoRoute(
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
          path: '/',
          initial: true,
          guards: [
            AutoRouteGuard.simple((resolver, _) {
              unawaited(
                resolver.redirectUntil(const NamedRoute('WelcomeRoute')),
              );
            }),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    expect(router.topRoute.name, 'WelcomeRoute');

    unawaited(router.navigatePath('/welcome'));
    await tester.pumpAndSettle();
    expect(find.text('WelcomeRoute'), findsOneWidget);
    expect(router.stack.map((page) => page.name), ['WelcomeRoute']);
    expect(router.currentUrl, '/welcome');
  });
}
