import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// An app with state restoration that builds a new router each time it
/// starts, as an app the platform ended and restored does.
///
/// `WidgetTester.restartAndRestore` rebuilds it from scratch; [router] is
/// the router of the last start.
class RestorableRouterApp extends StatefulWidget {
  const RestorableRouterApp(this.routerBuilder, {super.key});

  final RootStackRouter Function() routerBuilder;

  static late RootStackRouter router;

  @override
  State<RestorableRouterApp> createState() => _RestorableRouterAppState();
}

class _RestorableRouterAppState extends State<RestorableRouterApp> {
  late final RootStackRouter router = RestorableRouterApp.router = widget.routerBuilder();

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(restorationScopeId: 'app', routerConfig: router.config());
  }
}

PageInfo page(String name) => .new(name, builder: (_) => Text(name));
