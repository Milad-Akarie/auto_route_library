import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';

// flutter/flutter#155441: a PopScope(canPop: false) on the app's first page
// was not asked on back, and the app closed.
// Steps: the root router's only page is wrapped in PopScope(canPop:
// false); press Android's back key, or make the predictive back gesture. PopScope
// should hear it with didPop false, the app should not close, and Flutter
// should keep telling Android it handles back. The same first page inside a
// nested router is covered by nested_router/pop_scope_first_page_test.dart.
void main() {
  for (final MapEntry(key: name, value: back) in {
    'system back': systemBack,
    'the predictive back gesture': predictiveBack,
  }.entries) {
    testWidgets(
      '$name on a first page with a PopScope asks it and keeps the app open',
      (tester) async {
        final heard = <bool>[];
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              page: PageInfo(
                'Home',
                builder: (_) => PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, _) => heard.add(didPop),
                  child: const Scaffold(body: Text('Home')),
                ),
              ),
              initial: true,
            ),
          ],
        );
        addTearDown(router.dispose);
        var appClosed = false;
        bool? frameworkHandlesBack;
        tester.binding.handleAppLifecycleStateChanged(.resumed);
        final messenger = tester.binding.defaultBinaryMessenger
          ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'SystemNavigator.pop') appClosed = true;
            if (call.method == 'SystemNavigator.setFrameworkHandlesBack')
              frameworkHandlesBack = call.arguments as bool;
            return null;
          });
        addTearDown(
          () =>
              messenger.setMockMethodCallHandler(SystemChannels.platform, null),
        );
        await tester.pumpWidget(
          MaterialApp.router(
            theme: androidTheme,
            routerConfig: router.config(),
          ),
        );
        await tester.pumpAndSettle();
        expect(frameworkHandlesBack, isTrue);

        await back(tester);
        await back(tester);

        expect(heard, [false, false]);
        expect(appClosed, isFalse);
        expect(frameworkHandlesBack, isTrue, reason: 'after back(tester)');
        expect(find.text('Home'), findsOneWidget);
      },
      skip: kIsWeb,
    ); // Android only: on web Flutter never tells the platform whether it handles back.
  }
}
