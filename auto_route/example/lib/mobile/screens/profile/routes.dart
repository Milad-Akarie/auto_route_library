import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/profile/my_books_page.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../settings.dart';
import 'profile_page.dart';

const profileTab = AutoRoute(
  path: 'profile',
  name: 'ProfileTab',
  page: EmptyRouterPage,
  children: [
    AutoRoute(path: '', page: ProfilePage),
    AutoRoute(path: 'my-books', page: MyBooksPage),
  ],
);
