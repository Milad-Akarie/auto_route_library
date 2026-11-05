import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/857
  // Reported: a settings route shows its children in an AutoTabsRouter on a
  // tablet (two panes) and in an AutoRouter on a phone. Going from the
  // tablet layout to the phone one left the AutoRouter blank.
  // Steps: show the tablet layout, switch to the phone layout, then back and
  // forth once more.
  // Should: the phone layout shows the first child, the list page.
  testWidgets('AutoRouter replacing tabs shows its first page', (tester) async {
    final isTablet = ValueNotifier(true);
    addTearDown(isTablet.dispose);
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'SettingsRoute',
          path: '/',
          builder: (_, _) => ValueListenableBuilder(
            valueListenable: isTablet,
            builder: (_, isWide, _) => isWide
                ? AutoTabsRouter(
                    routes: const [
                      NamedRoute('SettingsListRoute'),
                      NamedRoute('AppearanceRoute'),
                    ],
                    builder: (_, child) => Row(
                      children: [
                        const Expanded(child: Text('two panes')),
                        Expanded(child: child),
                      ],
                    ),
                  )
                : const AutoRouter(),
          ),
          children: [
            NamedRouteDef(
              name: 'SettingsListRoute',
              path: '',
              builder: (_, _) => const Text('SettingsListRoute'),
            ),
            NamedRouteDef(
              name: 'AppearanceRoute',
              path: 'appearance',
              builder: (_, _) => const Text('AppearanceRoute'),
            ),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    final tabletAtStart = find.text('two panes').evaluate().length;

    final shown = <String>[];
    for (final tablet in [false, true, false]) {
      isTablet.value = tablet;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      shown.add(
        [
          if (find.text('two panes').evaluate().isNotEmpty) 'two panes',
          if (find.text('SettingsListRoute').evaluate().isNotEmpty)
            'SettingsListRoute',
        ].join(', '),
      );
    }
    expect(
      (tabletAtStart, shown.join(' | ')),
      (
        1,
        'SettingsListRoute | two panes, SettingsListRoute | SettingsListRoute',
      ),
    );
  });
}
