import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.dart';
import 'package:example/mobile/router/router.gr.dart';

//ignore_for_file: public_member_api_docs
final profileRoute = AutoRoute(
  path: 'profile',
  page: ProfileTab.page,
  children: [
    AutoRoute(path: '', page: ProfileRoute.page),
    AutoRoute(path: 'my-books', page: MyBooksRoute.page),
  ],
);
