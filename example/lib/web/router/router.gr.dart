// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i1;
import 'package:flutter/material.dart' as _i6;

import '../screens/book_details_page.dart' as _i5;
import '../screens/book_list_page.dart' as _i3;
import '../screens/dashboard_page.dart' as _i2;
import '../screens/settings_page.dart' as _i4;

class WebRouterConfig extends _i1.AutoRouterConfig {
  WebRouterConfig();

  @override
  final Map<Type, _i1.PageFactory> pagesMap = {
    _i2.DashboardPage: (data) {
      return _i1.MaterialPageX(data: data, child: _i2.DashboardPage());
    },
    _i3.BookListPage: (data) {
      return _i1.MaterialPageX(data: data, child: _i3.BookListPage());
    },
    _i4.SettingsPage: (data) {
      return _i1.MaterialPageX(data: data, child: _i4.SettingsPage());
    },
    _i5.BookDetailsPage: (data) {
      return _i1.MaterialPageX(data: data, child: _i5.BookDetailsPage(bookId: data.pathParams.getInt('id')));
    }
  };

  @override
  List<_i1.RouteConfig> get routes => [
        _i1.RouteConfig(DashboardPageRoute.key, path: '/', page: _i2.DashboardPage, children: [
          _i1.RouteConfig('#redirect', path: '', redirectTo: 'books', fullMatch: true),
          _i1.RouteConfig(BookListPageRoute.key, path: 'books', page: _i3.BookListPage, children: [
            _i1.RouteConfig('#redirect', path: '', redirectTo: '1', fullMatch: true),
            _i1.RouteConfig(BookDetailsPageRoute.key, path: ':id', page: _i5.BookDetailsPage)
          ]),
          _i1.RouteConfig(SettingsPageRoute.key, path: 'settings', page: _i4.SettingsPage)
        ]),
        _i1.RouteConfig('*#redirect', path: '*', redirectTo: '/', fullMatch: true)
      ];
}

class DashboardPageRoute extends _i1.PageRouteInfo {
  DashboardPageRoute({List<_i1.PageRouteInfo> children}) : super(key, path: '/', children: children);

  static const String key = 'DashboardPageRoute';
}

class BookListPageRoute extends _i1.PageRouteInfo {
  BookListPageRoute({List<_i1.PageRouteInfo> children}) : super(key, path: 'books', children: children);

  static const String key = 'BookListPageRoute';
}

class SettingsPageRoute extends _i1.PageRouteInfo {
  SettingsPageRoute() : super(key, path: 'settings');

  static const String key = 'SettingsPageRoute';
}

class BookDetailsPageRoute extends _i1.PageRouteInfo {
  BookDetailsPageRoute({@_i6.required id}) : super(key, path: ':id', pathParams: {'id': id});

  static const String key = 'BookDetailsPageRoute';
}

class BookDetailsPageArgs extends _i1.RouteArgs {
  BookDetailsPageArgs() : super([]);
}
