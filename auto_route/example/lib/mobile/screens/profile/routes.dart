// import 'package:auto_route/auto_route.dart';
// import 'package:example/mobile/screens/profile/my_books_page.dart';
// import 'package:auto_route/empty_router_widgets.dart';
// import 'profile_page.dart';
//
import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';

 final profileTab = AutoRoute(
  path: 'profile',
  page: ProfileTab.page,
  children: [
    AutoRoute(path: '', page: ProfileRoute.page),
    AutoRoute(path: 'my-books', page: MyBooksRoute.page),
  ],
);
