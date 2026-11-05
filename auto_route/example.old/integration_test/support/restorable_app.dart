import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// An app with state restoration that builds a new router each time it
/// starts, as an app the platform ended and restored does.
///
/// [WidgetTester.restartAndRestore] rebuilds it from scratch with the saved
/// restoration data; [router] is the router of the last start.
class RestorableRouterApp extends StatefulWidget {
  const new(this.buildRouter, {super.key});

  final RootStackRouter Function() buildRouter;

  static late RootStackRouter router;

  @override
  State<RestorableRouterApp> createState() => _RestorableRouterAppState();
}

class _RestorableRouterAppState extends State<RestorableRouterApp> {
  // Shared across a restart, so the restored app finds the same router.
  // ignore: dispose-fields
  late final RootStackRouter router = RestorableRouterApp.router = widget
      .buildRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      restorationScopeId: 'app',
      // The app opens at '/': on web the browser's url would otherwise carry
      // over from the previous test.
      routerConfig: router.config(
        deepLinkBuilder: (link) => link.initial ? DeepLink.defaultPath : link,
      ),
    );
  }
}

/// Shows a [RestorableRouterApp] that builds its router with [buildRouter],
/// and waits for its first page.
///
/// Like pumpRouterApp in app.dart, it first brings the app to the
/// foreground: the test binding forgets the app's lifecycle state after
/// each test, and while it's unknown Flutter stops telling Android whether
/// it handles back.
Future<void> pumpRestorableApp(
  WidgetTester tester,
  RootStackRouter Function() buildRouter,
) async {
  tester.binding.handleAppLifecycleStateChanged(.resumed);
  await tester.pumpWidget(RestorableRouterApp(buildRouter));
  await tester.pumpAndSettle();
}

/// A page showing its route's name.
PageInfo namedPage(String name) => .new(
  name,
  builder: (_) => Scaffold(body: Center(child: Text(name))),
);
