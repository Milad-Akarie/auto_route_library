// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i1;
import 'package:flutter/material.dart' as _i2;
import 'auth_guard.dart' as _i3;
import '../screens/home_page.dart' as _i4;
import '../screens/user-data/data_collector.dart' as _i5;
import '../screens/login_page.dart' as _i6;
import '../screens/settings.dart' as _i7;
import '../screens/books/book_list_page.dart' as _i8;
import '../screens/books/book_details_page.dart' as _i9;
import '../screens/profile/profile_page.dart' as _i10;
import '../screens/profile/my_books_page.dart' as _i11;
import '../screens/user-data/sinlge_field_page.dart' as _i12;
import '../screens/user-data/user_data_page.dart' as _i13;

class BookAppRouter extends _i1.AutoRouterConfig {
  BookAppRouter(
      {@_i2.required this.authGuard,
      String initialDeepLink,
      List<_i1.PageRouteInfo> initialRoutes})
      : assert(authGuard != null),
        super(initialDeepLink: initialDeepLink, initialRoutes: initialRoutes);

  final _i3.AuthGuard authGuard;

  @override
  final Map<Type, _i1.PageFactory> pagesMap = {
    _i4.HomePage: (args) {
      return _i1.MaterialPageX(data: args, child: _i4.HomePage());
    },
    _i5.UserDataCollectorPage: (args) {
      var data = args.as<UserDataCollectorRoute>();
      return _i1.MaterialPageX(
          data: args,
          child: _i5.UserDataCollectorPage(
              key: data.key, onResult: data.onResult));
    },
    _i6.LoginPage: (args) {
      var data = args.as<LoginRoute>();
      return _i1.MaterialPageX(
          data: args,
          child:
              _i6.LoginPage(key: data.key, onLoginResult: data.onLoginResult),
          fullscreenDialog: true);
    },
    _i1.EmptyRouterPage: (args) {
      return _i1.MaterialPageX(data: args, child: const _i1.EmptyRouterPage());
    },
    _i7.SettingsPage: (args) {
      return _i1.MaterialPageX(data: args, child: _i7.SettingsPage());
    },
    _i8.BookListPage: (args) {
      return _i1.MaterialPageX(data: args, child: _i8.BookListPage());
    },
    _i9.BookDetailsPage: (args) {
      var data = args.as<BookDetailsRoute>();
      return _i1.MaterialPageX(
          data: args,
          child: _i9.BookDetailsPage(
              id: data.id ?? 1, queryFilter: data.queryFilter),
          fullscreenDialog: true);
    },
    _i10.ProfilePage: (args) {
      return _i1.MaterialPageX(data: args, child: _i10.ProfilePage());
    },
    _i11.MyBooksPage: (args) {
      var data = args.as<MyBooksRoute>();
      return _i1.MaterialPageX(
          data: args,
          child:
              _i11.MyBooksPage(key: data.key, filter: data.filter ?? 'none'));
    },
    _i12.SingleFieldPage: (args) {
      var data = args.as<SingleFieldRoute>();
      return _i1.CustomPage(
          data: args,
          child: _i12.SingleFieldPage(
              key: data.key,
              message: data.message,
              willPopMessage: data.willPopMessage,
              onNext: data.onNext),
          transitionsBuilder: _i1.TransitionsBuilders.slideRightWithFade);
    },
    _i13.UserDataPage: (args) {
      var data = args.as<UserDataRoute>();
      return _i1.CustomPage(
          data: args,
          child: _i13.UserDataPage(key: data.key, onResult: data.onResult),
          transitionsBuilder: _i1.TransitionsBuilders.slideRightWithFade);
    }
  };

  @override
  List<_i1.RouteConfig> get routes => [
        _i1.RouteConfig<HomeRoute>(HomeRoute.name,
            path: '/',
            page: _i4.HomePage,
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
                        page: _i8.BookListPage,
                        routeBuilder: (_) => const BookListRoute()),
                    _i1.RouteConfig<BookDetailsRoute>(BookDetailsRoute.name,
                        path: 'list/:id',
                        page: _i9.BookDetailsPage,
                        routeBuilder: (match) =>
                            BookDetailsRoute.fromMatch(match),
                        guards: [authGuard])
                  ]),
              _i1.RouteConfig<ProfileTab>(ProfileTab.name,
                  path: 'profile',
                  page: _i1.EmptyRouterPage,
                  routeBuilder: (match) => ProfileTab.fromMatch(match),
                  children: [
                    _i1.RouteConfig('#redirect',
                        path: '', redirectTo: 'me', fullMatch: true),
                    _i1.RouteConfig<ProfileRoute>(ProfileRoute.name,
                        path: 'me',
                        page: _i10.ProfilePage,
                        routeBuilder: (_) => const ProfileRoute()),
                    _i1.RouteConfig<MyBooksRoute>(MyBooksRoute.name,
                        path: 'me/books',
                        page: _i11.MyBooksPage,
                        routeBuilder: (match) => MyBooksRoute.fromMatch(match))
                  ]),
              _i1.RouteConfig<SettingsTab>(SettingsTab.name,
                  path: 'settings',
                  page: _i7.SettingsPage,
                  routeBuilder: (_) => const SettingsTab())
            ]),
        _i1.RouteConfig<UserDataCollectorRoute>(UserDataCollectorRoute.name,
            path: '/user-data',
            page: _i5.UserDataCollectorPage,
            routeBuilder: (match) => UserDataCollectorRoute.fromMatch(match),
            children: [
              _i1.RouteConfig<SingleFieldRoute>(SingleFieldRoute.name,
                  path: 'single-field-page',
                  page: _i12.SingleFieldPage,
                  routeBuilder: (match) => SingleFieldRoute.fromMatch(match)),
              _i1.RouteConfig<UserDataRoute>(UserDataRoute.name,
                  path: 'user-data-page',
                  page: _i13.UserDataPage,
                  routeBuilder: (match) => UserDataRoute.fromMatch(match))
            ]),
        _i1.RouteConfig<LoginRoute>(LoginRoute.name,
            path: '/login',
            page: _i6.LoginPage,
            routeBuilder: (match) => LoginRoute.fromMatch(match)),
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

class UserDataCollectorRoute extends _i1.PageRouteInfo {
  UserDataCollectorRoute(
      {this.key, this.onResult, List<_i1.PageRouteInfo> children})
      : super(name,
            path: '/user-data',
            argProps: [key, onResult],
            initialChildren: children);

  UserDataCollectorRoute.fromMatch(_i1.RouteMatch match)
      : key = null,
        onResult = null,
        super.fromMatch(match);

  final _i2.Key key;

  final dynamic Function(_i5.UserData) onResult;

  static const String name = 'UserDataCollectorRoute';
}

class LoginRoute extends _i1.PageRouteInfo {
  LoginRoute({this.key, this.onLoginResult})
      : super(name, path: '/login', argProps: [key, onLoginResult]);

  LoginRoute.fromMatch(_i1.RouteMatch match)
      : key = null,
        onLoginResult = null,
        super.fromMatch(match);

  final _i2.Key key;

  final void Function(bool) onLoginResult;

  static const String name = 'LoginRoute';
}

class BooksTab extends _i1.PageRouteInfo {
  const BooksTab({List<_i1.PageRouteInfo> children})
      : super(name, path: 'books', initialChildren: children);

  BooksTab.fromMatch(_i1.RouteMatch match) : super.fromMatch(match);

  static const String name = 'BooksTab';
}

class ProfileTab extends _i1.PageRouteInfo {
  const ProfileTab({List<_i1.PageRouteInfo> children})
      : super(name, path: 'profile', initialChildren: children);

  ProfileTab.fromMatch(_i1.RouteMatch match) : super.fromMatch(match);

  static const String name = 'ProfileTab';
}

class SettingsTab extends _i1.PageRouteInfo {
  const SettingsTab() : super(name, path: 'settings');

  static const String name = 'SettingsTab';
}

class BookListRoute extends _i1.PageRouteInfo {
  const BookListRoute() : super(name, path: 'list');

  static const String name = 'BookListRoute';
}

class BookDetailsRoute extends _i1.PageRouteInfo {
  BookDetailsRoute({this.id = 1, this.queryFilter})
      : super(name,
            path: 'list/:id', params: {'id': id}, argProps: [id, queryFilter]);

  BookDetailsRoute.fromMatch(_i1.RouteMatch match)
      : id = match.pathParams.getInt('id', 1),
        queryFilter = match.queryParams.getString('queryFilter'),
        super.fromMatch(match);

  final int id;

  final String queryFilter;

  static const String name = 'BookDetailsRoute';
}

class ProfileRoute extends _i1.PageRouteInfo {
  const ProfileRoute() : super(name, path: 'me');

  static const String name = 'ProfileRoute';
}

class MyBooksRoute extends _i1.PageRouteInfo {
  MyBooksRoute({this.key, this.filter = 'none'})
      : super(name, path: 'me/books', argProps: [key, filter]);

  MyBooksRoute.fromMatch(_i1.RouteMatch match)
      : key = null,
        filter = match.queryParams.getString('filter', 'none'),
        super.fromMatch(match);

  final _i2.Key key;

  final String filter;

  static const String name = 'MyBooksRoute';
}

class SingleFieldRoute extends _i1.PageRouteInfo {
  SingleFieldRoute(
      {this.key,
      @_i2.required this.message,
      @_i2.required this.willPopMessage,
      @_i2.required this.onNext})
      : super(name,
            path: 'single-field-page',
            argProps: [key, message, willPopMessage, onNext]);

  SingleFieldRoute.fromMatch(_i1.RouteMatch match)
      : key = null,
        message = null,
        willPopMessage = null,
        onNext = null,
        super.fromMatch(match);

  final _i2.Key key;

  final String message;

  final String willPopMessage;

  final void Function(String) onNext;

  static const String name = 'SingleFieldRoute';
}

class UserDataRoute extends _i1.PageRouteInfo {
  UserDataRoute({this.key, this.onResult})
      : super(name, path: 'user-data-page', argProps: [key, onResult]);

  UserDataRoute.fromMatch(_i1.RouteMatch match)
      : key = null,
        onResult = null,
        super.fromMatch(match);

  final _i2.Key key;

  final dynamic Function(_i5.UserData) onResult;

  static const String name = 'UserDataRoute';
}
