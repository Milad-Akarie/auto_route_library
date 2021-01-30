// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i1;
import 'package:flutter/material.dart' as _i9;

import '../screens/books/book_details_page.dart' as _i6;
import '../screens/books/book_list_page.dart' as _i5;
import '../screens/home_page.dart' as _i2;
import '../screens/login_page.dart' as _i3;
import '../screens/profile/my_books_page.dart' as _i8;
import '../screens/profile/profile_page.dart' as _i7;
import '../screens/settings.dart' as _i4;

class AppRouter extends _i1.RootStackRouter {
  AppRouter();

  @override
  final Map<String, _i1.PageFactory> pagesMap = {
    HomeRoute.name: (entry) {
      return _i1.MaterialPageX(entry: entry, child: _i2.HomePage());
    },
    LoginRoute.name: (entry) {
      var route = entry.routeData.as<LoginRoute>();
      return _i1.MaterialPageX(
          entry: entry,
          child: _i3.LoginPage(
              key: route.key,
              onLoginResult: route.onLoginResult,
              showBackButton: route.showBackButton ?? true),
          fullscreenDialog: false);
    },
    BooksTab.name: (entry) {
      return _i1.MaterialPageX(
          entry: entry, child: const _i1.EmptyRouterPage());
    },
    ProfileTab.name: (entry) {
      return _i1.MaterialPageX(
          entry: entry, child: const _i1.EmptyRouterPage());
    },
    SettingsTab.name: (entry) {
      return _i1.MaterialPageX(entry: entry, child: _i4.SettingsPage());
    },
    BookListRoute.name: (entry) {
      var route = entry.routeData.as<BookListRoute>();
      return _i1.MaterialPageX(entry: entry, child: _i5.BookListPage(route.id));
    },
    BookDetailsRoute.name: (entry) {
      var route = entry.routeData.as<BookDetailsRoute>();
      return _i1.MaterialPageX(
          entry: entry, child: _i6.BookDetailsPage(id: route.id ?? 1));
    },
    ProfileRoute.name: (entry) {
      return _i1.MaterialPageX(entry: entry, child: _i7.ProfilePage());
    },
    MyBooksRoute.name: (entry) {
      var route = entry.routeData.as<MyBooksRoute>();
      return _i1.MaterialPageX(
          entry: entry,
          child:
              _i8.MyBooksPage(key: route.key, filter: route.filter ?? 'none'));
    }
  };

  @override
  List<_i1.RouteConfig> get routes => [
        _i1.RouteConfig<HomeRoute>(HomeRoute.name,
            path: '/',
            usesTabsRouter: true,
            routeBuilder: (match) => HomeRoute.fromMatch(match),
            children: [
              _i1.RouteConfig('#redirect',
                  path: '', redirectTo: 'books', fullMatch: true),
              _i1.RouteConfig<BooksTab>(BooksTab.name,
                  path: 'books',
                  routeBuilder: (match) => BooksTab.fromMatch(match),
                  children: [
                    _i1.RouteConfig<BookListRoute>(BookListRoute.name,
                        path: '',
                        routeBuilder: (match) =>
                            BookListRoute.fromMatch(match)),
                    _i1.RouteConfig<BookDetailsRoute>(BookDetailsRoute.name,
                        path: ':id',
                        routeBuilder: (match) =>
                            BookDetailsRoute.fromMatch(match))
                  ]),
              _i1.RouteConfig<ProfileTab>(ProfileTab.name,
                  path: 'profile',
                  routeBuilder: (match) => ProfileTab.fromMatch(match),
                  children: [
                    _i1.RouteConfig<ProfileRoute>(ProfileRoute.name,
                        path: '',
                        routeBuilder: (match) => ProfileRoute.fromMatch(match)),
                    _i1.RouteConfig<MyBooksRoute>(MyBooksRoute.name,
                        path: 'books',
                        routeBuilder: (match) => MyBooksRoute.fromMatch(match))
                  ]),
              _i1.RouteConfig<SettingsTab>(SettingsTab.name,
                  path: 'settings',
                  routeBuilder: (match) => SettingsTab.fromMatch(match))
            ]),
        _i1.RouteConfig<LoginRoute>(LoginRoute.name,
            path: '/login',
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

class LoginRoute extends _i1.PageRouteInfo {
  LoginRoute({this.key, this.onLoginResult, this.showBackButton = true})
      : super(name, path: '/login');

  LoginRoute.fromMatch(_i1.RouteMatch match)
      : key = null,
        onLoginResult = null,
        showBackButton = null,
        super.fromMatch(match);

  final _i9.Key key;

  final void Function(bool) onLoginResult;

  final bool showBackButton;

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

  SettingsTab.fromMatch(_i1.RouteMatch match) : super.fromMatch(match);

  static const String name = 'SettingsTab';
}

class BookListRoute extends _i1.PageRouteInfo {
  BookListRoute({this.id}) : super(name, path: '');

  BookListRoute.fromMatch(_i1.RouteMatch match)
      : id = null,
        super.fromMatch(match);

  final String id;

  static const String name = 'BookListRoute';
}

class BookDetailsRoute extends _i1.PageRouteInfo {
  BookDetailsRoute({this.id = 1})
      : super(name, path: ':id', params: {'id': id});

  BookDetailsRoute.fromMatch(_i1.RouteMatch match)
      : id = match.pathParams.getInt('id', 1),
        super.fromMatch(match);

  final int id;

  static const String name = 'BookDetailsRoute';
}

class ProfileRoute extends _i1.PageRouteInfo {
  const ProfileRoute() : super(name, path: '');

  ProfileRoute.fromMatch(_i1.RouteMatch match) : super.fromMatch(match);

  static const String name = 'ProfileRoute';
}

class MyBooksRoute extends _i1.PageRouteInfo {
  MyBooksRoute({this.key, this.filter = 'none'})
      : super(name, path: 'books', queryParams: {'filter': filter});

  MyBooksRoute.fromMatch(_i1.RouteMatch match)
      : key = null,
        filter = match.queryParams.getString('filter', 'none'),
        super.fromMatch(match);

  final _i9.Key key;

  final String filter;

  static const String name = 'MyBooksRoute';
}
