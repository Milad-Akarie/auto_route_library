import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/168915
  // In go_router, with a ShellRoute, VoiceOver on iOS said nothing when a
  // BottomNavigationBar item became selected. VoiceOver announces a change
  // of the selected state on the node it is on; a bar built anew gives that
  // node a new id, and the announcement is lost.
  // Steps: an AutoTabsScaffold with a BottomNavigationBar of three tabs; with
  // semantics on, tap the second item, then the third.
  // Should: each item keeps its semantics node, and the tapped one turns
  // selected while the one before turns unselected.
  testWidgets(
    'A bottom bar item keeps its semantics node when it becomes selected (flutter/flutter#168915)',
    (tester) async {
      final semantics = tester.ensureSemantics();
      const labels = ['Movies', 'Series', 'Settings'];
      PageInfo tab(String name) =>
          .new(name, builder: (_) => Text('$name page'));
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: PageInfo(
              'Host',
              builder: (_) => AutoTabsScaffold(
                routes: [for (final label in labels) _Route(label)],
                bottomNavigationBuilder: (_, tabsRouter) => BottomNavigationBar(
                  currentIndex: tabsRouter.activeIndex,
                  onTap: tabsRouter.setActiveIndex,
                  items: [
                    for (final label in labels)
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.circle),
                        label: label,
                      ),
                  ],
                ),
              ),
            ),
            path: '/',
            children: [
              for (final label in labels)
                AutoRoute(page: tab(label), path: label.toLowerCase()),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);

      // The bar item labeled [label]: its semantics node's id and whether it is
      // selected.
      (int, bool) item(String label) {
        final node = tester.getSemantics(find.text(label));
        return (node.id, node.flagsCollection.isSelected == .isTrue);
      }

      final ids = {for (final label in labels) label: item(label).$1};
      expect(item('Movies').$2, isTrue);

      for (final (selected, previous) in [
        ('Series', 'Movies'),
        ('Settings', 'Series'),
      ]) {
        await tester.tap(find.text(selected));
        await tester.pumpAndSettle();
        expect(find.text('$selected page'), findsOneWidget);
        expect(item(selected), (ids[selected], true));
        expect(item(previous), (ids[previous], false));
      }
      semantics.dispose();
    },
  );
}

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
