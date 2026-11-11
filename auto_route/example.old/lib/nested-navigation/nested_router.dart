import 'package:auto_route/auto_route.dart';
import 'package:example/nested-navigation/nested_router.gr.dart';

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
