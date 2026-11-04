import 'package:auto_route/auto_route.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  for (final kind in _TabsKind.values) {
    // Guards https://github.com/Milad-Akarie/auto_route_library/issues/2170
    // Steps: an AutoTabsRouter with three tabs, each a page with a title, a
    // text and a button. Open the second tab, the third, then the first again.
    // Reported: once another tab has been opened, the earlier tabs' semantics
    // are gone, so a screen reader can't read them; for the tab-bar kind still
    // on 10.1.2.
    // Should: the open tab's title, text and button are in the semantics tree
    // and not hidden; the other tabs' are hidden or left out.
    testWidgets('${kind.name}: a tab opened again is in the semantics tree', (tester) async {
      final semantics = tester.ensureSemantics();
      // A phone's screen: the pages laid out beside the open one only reached
      // the semantics tree, not hidden, on a narrow screen.
      tester.view.physicalSize = const Size(1080, 2361);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      _tabsKind = kind;
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: _TabsHostRoute.page,
            path: '/',
            initial: true,
            children: [
              AutoRoute(page: _FirstTabRoute.page, path: 'first'),
              AutoRoute(page: _SecondTabRoute.page, path: 'second'),
              AutoRoute(page: _ThirdTabRoute.page, path: 'third'),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      final tabsRouter = router.innerRouterOf<TabsRouter>(_TabsHostRoute.name)!;

      // The semantics nodes a screen reader gets whose label holds [text].
      List<SemanticsNode> nodesLabeled(String text) {
        final nodes = <SemanticsNode>[];
        bool visit(SemanticsNode node) {
          if (node.label.split('\n').contains(text)) nodes.add(node);
          node.visitChildren(visit);
          return true;
        }

        visit(tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!);
        return nodes;
      }

      void expectReadable(String label) {
        for (final text in ['$label title', '$label text', '$label button']) {
          expect(nodesLabeled(text).where((node) => !node.flagsCollection.isHidden), hasLength(1), reason: text);
        }
      }

      void expectNotReadable(String label) {
        for (final text in ['$label title', '$label text', '$label button']) {
          expect(nodesLabeled(text).where((node) => !node.flagsCollection.isHidden), isEmpty, reason: text);
        }
      }

      for (final (index, label, others) in [
        (1, 'Second', ['First', 'Third']),
        (2, 'Third', ['First', 'Second']),
        (0, 'First', ['Second', 'Third']),
      ]) {
        tabsRouter.setActiveIndex(index);
        await tester.pumpAndSettle();
        expectReadable(label);
        others.forEach(expectNotReadable);
      }
      semantics.dispose();
    });
  }
}

enum _TabsKind { indexedStack, pageView, tabBar }

_TabsKind _tabsKind = .indexedStack;

class _TabsHostRoute extends PageRouteInfo<void> {
  const _TabsHostRoute() : super(name);

  static const String name = '_TabsHostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) {
      const routes = [_FirstTabRoute(), _SecondTabRoute(), _ThirdTabRoute()];
      return switch (_tabsKind) {
        .indexedStack => const AutoTabsRouter(routes: routes),
        .pageView => const AutoTabsRouter.pageView(routes: routes),
        .tabBar => const AutoTabsRouter.tabBar(routes: routes),
      };
    },
  );
}

Widget _tabPage(String label) => Scaffold(
  appBar: AppBar(title: Text('$label title')),
  body: Column(
    children: [
      Text('$label text'),
      ElevatedButton(onPressed: () {}, child: Text('$label button')),
    ],
  ),
);

class _FirstTabRoute extends PageRouteInfo<void> {
  const _FirstTabRoute() : super(name);

  static const String name = '_FirstTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => _tabPage('First'));
}

class _SecondTabRoute extends PageRouteInfo<void> {
  const _SecondTabRoute() : super(name);

  static const String name = '_SecondTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => _tabPage('Second'));
}

class _ThirdTabRoute extends PageRouteInfo<void> {
  const _ThirdTabRoute() : super(name);

  static const String name = '_ThirdTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => _tabPage('Third'));
}
