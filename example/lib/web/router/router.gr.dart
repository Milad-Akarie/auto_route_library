// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i1;
import '../screens/dashboard_page.dart' as _i2;
import '../screens/book_list_page.dart' as _i3;
import '../screens/book_details_page.dart' as _i4;
import '../screens/settings_page.dart' as _i5;
import 'package:flutter/material.dart' as _i6;

class WebRouterConfig extends _i1.AutoRouterConfig {
  WebRouterConfig();

  @override
  final Map<Type, _i1.PageFactory> pagesMap = {
    _i2.DashboardPage: (data) {
      return _i1.CustomPage(data: data, child: _i2.DashboardPage());
    },
    _i3.BookListPage: (data) {
      return _i1.CustomPage(data: data, child: _i3.BookListPage());
    },
    _i4.BookDetailsPage: (data) {
      var args = data.getArgs<BookDetailsPageArgs>(
          orElse: () => BookDetailsPageArgs());
      return _i1.CustomPage(
          data: data,
          child: _i4.BookDetailsPage(bookId: data.pathParams.getInt('id')));
    },
    _i5.SettingsPage: (data) {
      return _i1.CustomPage(data: data, child: _i5.SettingsPage());
    }
  };

  @override
  List<_i1.RouteConfig> get routes => [
        _i1.RouteConfig(DashboardPageRoute.key,
            path: '/',
            page: _i2.DashboardPage,
            children: [
              _i1.RouteConfig('#redirect',
                  path: '', redirectTo: 'books', fullMatch: true),
              _i1.RouteConfig(BookListPageRoute.key,
                  path: 'books', page: _i3.BookListPage),
              _i1.RouteConfig(BookDetailsPageRoute.key,
                  path: 'books/:id', page: _i4.BookDetailsPage),
              _i1.RouteConfig(SettingsPageRoute.key,
                  path: 'settings', page: _i5.SettingsPage)
            ]),
        _i1.RouteConfig('*#redirect',
            path: '*', redirectTo: '/', fullMatch: true)
      ];
}

class DashboardPageRoute extends _i1.PageRouteInfo {
  DashboardPageRoute({List<_i1.PageRouteInfo> children})
      : super(key, path: '/', children: children);

  static const String key = 'DashboardPageRoute';
}

class BookListPageRoute extends _i1.PageRouteInfo {
  BookListPageRoute() : super(key, path: 'books');

  static const String key = 'BookListPageRoute';
}

class BookDetailsPageRoute extends _i1.PageRouteInfo {
  BookDetailsPageRoute({@_i6.required id})
      : super(key, path: 'books/:id', pathParams: {'id': id});

  static const String key = 'BookDetailsPageRoute';
}

class SettingsPageRoute extends _i1.PageRouteInfo {
  SettingsPageRoute() : super(key, path: 'settings');

  static const String key = 'SettingsPageRoute';
}

class BookDetailsPageArgs extends _i1.RouteArgs {
  BookDetailsPageArgs() : super([]);
}
