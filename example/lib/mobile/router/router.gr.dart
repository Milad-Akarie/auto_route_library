// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i1;
import '../screens/home_page.dart' as _i2;
import '../screens/book_list_page.dart' as _i3;
import '../screens/book_details_page.dart' as _i4;
import '../screens/settings_page.dart' as _i5;
import 'package:flutter/material.dart' as _i6;

class MyRouterConfig extends _i1.AutoRouterConfig {
  MyRouterConfig();

  @override
  final Map<Type, _i1.PageFactory> pagesMap = {
    _i2.HomePage: (data) {
      return _i1.MaterialPageX(data: data, child: _i2.HomePage());
    },
    _i1.TabRouterPage: (data) {
      return _i1.MaterialPageX(data: data, child: const _i1.TabRouterPage());
    },
    _i3.BookListPage: (data) {
      return _i1.MaterialPageX(data: data, child: _i3.BookListPage());
    },
    _i4.BookDetailsPage: (data) {
      return _i1.MaterialPageX(
          data: data,
          child: _i4.BookDetailsPage(bookId: data.pathParams.getInt('id')));
    },
    _i5.SettingsPage: (data) {
      return _i1.MaterialPageX(data: data, child: _i5.SettingsPage());
    }
  };

  @override
  List<_i1.RouteConfig> get routes => [
        _i1.RouteConfig(HomePageRoute.key,
            path: '/',
            page: _i2.HomePage,
            usesTabsRouter: true,
            children: [
              _i1.RouteConfig(BooksTab.key,
                  path: 'books',
                  page: _i1.TabRouterPage,
                  children: [
                    _i1.RouteConfig(BookListPageRoute.key,
                        path: 'list', page: _i3.BookListPage),
                    _i1.RouteConfig(BookDetailsPageRoute.key,
                        path: 'list/:id', page: _i4.BookDetailsPage)
                  ]),
              _i1.RouteConfig(SettingsTab.key,
                  path: 'settings',
                  page: _i1.TabRouterPage,
                  children: [
                    _i1.RouteConfig(SettingsPageRoute.key,
                        path: '', page: _i5.SettingsPage)
                  ])
            ]),
        _i1.RouteConfig('*#redirect',
            path: '*', redirectTo: '/', fullMatch: true, usesTabsRouter: false)
      ];
}

class HomePageRoute extends _i1.PageRouteInfo {
  HomePageRoute({List<_i1.PageRouteInfo> children})
      : super(key, path: '/', children: children);

  static const String key = 'HomePageRoute';
}

class BooksTab extends _i1.PageRouteInfo {
  BooksTab({List<_i1.PageRouteInfo> children})
      : super(key, path: 'books', children: children);

  static const String key = 'BooksTab';
}

class SettingsTab extends _i1.PageRouteInfo {
  SettingsTab({List<_i1.PageRouteInfo> children})
      : super(key, path: 'settings', children: children);

  static const String key = 'SettingsTab';
}

class BookListPageRoute extends _i1.PageRouteInfo {
  BookListPageRoute() : super(key, path: 'list');

  static const String key = 'BookListPageRoute';
}

class BookDetailsPageRoute extends _i1.PageRouteInfo {
  BookDetailsPageRoute({@_i6.required id})
      : super(key, path: 'list/:id', pathParams: {'id': id});

  static const String key = 'BookDetailsPageRoute';
}

class SettingsPageRoute extends _i1.PageRouteInfo {
  SettingsPageRoute() : super(key, path: '');

  static const String key = 'SettingsPageRoute';
}

class BookDetailsPageArgs extends _i1.RouteArgs {
  BookDetailsPageArgs() : super([]);
}
