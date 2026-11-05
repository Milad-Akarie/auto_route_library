import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';
import 'router_test_utils.dart';

// flutter/flutter#128793: in go_router, back on the first page of a shell
// inside another shell did not let Android close the app.
// Setup: an outer shell '/outer' whose first page is an inner shell 'inner'
// that holds 'first' and 'second'.
// Steps: open the app on 'first', then push 'second' and press back.
// Should: while 'second' is on top, Flutter tells Android it handles
// back; on 'first', it tells Android it doesn't, so Android closes the app.
void main() {
  testWidgets(
    'Back on the first page of a shell inside a shell lets Android close the '
    'app',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/outer',
            initial: true,
            page: PageInfo('OuterRoute', builder: (_) => const AutoRouter()),
            children: [
              AutoRoute(
                path: 'inner',
                initial: true,
                page: PageInfo(
                  'InnerRoute',
                  builder: (_) => const AutoRouter(),
                ),
                children: [
                  AutoRoute(
                    path: 'first',
                    initial: true,
                    page: _page('FirstRoute'),
                  ),
                  AutoRoute(path: 'second', page: _page('SecondRoute')),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      final frameworkHandlesBack = FrameworkHandlesBackRecorder()
        ..listen(tester);
      await tester.pumpWidget(
        MaterialApp.router(theme: androidTheme, routerConfig: router.config()),
      );
      await tester.pumpAndSettle();
      expectTopPage(router, 'FirstRoute');
      expect(frameworkHandlesBack.isHandlingBack, isFalse);

      final inner = router
          .innerRouterOf<StackRouter>('OuterRoute')!
          .innerRouterOf<StackRouter>('InnerRoute')!;
      unawaited(inner.push(const NamedRoute('SecondRoute')));
      await tester.pumpAndSettle();
      expect(frameworkHandlesBack.isHandlingBack, isTrue);

      await systemBack(tester);
      expectTopPage(router, 'FirstRoute');
      expect(
        frameworkHandlesBack.isHandlingBack,
        isFalse,
        reason: 'after systemBack(tester)',
      );
    },
    skip: kIsWeb,
    // Android only: on web Flutter never tells the platform whether it handles
    // back.
  );
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
