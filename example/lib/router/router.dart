import 'package:auto_route/auto_route.dart';
import 'package:example/screens/book_details_page.dart';
import 'package:example/screens/book_list_page.dart';
import 'package:example/screens/home_page.dart';
import 'package:example/screens/unknown_route.dart';

@MaterialAutoRouter(
  routes: <AutoRoute>[
    AutoRoute(path: '/', page: HomePage),
    AutoRoute(path: '/books', page: BookListPage),
    AutoRoute(path: '/books/:id', page: BookDetailsPage, name: 'BookDetails'),
    AutoRoute(path: '*', page: UnknownRouteScreen),
  ],
)
class $MyRouterConfig {}

// Widget customTrans(
//     BuildContext context,
//     Animation<double> animation,
//     Animation<double> secondaryAnimation,
//     Widget child,
//     ) {
//   return FadeTransition(opacity: animation, child: child);
// }
//
// Route myRouteBuilder(BuildContext context, CustomPage page) {
//   return PageRouteBuilder(
//     pageBuilder: (_, __, ___) => page.child,
//     settings: page,
//   );
// }
