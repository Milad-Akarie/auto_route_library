// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i1;
import 'package:flutter/material.dart' as _i6;

import '../screens/book_details_page.dart' as _i4;
import '../screens/book_list_page.dart' as _i3;
import '../screens/dashboard_page.dart' as _i2;
import '../screens/settings_page.dart' as _i5;

class WebRouterConfig extends _i1.AutoRouterConfig {
  WebRouterConfig();

  @override
  final Map<Type, _i1.PageFactory> pagesMap = {
    _i2.DashboardPage: (data) {
      return _i1.MaterialPageX(data: data, child: _i2.DashboardPage());
    },
    _i1.AutoRouter: (data) {
      var args = data.getArgs<AutoRouterArgs>(orElse: () => AutoRouterArgs());
      return _i1.MaterialPageX(
          data: data,
          child: _i1.AutoRouter(
              key1: args.key1, navigatorObservers: args.navigatorObservers ?? const [], builder: args.builder));
    },
    _i3.BookListPage: (data) {
      return _i1.MaterialPageX(data: data, child: _i3.BookListPage());
    },
    _i4.BookDetailsPage: (data) {
      return _i1.MaterialPageX(data: data, child: _i4.BookDetailsPage(bookId: data.pathParams.getInt('id')));
    },
    _i5.SettingsPage: (data) {
      return _i1.MaterialPageX(data: data, child: _i5.SettingsPage());
    }
  };

  @override
  List<_i1.RouteConfig> get routes => [
        _i1.RouteConfig(DashboardPageRoute.key, path: '/', usesTabsRouter: true, page: _i2.DashboardPage, children: [
          _i1.RouteConfig(BooksTabs.key, path: 'books', page: _i1.AutoRouter, children: [
            _i1.RouteConfig(BookListPageRoute.key, path: '', page: _i3.BookListPage),
            _i1.RouteConfig(BookDetailsPageRoute.key, path: ':id', page: _i4.BookDetailsPage)
          ]),
          _i1.RouteConfig(SettingsTab.key,
              path: 'settings',
              page: _i1.AutoRouter,
              children: [_i1.RouteConfig(SettingsPageRoute.key, path: '', page: _i5.SettingsPage)])
        ]),
        _i1.RouteConfig('*#redirect', path: '*', redirectTo: '/', fullMatch: true)
      ];
}

class DashboardPageRoute extends _i1.PageRouteInfo {
  DashboardPageRoute({List<_i1.PageRouteInfo> children}) : super(key, path: '/', children: children);

  static const String key = 'DashboardPageRoute';
}

class BooksTabs extends _i1.PageRouteInfo {
  BooksTabs(
      {_i6.Key key1,
      List<_i6.NavigatorObserver> navigatorObservers = const [],
      _i6.Widget Function(_i6.BuildContext, _i6.Widget) builder,
      List<_i1.PageRouteInfo> children})
      : super(key,
            path: 'books',
            args: AutoRouterArgs(key1: key1, navigatorObservers: navigatorObservers, builder: builder),
            children: children);

  static const String key = 'BooksTabs';
}

class SettingsTab extends _i1.PageRouteInfo {
  SettingsTab(
      {_i6.Key key1,
      List<_i6.NavigatorObserver> navigatorObservers = const [],
      _i6.Widget Function(_i6.BuildContext, _i6.Widget) builder,
      List<_i1.PageRouteInfo> children})
      : super(key,
            path: 'settings',
            args: AutoRouterArgs(key1: key1, navigatorObservers: navigatorObservers, builder: builder),
            children: children);

  static const String key = 'SettingsTab';
}

class BookListPageRoute extends _i1.PageRouteInfo {
  BookListPageRoute() : super(key, path: '');

  static const String key = 'BookListPageRoute';
}

class BookDetailsPageRoute extends _i1.PageRouteInfo {
  BookDetailsPageRoute({@_i6.required id}) : super(key, path: ':id', pathParams: {'id': id});

  static const String key = 'BookDetailsPageRoute';
}

class SettingsPageRoute extends _i1.PageRouteInfo {
  SettingsPageRoute() : super(key, path: '');

  static const String key = 'SettingsPageRoute';
}

class AutoRouterArgs extends _i1.RouteArgs {
  AutoRouterArgs({this.key1, this.navigatorObservers = const [], this.builder})
      : super([key1, navigatorObservers, builder]);

  final _i6.Key key1;

  final List<_i6.NavigatorObserver> navigatorObservers;

  final _i6.Widget Function(_i6.BuildContext, _i6.Widget) builder;
}

class AutoRouterArgs2 extends _i1.RouteArgs {
  AutoRouterArgs2({this.key1, this.navigatorObservers = const [], this.builder})
      : super([key1, navigatorObservers, builder]);

  final _i6.Key key1;

  final List<_i6.NavigatorObserver> navigatorObservers;

  final _i6.Widget Function(_i6.BuildContext, _i6.Widget) builder;
}

class BookDetailsPageArgs extends _i1.RouteArgs {
  BookDetailsPageArgs() : super([]);
}
