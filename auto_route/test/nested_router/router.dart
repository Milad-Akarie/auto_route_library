import 'package:auto_route/auto_route.dart';
import '../main_router.dart';

class NestedRouter extends MainRouter {
  @override
  final List<AutoRoute> routes = [
    AutoRoute(path: '/', page: FirstRoute.page),
    AutoRoute(path: '/second', page: SecondHostRoute.page, children: [
      AutoRoute(path: '', page: SecondNested1Route.page),
      AutoRoute(path: 'nested2', page: SecondNested2Route.page, fullscreenDialog: true),
    ]),
  ];
}
