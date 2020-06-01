import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/router/router.gr.dart';
import 'package:example/screens/nested_screens/nested_screen_two.dart';

import 'nested_router.gr.dart';
import 'nested_screen.dart';

@MaterialAutoRouter()
class NestedRouter extends $NestedRouter {
  @RoutesList(namePrefix: '/second/{id}')
  static const nestedRoutes = <AutoRoute>[
    AutoRoute(page: NestedScreen, initial: true),
    AutoRoute(path: '/nested', page: NestedScreenTwo),
  ];
}
