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
    _i2.HomePage: (args) {
      return _i1.MaterialPageX(data: args, child: _i2.HomePage());
    },
    _i1.EmptyRouterPage: (args) {
      return _i1.MaterialPageX(data: args, child: const _i1.EmptyRouterPage());
    },
    _i3.BookListPage: (args) {
      return _i1.MaterialPageX(data: args, child: _i3.BookListPage());
    },
    _i4.BookDetailsPage: (args) {
      var data = args.as<BookDetailsRoute>();
      return _i1.MaterialPageX(
          data: args,
          child:
              _i4.BookDetailsPage(id: data.id, queryFilter: data.queryFilter));
    },
    _i5.SettingsPage: (args) {
      return _i1.MaterialPageX(data: args, child: _i5.SettingsPage());
    }
  };

  @override
  List<_i1.RouteConfig> get routes => [
        _i1.RouteConfig<HomeRoute>(HomeRoute.name,
            path: '/',
            page: _i2.HomePage,
            usesTabsRouter: true,
            routeBuilder: (match) => HomeRoute.fromMatch(match),
            children: [
              _i1.RouteConfig<BooksTab>(BooksTab.name,
                  path: 'books',
                  page: _i1.EmptyRouterPage,
                  routeBuilder: (match) => BooksTab.fromMatch(match),
                  children: [
                    _i1.RouteConfig('#redirect',
                        path: '', redirectTo: 'list', fullMatch: true),
                    _i1.RouteConfig<BookListRoute>(BookListRoute.name,
                        path: 'list',
                        page: _i3.BookListPage,
                        routeBuilder: (_) => const BookListRoute()),
                    _i1.RouteConfig<BookDetailsRoute>(BookDetailsRoute.name,
                        path: 'list/:id',
                        page: _i4.BookDetailsPage,
                        routeBuilder: (match) =>
                            BookDetailsRoute.fromMatch(match))
                  ]),
              _i1.RouteConfig<SettingsTab>(SettingsTab.name,
                  path: 'settings',
                  page: _i1.EmptyRouterPage,
                  routeBuilder: (match) => SettingsTab.fromMatch(match),
                  children: [
                    _i1.RouteConfig<SettingsRoute>(SettingsRoute.name,
                        path: '',
                        page: _i5.SettingsPage,
                        routeBuilder: (_) => const SettingsRoute())
                  ])
            ]),
        _i1.RouteConfig('*#redirect',
            path: '*', redirectTo: '/', fullMatch: true)
      ];
}

class HomeRoute extends _i1.PageRouteInfo {
  const HomeRoute({List<_i1.PageRouteInfo> children})
      : super(name, path: '/', initialChildren: children);

  HomeRoute.fromMatch(_i1.RouteMatch match) : super.fromMatch(match);

  static const String name = 'HomeRoute';
}

class BooksTab extends _i1.PageRouteInfo {
  const BooksTab({List<_i1.PageRouteInfo> children})
      : super(name, path: 'books', initialChildren: children);

  BooksTab.fromMatch(_i1.RouteMatch match) : super.fromMatch(match);

  static const String name = 'BooksTab';
}

class SettingsTab extends _i1.PageRouteInfo {
  const SettingsTab({List<_i1.PageRouteInfo> children})
      : super(name, path: 'settings', initialChildren: children);

  SettingsTab.fromMatch(_i1.RouteMatch match) : super.fromMatch(match);

  static const String name = 'SettingsTab';
}

class BookListRoute extends _i1.PageRouteInfo {
  const BookListRoute() : super(name, path: 'list');

  static const String name = 'BookListRoute';
}

class BookDetailsRoute extends _i1.PageRouteInfo {
  BookDetailsRoute({@_i6.required this.id, this.queryFilter})
      : super(name,
            path: 'list/:id', params: {'id': id}, argProps: [id, queryFilter]);

  BookDetailsRoute.fromMatch(_i1.RouteMatch match)
      : id = match.pathParams.getInt('id'),
        queryFilter = match.queryParams.getString('queryFilter'),
        super.fromMatch(match);

  final int id;

  final String queryFilter;

  static const String name = 'BookDetailsRoute';
}

class SettingsRoute extends _i1.PageRouteInfo {
  const SettingsRoute() : super(name, path: '');

  static const String name = 'SettingsRoute';
}
