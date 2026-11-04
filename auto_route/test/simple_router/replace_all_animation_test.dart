import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

// flutter/flutter#151885: with MaterialPages, go('screen4') from a stack of
// three pages showed screen4 with the pop animation of the page it replaced.
// Steps: push S2 and S3 over S1, then replaceAll with S4.
// Should: S4 slides in (its route's animation runs forward), and no page left
// in the tree is on its way out.
void main() {
  testWidgets('Replacing a stack of pages with a new one slides the new page in (flutter/flutter#151885)', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('S1'), path: '/'),
        AutoRoute(page: _page('S2'), path: '/s2'),
        AutoRoute(page: _page('S3'), path: '/s3'),
        AutoRoute(page: _page('S4'), path: '/s4'),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('S2')));
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('S3')));
    await tester.pumpAndSettle();

    unawaited(router.replaceAll([const NamedRoute('S4')]));
    // the page is added a frame or two after the call
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final s4 = ModalRoute.of(tester.element(find.text('S4')))!;
    expect(s4.animation!.status, AnimationStatus.forward);
    for (final name in ['S1', 'S2', 'S3']) {
      final finder = find.text(name, skipOffstage: false);
      if (finder.evaluate().isEmpty) continue;
      expect(ModalRoute.of(tester.element(finder))!.animation!.status, isNot(AnimationStatus.reverse), reason: name);
    }

    await tester.pumpAndSettle();
    expect(router.stack.map((p) => p.name), ['S4']);
  });
}
