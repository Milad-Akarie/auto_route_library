import 'package:auto_route/auto_route.dart';
import 'package:example/dollar_names/dollar_names.router.gr.dart';

/// Routes to the page of `venue_page.dart`, whose class and parameters are
/// named with a `$`.
@AutoRouterConfig(generateForDir: ['lib/dollar_names'])
class DollarNamesRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    RedirectRoute(path: '/', redirectTo: '/users/1'),
    AutoRoute(path: r'/users/:user$id', page: Venue$Route.page),
  ];
}
