import 'package:auto_route/auto_route.dart';
import 'package:example/nested-navigation/nested_navigation.router.gr.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(NestedNavigationApp());
}

class NestedNavigationApp extends StatelessWidget {
  NestedNavigationApp({super.key});

  final nestedRouter = NestedRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: nestedRouter.config(),
    );
  }
}

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

@RoutePage()
class HostScreen extends StatelessWidget {
  const HostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Host Screen'),

        /// This will automatically display a back button if the nested router can pop
        leading: AutoLeadingButton(),
      ),
      body: AutoRouter(),
    );
  }
}

@RoutePage()
class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.pushRoute(SecondRoute()),
          child: Text('Go to second screen'),
        ),
      ),
    );
  }
}

@RoutePage()
class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.maybePop(),
          child: Text('Go Back'),
        ),
      ),
    );
  }
}
