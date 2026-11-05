import 'package:auto_route/auto_route.dart';
import 'package:example/nested-navigation/nested_navigation.router.gr.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(NestedNavigationApp());
}

/// Root widget of the nested navigation example.
class NestedNavigationApp extends StatelessWidget {
  /// Creates the app, which builds its own [NestedRouter].
  new({super.key});

  /// The router of this app.
  final nestedRouter = NestedRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: nestedRouter.config());
  }
}

/// Routes of the nested navigation example: a host page with two child pages.
@AutoRouterConfig(generateForDir: ['lib/nested-navigation'])
class NestedRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      initial: true,
      page: HostRoute.page,
      children: [
        AutoRoute(page: FirstRoute.page, initial: true),
        AutoRoute(page: SecondRoute.page),
      ],
    ),
  ];
}

/// Host page whose body is a nested router, with a back button when that router
/// can pop.
@RoutePage()
class HostScreen extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Screen'),

        /// This will automatically display a back button if the nested router
        /// can pop
        leading: const AutoLeadingButton(),
      ),
      body: const AutoRouter(),
    );
  }
}

/// Child page with a button that opens [SecondScreen] in the host's nested
/// router.
@RoutePage()
class FirstScreen extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.pushRoute(const SecondRoute()),
          child: const Text('Go to second screen'),
        ),
      ),
    );
  }
}

/// Child page with a button that pops back to [FirstScreen].
@RoutePage()
class SecondScreen extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.maybePop(),
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}
