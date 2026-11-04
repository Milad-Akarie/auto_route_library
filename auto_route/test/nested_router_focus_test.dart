import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/112367: rebuilding a nested
  // Navigator whose pages are new objects each build took focus from a text
  // field outside it, and gave it back to the field that last had focus
  // inside it.
  // Steps: HostRoute shows an outer TextField above a nested AutoRouter whose
  // page is an inner TextField. Tap the inner field, then the outer one, then
  // rebuild HostRoute, as a MediaQuery change does.
  // Should: the outer field keeps focus. auto_route hands the nested
  // Navigator the same page objects on a rebuild, so it has nothing to update.
  testWidgets('Rebuilding a nested router keeps focus in a field outside it', (tester) async {
    late StateSetter setHostState;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HostRoute',
            builder: (_) => StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return const Scaffold(
                  body: Column(
                    children: [
                      TextField(key: Key('outer')),
                      Expanded(child: AutoRouter()),
                    ],
                  ),
                );
              },
            ),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo('InnerRoute', builder: (_) => const TextField(key: Key('inner'))),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    await tester.tap(find.byKey(const Key('inner')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('outer')));
    await tester.pump();
    final outerFocus = FocusManager.instance.primaryFocus;
    expect(outerFocus?.context?.findAncestorWidgetOfExactType<TextField>()?.key, const Key('outer'));

    setHostState(() {});
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, same(outerFocus));
  });
}
