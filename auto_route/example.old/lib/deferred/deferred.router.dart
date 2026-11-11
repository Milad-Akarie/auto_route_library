import 'package:auto_route/auto_route.dart';
import 'package:example/deferred/deferred.router.gr.dart';

/// Routes to the two pages of the library `deferred_first_page.dart`, which
/// loads on demand because one of them asks to. The second page is a part of
/// that library.
@AutoRouterConfig(generateForDir: ['lib/deferred'])
class DeferredRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(path: '/', page: DeferredFirstRoute.page),
    AutoRoute(path: '/second', page: DeferredSecondRoute.page),
  ];
}
