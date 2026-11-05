import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// An app with state restoration that builds a new router each time it
/// starts, as an app the platform ended and restored does.
///
/// `WidgetTester.restartAndRestore` rebuilds it from scratch; [router] is
/// the router of the last start.
class RestorableRouterApp extends StatefulWidget {
  const new(this._routerBuilder, {super.key, this.navRestorationScopeId});

  final RootStackRouter Function() _routerBuilder;

  /// The restoration scope of the root navigator, which restores the routes
  /// pushed with `Navigator.restorablePush`.
  final String? navRestorationScopeId;

  static late RootStackRouter router;

  @override
  State<RestorableRouterApp> createState() => _RestorableRouterAppState();
}

class _RestorableRouterAppState extends State<RestorableRouterApp> {
  late final RootStackRouter router = RestorableRouterApp.router = widget
      ._routerBuilder();

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      restorationScopeId: 'app',
      routerConfig: router.config(
        navRestorationScopeId: widget.navRestorationScopeId,
      ),
    );
  }
}

PageInfo page(String name) => .new(name, builder: (_) => Text(name));
