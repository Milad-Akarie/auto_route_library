import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1759
// Setup, as in the report: an AutoTabsRouter whose homeIndex and routes come
// from state above it, so a rebuild passes new values.
// Steps: show the tabs with homeIndex 0, show another tab, rebuild the
// AutoTabsRouter with another homeIndex, press back.
// Reported: back goes to the old homeIndex, or throws a RangeError when the
// old homeIndex is past the end of the new, shorter list of tabs.
// Should: back shows the tab of the new homeIndex, and Android hears that
// the tabs take back when the new homeIndex is not the active tab. A homeIndex
// the new tabs don't reach counts as no home tab.
void main() {
  late RootStackRouter router;

  setUp(() {
    _homeIndex = ValueNotifier(0);
    _routes = ValueNotifier(_allTabs);
    addTearDown(_homeIndex.dispose);
    addTearDown(_routes.dispose);
    router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HostRoute',
          path: '/',
          builder: (_, _) => ValueListenableBuilder<List<PageRouteInfo>>(
            valueListenable: _routes,
            builder: (_, routes, _) => ValueListenableBuilder<int>(
              valueListenable: _homeIndex,
              builder: (_, homeIndex, _) =>
                  AutoTabsRouter(routes: routes, homeIndex: homeIndex),
            ),
          ),
          children: [
            for (final name in _names)
              NamedRouteDef(
                name: name,
                path: name.toLowerCase(),
                builder: (_, _) => Text(name),
              ),
          ],
        ),
      ],
    );
  });

  testWidgets('Back shows the tab of a homeIndex that changed', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    final tabs = router.innerRouterOf<TabsRouter>('HostRoute')!
      ..setActiveIndex(3);
    await tester.pumpAndSettle();

    _homeIndex.value = 2;
    await tester.pumpAndSettle();
    await systemBack(tester);

    expect(tester.takeException(), isNull);
    expect(tabs.activeIndex, 2, reason: '_homeIndex.value = 2, then back');
    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('Back with fewer tabs and a new homeIndex does not throw', (
    tester,
  ) async {
    _homeIndex.value = 3;
    await pumpRouterConfigApp(tester, router.config());
    final tabs = router.innerRouterOf<TabsRouter>('HostRoute')!
      ..setActiveIndex(1);
    await tester.pumpAndSettle();

    _routes.value = _allTabs.take(2).toList();
    _homeIndex.value = 0;
    await tester.pumpAndSettle();
    await systemBack(tester);

    expect(tester.takeException(), isNull);
    expect(tabs.activeIndex, 0, reason: 'two tabs, homeIndex 0, then back');
    expect(find.text('Zero'), findsOneWidget);
  });

  testWidgets('Back from the old home tab shows the new one', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    final tabs = router.innerRouterOf<TabsRouter>('HostRoute')!;

    _homeIndex.value = 1;
    await tester.pumpAndSettle();
    await systemBack(tester);

    expect(tester.takeException(), isNull);
    expect(tabs.activeIndex, 1, reason: 'homeIndex moved off the active tab');
    expect(find.text('One'), findsOneWidget);
  });

  // Android closes the app on back unless it was told the tabs take it.
  testWidgets(
    'Android is told the tabs take back once homeIndex leaves the active tab',
    (tester) async {
      final frameworkHandlesBack = FrameworkHandlesBackRecorder()
        ..listen(tester);
      await pumpRouterConfigApp(tester, router.config());
      expect(frameworkHandlesBack.isHandlingBack, isFalse);

      _homeIndex.value = 1;
      await tester.pumpAndSettle();

      expect(frameworkHandlesBack.isHandlingBack, isTrue);
    },
    skip: kIsWeb,
  );

  testWidgets('A homeIndex past the end of the tabs counts as none', (
    tester,
  ) async {
    _homeIndex.value = 3;
    await pumpRouterConfigApp(tester, router.config());
    final tabs = router.innerRouterOf<TabsRouter>('HostRoute')!
      ..setActiveIndex(1);
    await tester.pumpAndSettle();

    _routes.value = _allTabs.take(2).toList();
    await tester.pumpAndSettle();

    expect(tabs.activeIndex, 1, reason: 'the active tab is still there');
    await tabs.maybePop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tabs.activeIndex, 1, reason: 'there is no tab 3 to go to');
  });
}

const _names = ['Zero', 'One', 'Two', 'Three'];
final List<PageRouteInfo> _allTabs = [
  for (final name in _names) NamedRoute(name),
];
late ValueNotifier<int> _homeIndex;
late ValueNotifier<List<PageRouteInfo>> _routes;
