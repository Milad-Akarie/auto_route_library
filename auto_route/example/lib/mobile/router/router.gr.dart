// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i4;
import 'package:flutter/cupertino.dart' as _i14;
import 'package:flutter/material.dart' as _i12;

import '../screens/books/book_details_page.dart' as _i7;
import '../screens/books/book_list_page.dart' as _i6;
import '../screens/home_page.dart' as _i1;
import '../screens/login_page.dart' as _i3;
import '../screens/profile/my_books_page.dart' as _i9;
import '../screens/profile/profile_page.dart' as _i8;
import '../screens/settings.dart' as _i5;
import '../screens/user-data/data_collector.dart' as _i2;
import '../screens/user-data/single_field_page.dart' as _i10;
import '../screens/user-data/user_data_page.dart' as _i11;
import 'auth_guard.dart' as _i13;

class RootRouter extends _i4.RootStackRouter {
  RootRouter(
      {_i12.GlobalKey<_i12.NavigatorState>? navigatorKey,
      required this.authGuard})
      : super(navigatorKey);

  final _i13.AuthGuard authGuard;

  @override
  final Map<String, _i4.PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      return _i4.CustomPage<String>(
          routeData: routeData,
          child: const _i1.HomePage(),
          transitionsBuilder: _i4.TransitionsBuilders.fadeIn,
          opaque: true,
          barrierDismissible: false);
    },
    UserDataCollectorRoute.name: (routeData) {
      final args = routeData.argsAs<UserDataCollectorRouteArgs>(
          orElse: () => const UserDataCollectorRouteArgs());
      return _i4.CustomPage<_i2.UserData>(
          routeData: routeData,
          child:
              _i2.UserDataCollectorPage(key: args.key, onResult: args.onResult),
          transitionsBuilder: _i4.TransitionsBuilders.fadeIn,
          opaque: true,
          barrierDismissible: false);
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i4.CustomPage<dynamic>(
          routeData: routeData,
          child: _i3.LoginPage(
              key: args.key,
              onLoginResult: args.onLoginResult,
              showBackButton: args.showBackButton),
          transitionsBuilder: _i4.TransitionsBuilders.fadeIn,
          opaque: true,
          barrierDismissible: false);
    },
    BooksTab.name: (routeData) {
      return _i4.CustomPage<dynamic>(
          routeData: routeData,
          child: const _i4.EmptyRouterPage(),
          transitionsBuilder: _i4.TransitionsBuilders.fadeIn,
          opaque: true,
          barrierDismissible: false);
    },
    ProfileTab.name: (routeData) {
      return _i4.CustomPage<dynamic>(
          routeData: routeData,
          child: const _i4.EmptyRouterPage(),
          transitionsBuilder: _i4.TransitionsBuilders.fadeIn,
          opaque: true,
          barrierDismissible: false);
    },
    SettingsTab.name: (routeData) {
      final pathParams = routeData.pathParams;
      final args = routeData.argsAs<SettingsTabArgs>(
          orElse: () => SettingsTabArgs(tab: pathParams.getString('tab')));
      return _i4.CustomPage<dynamic>(
          routeData: routeData,
          child: _i5.SettingsPage(key: args.key, tab: args.tab),
          transitionsBuilder: _i4.TransitionsBuilders.fadeIn,
          opaque: true,
          barrierDismissible: false);
    },
    BookListRoute.name: (routeData) {
      return _i4.CustomPage<dynamic>(
          routeData: routeData,
          child: _i6.BookListPage(),
          transitionsBuilder: _i4.TransitionsBuilders.fadeIn,
          opaque: true,
          barrierDismissible: false);
    },
    BookDetailsRoute.name: (routeData) {
      final pathParams = routeData.pathParams;
      final args = routeData.argsAs<BookDetailsRouteArgs>(
          orElse: () => BookDetailsRouteArgs(id: pathParams.getInt('id', -1)));
      return _i4.CustomPage<dynamic>(
          routeData: routeData,
          child: _i7.BookDetailsPage(id: args.id),
          transitionsBuilder: _i4.TransitionsBuilders.fadeIn,
          opaque: true,
          barrierDismissible: false);
    },
    ProfileRoute.name: (routeData) {
      return _i4.CustomPage<dynamic>(
          routeData: routeData,
          child: _i8.ProfilePage(),
          transitionsBuilder: _i4.TransitionsBuilders.fadeIn,
          opaque: true,
          barrierDismissible: false);
    },
    MyBooksRoute.name: (routeData) {
      final queryParams = routeData.queryParams;
      final args = routeData.argsAs<MyBooksRouteArgs>(
          orElse: () => MyBooksRouteArgs(
              filter: queryParams.optString('filter', 'none')));
      return _i4.CustomPage<dynamic>(
          routeData: routeData,
          child: _i9.MyBooksPage(key: args.key, filter: args.filter),
          transitionsBuilder: _i4.TransitionsBuilders.fadeIn,
          opaque: true,
          barrierDismissible: false);
    },
    NameFieldRoute.name: (routeData) {
      final args = routeData.argsAs<NameFieldRouteArgs>(
          orElse: () => const NameFieldRouteArgs());
      return _i4.CustomPage<dynamic>(
          routeData: routeData,
          child: _i10.SingleFieldPage(
              key: args.key,
              message: args.message,
              willPopMessage: args.willPopMessage,
              onNext: args.onNext),
          transitionsBuilder: _i4.TransitionsBuilders.fadeIn,
          opaque: true,
          barrierDismissible: false);
    },
    FavoriteBookFieldRoute.name: (routeData) {
      final args = routeData.argsAs<FavoriteBookFieldRouteArgs>(
          orElse: () => const FavoriteBookFieldRouteArgs());
      return _i4.CustomPage<dynamic>(
          routeData: routeData,
          child: _i10.SingleFieldPage(
              key: args.key,
              message: args.message,
              willPopMessage: args.willPopMessage,
              onNext: args.onNext),
          transitionsBuilder: _i4.TransitionsBuilders.fadeIn,
          opaque: true,
          barrierDismissible: false);
    },
    UserDataRoute.name: (routeData) {
      final args = routeData.argsAs<UserDataRouteArgs>(
          orElse: () => const UserDataRouteArgs());
      return _i4.CustomPage<dynamic>(
          routeData: routeData,
          child: _i11.UserDataPage(key: args.key, onResult: args.onResult),
          transitionsBuilder: _i4.TransitionsBuilders.fadeIn,
          opaque: true,
          barrierDismissible: false);
    }
  };

  @override
  List<_i4.RouteConfig> get routes => [
        _i4.RouteConfig(HomeRoute.name, path: '/', guards: [
          authGuard
        ], children: [
          _i4.RouteConfig(BooksTab.name, path: 'books', children: [
            _i4.RouteConfig(BookListRoute.name, path: ''),
            _i4.RouteConfig(BookDetailsRoute.name, path: ':id')
          ]),
          _i4.RouteConfig(ProfileTab.name, path: 'profile', children: [
            _i4.RouteConfig(ProfileRoute.name, path: ''),
            _i4.RouteConfig(MyBooksRoute.name, path: 'my-books')
          ]),
          _i4.RouteConfig(SettingsTab.name, path: 'settings/:tab')
        ]),
        _i4.RouteConfig(UserDataCollectorRoute.name,
            path: '/user-data',
            children: [
              _i4.RouteConfig(NameFieldRoute.name, path: 'name'),
              _i4.RouteConfig(FavoriteBookFieldRoute.name,
                  path: 'favorite-book'),
              _i4.RouteConfig(UserDataRoute.name, path: 'results')
            ]),
        _i4.RouteConfig(LoginRoute.name, path: '/login'),
        _i4.RouteConfig('*#redirect',
            path: '*', redirectTo: '/', fullMatch: true)
      ];
}

/// generated route for [_i1.HomePage]
class HomeRoute extends _i4.PageRouteInfo<void> {
  const HomeRoute({List<_i4.PageRouteInfo>? children})
      : super(name, path: '/', initialChildren: children);

  static const String name = 'HomeRoute';
}

/// generated route for [_i2.UserDataCollectorPage]
class UserDataCollectorRoute
    extends _i4.PageRouteInfo<UserDataCollectorRouteArgs> {
  UserDataCollectorRoute(
      {_i14.Key? key,
      dynamic Function(_i2.UserData)? onResult,
      List<_i4.PageRouteInfo>? children})
      : super(name,
            path: '/user-data',
            args: UserDataCollectorRouteArgs(key: key, onResult: onResult),
            initialChildren: children);

  static const String name = 'UserDataCollectorRoute';
}

class UserDataCollectorRouteArgs {
  const UserDataCollectorRouteArgs({this.key, this.onResult});

  final _i14.Key? key;

  final dynamic Function(_i2.UserData)? onResult;
}

/// generated route for [_i3.LoginPage]
class LoginRoute extends _i4.PageRouteInfo<LoginRouteArgs> {
  LoginRoute(
      {_i14.Key? key,
      void Function(bool)? onLoginResult,
      bool showBackButton = true})
      : super(name,
            path: '/login',
            args: LoginRouteArgs(
                key: key,
                onLoginResult: onLoginResult,
                showBackButton: showBackButton));

  static const String name = 'LoginRoute';
}

class LoginRouteArgs {
  const LoginRouteArgs(
      {this.key, this.onLoginResult, this.showBackButton = true});

  final _i14.Key? key;

  final void Function(bool)? onLoginResult;

  final bool showBackButton;
}

/// generated route for [_i4.EmptyRouterPage]
class BooksTab extends _i4.PageRouteInfo<void> {
  const BooksTab({List<_i4.PageRouteInfo>? children})
      : super(name, path: 'books', initialChildren: children);

  static const String name = 'BooksTab';
}

/// generated route for [_i4.EmptyRouterPage]
class ProfileTab extends _i4.PageRouteInfo<void> {
  const ProfileTab({List<_i4.PageRouteInfo>? children})
      : super(name, path: 'profile', initialChildren: children);

  static const String name = 'ProfileTab';
}

/// generated route for [_i5.SettingsPage]
class SettingsTab extends _i4.PageRouteInfo<SettingsTabArgs> {
  SettingsTab({_i14.Key? key, required String tab})
      : super(name,
            path: 'settings/:tab',
            args: SettingsTabArgs(key: key, tab: tab),
            rawPathParams: {'tab': tab});

  static const String name = 'SettingsTab';
}

class SettingsTabArgs {
  const SettingsTabArgs({this.key, required this.tab});

  final _i14.Key? key;

  final String tab;
}

/// generated route for [_i6.BookListPage]
class BookListRoute extends _i4.PageRouteInfo<void> {
  const BookListRoute() : super(name, path: '');

  static const String name = 'BookListRoute';
}

/// generated route for [_i7.BookDetailsPage]
class BookDetailsRoute extends _i4.PageRouteInfo<BookDetailsRouteArgs> {
  BookDetailsRoute({int id = -1})
      : super(name,
            path: ':id',
            args: BookDetailsRouteArgs(id: id),
            rawPathParams: {'id': id});

  static const String name = 'BookDetailsRoute';
}

class BookDetailsRouteArgs {
  const BookDetailsRouteArgs({this.id = -1});

  final int id;
}

/// generated route for [_i8.ProfilePage]
class ProfileRoute extends _i4.PageRouteInfo<void> {
  const ProfileRoute() : super(name, path: '');

  static const String name = 'ProfileRoute';
}

/// generated route for [_i9.MyBooksPage]
class MyBooksRoute extends _i4.PageRouteInfo<MyBooksRouteArgs> {
  MyBooksRoute({_i14.Key? key, String? filter = 'none'})
      : super(name,
            path: 'my-books',
            args: MyBooksRouteArgs(key: key, filter: filter),
            rawQueryParams: {'filter': filter});

  static const String name = 'MyBooksRoute';
}

class MyBooksRouteArgs {
  const MyBooksRouteArgs({this.key, this.filter = 'none'});

  final _i14.Key? key;

  final String? filter;
}

/// generated route for [_i10.SingleFieldPage]
class NameFieldRoute extends _i4.PageRouteInfo<NameFieldRouteArgs> {
  NameFieldRoute(
      {_i14.Key? key,
      String message = '',
      String willPopMessage = '',
      void Function(String)? onNext})
      : super(name,
            path: 'name',
            args: NameFieldRouteArgs(
                key: key,
                message: message,
                willPopMessage: willPopMessage,
                onNext: onNext));

  static const String name = 'NameFieldRoute';
}

class NameFieldRouteArgs {
  const NameFieldRouteArgs(
      {this.key, this.message = '', this.willPopMessage = '', this.onNext});

  final _i14.Key? key;

  final String message;

  final String willPopMessage;

  final void Function(String)? onNext;
}

/// generated route for [_i10.SingleFieldPage]
class FavoriteBookFieldRoute
    extends _i4.PageRouteInfo<FavoriteBookFieldRouteArgs> {
  FavoriteBookFieldRoute(
      {_i14.Key? key,
      String message = '',
      String willPopMessage = '',
      void Function(String)? onNext})
      : super(name,
            path: 'favorite-book',
            args: FavoriteBookFieldRouteArgs(
                key: key,
                message: message,
                willPopMessage: willPopMessage,
                onNext: onNext));

  static const String name = 'FavoriteBookFieldRoute';
}

class FavoriteBookFieldRouteArgs {
  const FavoriteBookFieldRouteArgs(
      {this.key, this.message = '', this.willPopMessage = '', this.onNext});

  final _i14.Key? key;

  final String message;

  final String willPopMessage;

  final void Function(String)? onNext;
}

/// generated route for [_i11.UserDataPage]
class UserDataRoute extends _i4.PageRouteInfo<UserDataRouteArgs> {
  UserDataRoute({_i14.Key? key, dynamic Function(_i2.UserData)? onResult})
      : super(name,
            path: 'results',
            args: UserDataRouteArgs(key: key, onResult: onResult));

  static const String name = 'UserDataRoute';
}

class UserDataRouteArgs {
  const UserDataRouteArgs({this.key, this.onResult});

  final _i14.Key? key;

  final dynamic Function(_i2.UserData)? onResult;
}
