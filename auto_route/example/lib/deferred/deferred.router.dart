import 'package:auto_route/auto_route.dart';
import 'package:example/deferred/deferred.router.gr.dart';

/// Routes to the two pages of `pages.dart`, a library whose pages load on
/// demand because one of them asks to.
@AutoRouterConfig(generateForDir: ['lib/deferred'])
class DeferredRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(path: '/', page: DeferredFirstRoute.page),
    AutoRoute(path: '/second', page: DeferredSecondRoute.page),
  ];
}
