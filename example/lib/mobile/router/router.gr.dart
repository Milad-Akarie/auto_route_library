// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i1;
import 'package:flutter/material.dart' as _i2;
import 'auth_guard.dart' as _i3;
import '../screens/home_page.dart' as _i4;
import '../screens/book_list_page.dart' as _i5;
import '../screens/book_details_page.dart' as _i6;
import '../screens/login_page.dart' as _i7;

class MyRouterConfig extends _i1.AutoRouterConfig {
  MyRouterConfig({@_i2.required this.authGuard}) : assert(authGuard != null);

  final _i3.AuthGuard authGuard;

  @override
  final Map<Type, _i1.PageFactory> pagesMap = {
    _i4.HomePage: (data) {
      return _i1.MaterialPageX(data: data, child: _i4.HomePage());
    },
    _i5.BookListPage: (data) {
      return _i1.MaterialPageX(data: data, child: _i5.BookListPage());
    },
    _i6.BookDetailsPage: (data) {
      return _i1.MaterialPageX(
          data: data,
          child: _i6.BookDetailsPage(bookId: data.pathParams.getInt('id')));
    },
    _i7.LoginPage: (data) {
      var args = data.getArgs<LoginPageArgs>(orElse: () => LoginPageArgs());
      return _i1.MaterialPageX(
          data: data,
          child: _i7.LoginPage(key: args.key, onResult: args.onResult));
    }
  };

  @override
  List<_i1.RouteConfig> get routes => [
        _i1.RouteConfig(HomePageRoute.key, path: '/', page: _i4.HomePage),
        _i1.RouteConfig(BookListPageRoute.key,
            path: '/book-list-page', page: _i5.BookListPage),
        _i1.RouteConfig(BookDetailsPageRoute.key,
            path: '/books/:id', page: _i6.BookDetailsPage, guards: [authGuard]),
        _i1.RouteConfig(LoginPageRoute.key,
            path: '/login', page: _i7.LoginPage),
        _i1.RouteConfig('*#redirect',
            path: '*', redirectTo: '/', fullMatch: true)
      ];
}

class HomePageRoute extends _i1.PageRouteInfo {
  HomePageRoute() : super(key, path: '/');

  static const String key = 'HomePageRoute';
}

class BookListPageRoute extends _i1.PageRouteInfo {
  BookListPageRoute() : super(key, path: '/book-list-page');

  static const String key = 'BookListPageRoute';
}

class BookDetailsPageRoute extends _i1.PageRouteInfo {
  BookDetailsPageRoute({@_i2.required id})
      : super(key, path: '/books/:id', pathParams: {'id': id});

  static const String key = 'BookDetailsPageRoute';
}

class LoginPageRoute extends _i1.PageRouteInfo {
  LoginPageRoute({_i2.Key key0, void Function(bool) onResult})
      : super(key,
            path: '/login', args: LoginPageArgs(key: key0, onResult: onResult));

  static const String key = 'LoginPageRoute';
}

class BookDetailsPageArgs extends _i1.RouteArgs {
  BookDetailsPageArgs() : super([]);
}

class LoginPageArgs extends _i1.RouteArgs {
  LoginPageArgs({this.key, this.onResult}) : super([key, onResult]);

  final _i2.Key key;

  final void Function(bool) onResult;
}
