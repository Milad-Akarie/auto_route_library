import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// On web, a deep link to an app whose router is built after its first frame
// keeps one browser history entry, instead of ['/second', '/', '/second'].
// Headless test: auto_route/test/web/late_router_deep_link_web_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('late router deep link', () {
    RootStackRouter buildRouter() => .build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(page: SecondRoute.page, path: '/second'),
      ],
    );

    final apps = <String, Widget Function(RootStackRouter router)>{
      'router.config()': (router) =>
          MaterialApp.router(routerConfig: router.config()),
      'routerDelegate and routeInformationParser': (router) =>
          MaterialApp.router(
            routeInformationParser: router.defaultRouteParser(),
            routerDelegate: router.delegate(),
          ),
    };

    // Steps: open the app at '/second'; it shows a splash for its first
    // frame, then builds its router.
    // Should: the second page opens at '/second', and on web the browser holds
    // the link in the same history entry, not two more.
    for (final MapEntry(key: name, value: buildApp) in apps.entries) {
      testWidgets(
        'A deep link to a router built after the first frame adds no history '
        'entry, with $name',
        (tester) async {
          final entryBefore = browserEntryIndex() ?? 0;
          final router = buildRouter();
          await pumpAppAtDeepLink(
            tester,
            '/second',
            _Splash(builder: () => buildApp(router)),
          );
          expect(find.text('SecondRoute'), findsOneWidget);
          expect(router.urlState.url, '/second');
          await expectBrowserUrl('/second');
          await expectAppWroteDeepLinkEntry(entryBefore);
        },
      );
    }
  });
}

// Shows nothing for the app's first frame, then the app.
class _Splash extends StatefulWidget {
  const new({required this.builder});

  final Widget Function() builder;

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  var _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => setState(() => _isReady = true),
    );
  }

  @override
  Widget build(BuildContext context) =>
      _isReady ? widget.builder() : const SizedBox();
}
