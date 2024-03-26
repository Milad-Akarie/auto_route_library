import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';

//ignore_for_file: public_member_api_docs
final profileTab = RouteDef(
  path: 'profile',
  page: ProfileTab.page,
  children: [
    RouteDef(path: '', page: ProfileRoute.page),
    RouteDef(path: 'my-books', page: MyBooksRoute.page),
  ],
);
