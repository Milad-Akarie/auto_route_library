// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i1;
import 'package:flutter/material.dart' as _i12;

import '../screens/books/book_details_page.dart' as _i7;
import '../screens/books/book_list_page.dart' as _i6;
import '../screens/home_page.dart' as _i2;
import '../screens/login_page.dart' as _i4;
import '../screens/profile/my_books_page.dart' as _i9;
import '../screens/profile/profile_page.dart' as _i8;
import '../screens/settings.dart' as _i5;
import '../screens/user-data/data_collector.dart' as _i3;
import '../screens/user-data/sinlge_field_page.dart' as _i10;
import '../screens/user-data/user_data_page.dart' as _i11;

class AppRouter extends _i1.RootStackRouter {
  AppRouter();

  @override
  final Map<String, _i1.PageFactory> pagesMap = {
    HomeRoute.name: (entry) {
      return _i1.MaterialPageX(
          entry: entry,
          child: _i2.HomePage(),
          maintainState: true,
          fullscreenDialog: false);
    },
    UserDataCollectorRoute.name: (entry) {
      var route = entry.routeData.as<UserDataCollectorRoute>();
      return _i1.MaterialPageX(
          entry: entry,
          child: _i3.UserDataCollectorPage(
              key: route.key, onResult: route.onResult, id: route.id),
          maintainState: true,
          fullscreenDialog: false);
    },
    LoginRoute.name: (entry) {
      var route = entry.routeData.as<LoginRoute>();
      return _i1.MaterialPageX(
          entry: entry,
          child: _i4.LoginPage(
              key: route.key,
              onLoginResult: route.onLoginResult,
              showBackButton: route.showBackButton),
          maintainState: true,
          fullscreenDialog: false);
    },
    BooksTab.name: (entry) {
      return _i1.MaterialPageX(
          entry: entry,
          child: const _i1.EmptyRouterPage(),
          maintainState: true,
          fullscreenDialog: false);
    },
    ProfileTab.name: (entry) {
      return _i1.MaterialPageX(
          entry: entry,
          child: const _i1.EmptyRouterPage(),
          maintainState: true,
          fullscreenDialog: false);
    },
    SettingsTab.name: (entry) {
      return _i1.MaterialPageX(
          entry: entry,
          child: _i5.SettingsPage(),
          maintainState: true,
          fullscreenDialog: false);
    },
    BookListRoute.name: (entry) {
      var route = entry.routeData.as<BookListRoute>();
      return _i1.MaterialPageX(
          entry: entry,
          child: _i6.BookListPage(route.id),
          maintainState: true,
          fullscreenDialog: false);
    },
    BookDetailsRoute.name: (entry) {
      var route = entry.routeData.as<BookDetailsRoute>();
      return _i1.MaterialPageX(
          entry: entry,
          child: _i7.BookDetailsPage(id: route.id),
          maintainState: true,
          fullscreenDialog: false);
    },
    ProfileRoute.name: (entry) {
      return _i1.MaterialPageX(
          entry: entry,
          child: _i8.ProfilePage(),
          maintainState: true,
          fullscreenDialog: false);
    },
    MyBooksRoute.name: (entry) {
      var route = entry.routeData.as<MyBooksRoute>();
      return _i1.MaterialPageX(
          entry: entry,
          child: _i9.MyBooksPage(key: route.key, filter: route.filter),
          maintainState: true,
          fullscreenDialog: false);
    },
    SingleFieldRoute.name: (entry) {
      var route = entry.routeData.as<SingleFieldRoute>();
      return _i1.CustomPage(
          entry: entry,
          child: _i10.SingleFieldPage(
              key: route.key,
              message: route.message,
              willPopMessage: route.willPopMessage,
              onNext: route.onNext),
          maintainState: true,
          fullscreenDialog: false,
          transitionsBuilder: _i1.TransitionsBuilders.slideRightWithFade,
          opaque: true,
          barrierDismissible: false);
    },
    UserDataRoute.name: (entry) {
      var route = entry.routeData.as<UserDataRoute>();
      return _i1.CustomPage(
          entry: entry,
          child: _i11.UserDataPage(key: route.key, onResult: route.onResult),
          maintainState: true,
          fullscreenDialog: false,
          transitionsBuilder: _i1.TransitionsBuilders.slideRightWithFade,
          opaque: true,
          barrierDismissible: false);
    }
  };

  @override
  List<_i1.RouteConfig> get routes => [
        _i1.RouteConfig<HomeRoute>(HomeRoute.name,
            path: '/',
            fullMatch: false,
            usesTabsRouter: true,
            routeBuilder: (match) => HomeRoute.fromMatch(match),
            children: [
              _i1.RouteConfig('#redirect',
                  path: '', redirectTo: 'books', fullMatch: true),
              _i1.RouteConfig<BooksTab>(BooksTab.name,
                  path: 'books',
                  fullMatch: false,
                  usesTabsRouter: false,
                  routeBuilder: (match) => BooksTab.fromMatch(match),
                  children: [
                    _i1.RouteConfig<BookListRoute>(BookListRoute.name,
                        path: '',
                        fullMatch: false,
                        usesTabsRouter: false,
                        routeBuilder: (match) =>
                            BookListRoute.fromMatch(match)),
                    _i1.RouteConfig<BookDetailsRoute>(BookDetailsRoute.name,
                        path: ':id',
                        fullMatch: false,
                        usesTabsRouter: false,
                        routeBuilder: (match) =>
                            BookDetailsRoute.fromMatch(match))
                  ]),
              _i1.RouteConfig<ProfileTab>(ProfileTab.name,
                  path: 'profile',
                  fullMatch: false,
                  usesTabsRouter: false,
                  routeBuilder: (match) => ProfileTab.fromMatch(match),
                  children: [
                    _i1.RouteConfig<ProfileRoute>(ProfileRoute.name,
                        path: '',
                        fullMatch: false,
                        usesTabsRouter: false,
                        routeBuilder: (match) => ProfileRoute.fromMatch(match)),
                    _i1.RouteConfig<MyBooksRoute>(MyBooksRoute.name,
                        path: 'books',
                        fullMatch: false,
                        usesTabsRouter: false,
                        routeBuilder: (match) => MyBooksRoute.fromMatch(match))
                  ]),
              _i1.RouteConfig<SettingsTab>(SettingsTab.name,
                  path: 'settings',
                  fullMatch: false,
                  usesTabsRouter: false,
                  routeBuilder: (match) => SettingsTab.fromMatch(match))
            ]),
        _i1.RouteConfig<UserDataCollectorRoute>(UserDataCollectorRoute.name,
            path: '/user-data/:id',
            fullMatch: false,
            usesTabsRouter: false,
            routeBuilder: (match) => UserDataCollectorRoute.fromMatch(match),
            children: [
              _i1.RouteConfig<SingleFieldRoute>(SingleFieldRoute.name,
                  path: 'single-field-page',
                  fullMatch: false,
                  usesTabsRouter: false,
                  routeBuilder: (match) => SingleFieldRoute.fromMatch(match)),
              _i1.RouteConfig<UserDataRoute>(UserDataRoute.name,
                  path: 'user-data-page',
                  fullMatch: false,
                  usesTabsRouter: false,
                  routeBuilder: (match) => UserDataRoute.fromMatch(match))
            ]),
        _i1.RouteConfig<LoginRoute>(LoginRoute.name,
            path: '/login',
            fullMatch: false,
            usesTabsRouter: false,
            routeBuilder: (match) => LoginRoute.fromMatch(match)),
        _i1.RouteConfig('*#redirect',
            path: '*', redirectTo: '/', fullMatch: true)
      ];
}

class HomeRoute extends _i1.PageRouteInfo {
  const HomeRoute({List<_i1.PageRouteInfo>? children})
      : super(name, path: '/', initialChildren: children);

  HomeRoute.fromMatch(_i1.RouteMatch match) : super.fromMatch(match);

  static const String name = 'HomeRoute';
}

class UserDataCollectorRoute extends _i1.PageRouteInfo {
  UserDataCollectorRoute(
      {this.key, this.onResult, this.id, List<_i1.PageRouteInfo>? children})
      : super(name, path: '/user-data/:id', initialChildren: children);

  UserDataCollectorRoute.fromMatch(_i1.RouteMatch match)
      : key = null,
        onResult = null,
        id = match.pathParams.getIntOrNull('id'),
        super.fromMatch(match);

  final _i12.Key? key;

  final dynamic Function(_i3.UserData)? onResult;

  final int? id;

  static const String name = 'UserDataCollectorRoute';
}

class LoginRoute extends _i1.PageRouteInfo {
  LoginRoute({this.key, this.onLoginResult, this.showBackButton = true})
      : super(name, path: '/login');

  LoginRoute.fromMatch(_i1.RouteMatch match)
      : key = null,
        onLoginResult = null,
        showBackButton = true,
        super.fromMatch(match);

  final _i12.Key? key;

  final void Function(bool)? onLoginResult;

  final bool showBackButton;

  static const String name = 'LoginRoute';
}

class BooksTab extends _i1.PageRouteInfo {
  const BooksTab({List<_i1.PageRouteInfo>? children})
      : super(name, path: 'books', initialChildren: children);

  BooksTab.fromMatch(_i1.RouteMatch match) : super.fromMatch(match);

  static const String name = 'BooksTab';
}

class ProfileTab extends _i1.PageRouteInfo {
  const ProfileTab({List<_i1.PageRouteInfo>? children})
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
  BookDetailsRoute({this.id = 1}) : super(name, path: ':id');

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

  final _i12.Key? key;

  final String filter;

  static const String name = 'MyBooksRoute';
}

class SingleFieldRoute extends _i1.PageRouteInfo {
  SingleFieldRoute(
      {this.key,
      required this.message,
      required this.willPopMessage,
      required this.onNext})
      : super(name, path: 'single-field-page');

  SingleFieldRoute.fromMatch(_i1.RouteMatch match)
      : key = null,
        message = null,
        willPopMessage = null,
        onNext = null,
        super.fromMatch(match);

  final _i12.Key? key;

  final String message;

  final String willPopMessage;

  final void Function(String) onNext;

  static const String name = 'SingleFieldRoute';
}

class UserDataRoute extends _i1.PageRouteInfo {
  UserDataRoute({this.key, this.onResult})
      : super(name, path: 'user-data-page');

  UserDataRoute.fromMatch(_i1.RouteMatch match)
      : key = null,
        onResult = null,
        super.fromMatch(match);

  final _i12.Key? key;

  final dynamic Function(_i3.UserData)? onResult;

  static const String name = 'UserDataRoute';
}
