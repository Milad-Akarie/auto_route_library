import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#126929: a go_router page built by pageBuilder froze the app
// when its back button was pressed.
// Setup: a details page that is a CustomRoute with a customRouteBuilder, under
// an AppBar that shows the automatic back button.
// Steps: open the details page, tap its back button.
// Should: the home page shows again, and the app is not stuck.
void main() {
  testWidgets('The back button of a page built by customRouteBuilder goes back', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Scaffold(body: Text('HomeRoute'))),
        ),
        CustomRoute(
          path: '/details',
          page: PageInfo(
            'DetailsRoute',
            builder: (_) => Scaffold(
              appBar: AppBar(leading: const AutoLeadingButton()),
              body: const Text('DetailsRoute'),
            ),
          ),
          customRouteBuilder: <T>(context, child, page) => PageRouteBuilder<T>(
            settings: page,
            pageBuilder: (_, _, _) => child,
            transitionsBuilder: TransitionsBuilders.fadeIn,
          ),
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('DetailsRoute')));
    await tester.pumpAndSettle();
    expect(find.text('DetailsRoute'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute'), findsOneWidget);
    expect(find.text('DetailsRoute'), findsNothing);
    expect(router.currentUrl, '/');
  });
}
