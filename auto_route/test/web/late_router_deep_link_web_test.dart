@TestOn('browser')
library;

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../main_router.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  setUp(rewindBrowserHistory);

  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(page: FirstRoute.page, path: '/'),
      AutoRoute(page: SecondRoute.page, path: '/second'),
    ],
  );

  // On web, open an app at '/second' whose router is built after its first
  // frame, behind a splash. The browser should keep one history entry for the
  // link; with the router's empty route reported first, it held
  // ['/second', '/', '/second'] and the first back showed the home page.
  final apps = <String, Widget Function(RootStackRouter router)>{
    'router.config()': (router) => MaterialApp.router(routerConfig: router.config()),
    'routerDelegate and routeInformationParser': (router) =>
        MaterialApp.router(routeInformationParser: router.defaultRouteParser(), routerDelegate: router.delegate()),
  };
  for (final MapEntry(key: name, value: buildApp) in apps.entries) {
    testWidgets('On web, a deep link to a router built after the first frame adds no history entry, with $name', (
      tester,
    ) async {
      openBrowserAt(tester, '/second');
      final router = buildRouter();
      addTearDown(router.dispose);
      await pumpAsRunApp(tester, _Splash(builder: () => buildApp(router)));
      expect(find.text('SecondRoute'), findsOneWidget);
      expect(router.urlState.url, '/second');
      expect(browserPath, '/second');
      expect(browserSerialCount, 0);
      expect(appWroteBrowserEntry, isTrue);
    });
  }
}

// Shows nothing for the app's first frame, then the app.
class _Splash extends StatefulWidget {
  const new({required this.builder});

  final Widget Function() builder;

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _ready = true));
  }

  @override
  Widget build(BuildContext context) => _ready ? widget.builder() : const SizedBox();
}
