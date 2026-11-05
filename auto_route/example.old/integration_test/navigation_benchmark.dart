import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

// Times the navigation apps do most, in profile mode: push and pop, a deep
// link through nested routers, tab switches of each kind, and a push through
// guards. It is a benchmark, not a test, so all_tests.dart leaves it out.
// Run it from auto_route/example on its own, on macOS or a phone:
//
//   flutter drive --profile --no-dds --driver=test_driver/perf_driver.dart --target=integration_test/navigation_benchmark.dart -d macos
//
// traceAction connects to the app's own VM service. On a phone the app can't
// reach it through the development service on the host, so `--no-dds`.
//
// For each case the driver writes the frames' build and raster times, and the
// time the case's push, navigate or tab change call takes before it returns, to
// build/navigation_benchmark.json, and prints them as `RESULT` lines.
// Pages show no transition, so each step's frames are the router's own work.
// A benchmark run on its own, so not a `_test` file.
// ignore: prefer-correct-test-file-name
void main() {
  final syncMicros = <String, double>{};
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = .fullyLive
    ..reportData = {'sync_micros': syncMicros};

  // Times [steps] runs of [step] in a timeline under [key], and the median
  // time of the router call [step] makes before it awaits.
  Future<void> measure(
    String key,
    Future<void> Function(int index, Stopwatch call) step,
  ) async {
    final calls = <int>[];
    await binding.traceAction(
      () async {
        for (var index = 0; index < _steps; index++) {
          final call = Stopwatch();
          await step(index, call);
          calls.add(call.elapsedMicroseconds);
        }
      },
      reportKey: key,
    );
    syncMicros[key] = _median(calls);
  }

  testWidgets('navigation benchmark', (tester) async {
    final router = _buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();

    // Run every case once untimed, so the timed runs find their code compiled
    // and their images cached.
    for (final warmUp in [true, false]) {
      Future<void> run(
        String key,
        Future<void> Function(int index, Stopwatch call) step,
      ) async {
        if (warmUp) {
          for (var index = 0; index < 3; index++) {
            await step(index, Stopwatch());
          }
        } else {
          await measure(key, step);
        }
      }

      await run('push_pop', (_, call) async {
        call.start();
        unawaited(router.push(const NamedRoute('DetailsRoute')));
        call.stop();
        await tester.pumpAndSettle();
        expect(router.current.name, 'DetailsRoute');
        router.pop<void>();
        await tester.pumpAndSettle();
      });

      await run('guarded_push_pop', (_, call) async {
        call.start();
        unawaited(router.push(const NamedRoute('GuardedRoute')));
        call.stop();
        await tester.pumpAndSettle();
        expect(router.current.name, 'GuardedRoute');
        router.pop<void>();
        await tester.pumpAndSettle();
      });

      await run('deep_link', (index, call) async {
        call.start();
        unawaited(router.navigatePath(_deepLink(index)));
        call.stop();
        await tester.pumpAndSettle();
        expect(router.topMatch.name, 'Level${_depth - 1}');
        unawaited(router.navigatePath('/'));
        await tester.pumpAndSettle();
      });

      for (final kind in _Tabs.values) {
        unawaited(router.navigatePath('/${kind.name}'));
        await tester.pumpAndSettle();
        final tabs = router.innerRouterOf<TabsRouter>('${kind.parent}Route')!;
        await run('tabs_${kind.name}', (index, call) async {
          call.start();
          tabs.setActiveIndex((index + 1) % _tabCount);
          call.stop();
          await tester.pumpAndSettle();
        });
        unawaited(router.navigatePath('/'));
        await tester.pumpAndSettle();
      }
    }
  });
}

const _steps = 40;
const _depth = 5;
const _tabCount = 4;

/// The kinds of tabs auto_route builds, by the parent route that holds them.
enum _Tabs {
  indexedStack('IndexedStack'),
  pageView('PageView'),
  tabBar('TabBar');

  new(this.parent);

  final String parent;
}

double _median(List<int> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle].toDouble()
      : (sorted[middle - 1] + sorted[middle]) / 2;
}

// '/level0/7/level1/7/...', a different id each step so every step changes the stack.
String _deepLink(int index) =>
    '/${[for (var depth = 0; depth < _depth; depth++) 'level$depth/$index'].join('/')}';

final _alwaysLetIn = AutoRouteGuard.simple((resolver, _) => resolver.next());

final _noTransition = RouteType.custom(
  transitionsBuilder: TransitionsBuilders.noTransition,
  duration: .zero,
  reverseDuration: .zero,
);

RootStackRouter _buildRouter() {
  return RootStackRouter.build(
    defaultRouteType: _noTransition,
    routes: [
      // An app's other routes, which a url is matched against first.
      for (var i = 0; i < 30; i++) _route('OtherRoute$i', path: '/other$i'),
      _route('HomeRoute', path: '/'),
      _route('DetailsRoute', path: '/details'),
      _route(
        'GuardedRoute',
        path: '/guarded',
        guards: [_alwaysLetIn, _alwaysLetIn, _alwaysLetIn],
      ),
      _level(0),
      for (final kind in _Tabs.values)
        AutoRoute(
          page: PageInfo(
            '${kind.parent}Route',
            builder: (_) => _TabsHost(kind),
          ),
          path: '/${kind.name}',
          children: [
            for (var i = 0; i < _tabCount; i++)
              _route('${kind.parent}Tab$i', path: 'tab$i'),
          ],
        ),
    ],
  );
}

AutoRoute _route(
  String name, {
  required String path,
  List<AutoRouteGuard> guards = const [],
}) {
  return AutoRoute(
    page: PageInfo(name, builder: (_) => const _BenchmarkPage()),
    path: path,
    guards: guards,
  );
}

// Level0 to Level3 are shells with their own router, Level4 is a page.
AutoRoute _level(int depth) {
  final name = 'Level$depth';
  final path = '${depth == 0 ? '/' : ''}level$depth/:id$depth';
  if (depth == _depth - 1) return _route(name, path: path);
  return AutoRoute(
    page: PageInfo.emptyShell(name),
    path: path,
    children: [_level(depth + 1)],
  );
}

/// A page with a list, so building it costs about what a real page does.
class _BenchmarkPage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final name = context.routeData.name;
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView.builder(
        itemCount: 30,
        itemBuilder: (_, index) => ListTile(title: Text('$name item $index')),
      ),
    );
  }
}

/// Shows its routes as tabs of [kind], with a bottom bar to switch them.
class _TabsHost extends StatelessWidget {
  const new(this.kind);

  final _Tabs kind;

  @override
  Widget build(BuildContext context) {
    final routes = [
      for (var i = 0; i < _tabCount; i++) NamedRoute('${kind.parent}Tab$i'),
    ];
    return switch (kind) {
      .indexedStack => AutoTabsRouter(
        routes: routes,
        builder: (_, child) => _TabsScaffold(child: child),
      ),
      .pageView => AutoTabsRouter.pageView(
        routes: routes,
        builder: (_, child, _) => _TabsScaffold(child: child),
      ),
      .tabBar => AutoTabsRouter.tabBar(
        routes: routes,
        builder: (_, child, _) => _TabsScaffold(child: child),
      ),
    };
  }
}

class _TabsScaffold extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tabs = AutoTabsRouter.of(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabs.activeIndex,
        onTap: tabs.setActiveIndex,
        type: .fixed,
        items: [
          for (var i = 0; i < _tabCount; i++)
            BottomNavigationBarItem(
              icon: const Icon(Icons.circle),
              label: 'Tab $i',
            ),
        ],
      ),
    );
  }
}
