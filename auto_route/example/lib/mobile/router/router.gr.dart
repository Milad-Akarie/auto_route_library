// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i1;
import 'package:flutter/foundation.dart' as _i15;
import 'package:flutter/material.dart' as _i2;

import '../../data/db.dart' as _i9;
import '../screens/books/book_details_page.dart' as _i10;
import '../screens/books/book_list_page.dart' as _i8;
import '../screens/home_page.dart' as _i4;
import '../screens/login_page.dart' as _i6;
import '../screens/profile/my_books_page.dart' as _i12;
import '../screens/profile/profile_page.dart' as _i11;
import '../screens/settings.dart' as _i7;
import '../screens/user-data/data_collector.dart' as _i5;
import '../screens/user-data/single_field_page.dart' as _i13;
import '../screens/user-data/user_data_page.dart' as _i14;
import 'auth_guard.dart' as _i3;

class RootRouter extends _i1.RootStackRouter {
  RootRouter(
      {_i2.GlobalKey<_i2.NavigatorState>? navigatorKey,
      required this.authGuard})
      : super(navigatorKey);

  final _i3.AuthGuard authGuard;

  @override
  final Map<String, _i1.PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      return _i1.MaterialPageX<String>(
          routeData: routeData, child: const _i4.HomePage());
    },
    UserDataCollectorRoute.name: (routeData) {
      final args = routeData.argsAs<UserDataCollectorRouteArgs>(
          orElse: () => const UserDataCollectorRouteArgs());
      return _i1.MaterialPageX<_i5.UserData>(
          routeData: routeData,
          child: _i5.UserDataCollectorPage(
              key: args.key, onResult: args.onResult));
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i1.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i6.LoginPage(
              key: args.key,
              onLoginResult: args.onLoginResult,
              showBackButton: args.showBackButton));
    },
    BooksTab.name: (routeData) {
      return _i1.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i1.EmptyRouterPage());
    },
    ProfileTab.name: (routeData) {
      return _i1.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i1.EmptyRouterPage());
    },
    SettingsTab.name: (routeData) {
      final pathParams = routeData.pathParams;
      final args = routeData.argsAs<SettingsTabArgs>(
          orElse: () => SettingsTabArgs(tab: pathParams.getString('tab')));
      return _i1.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i7.SettingsPage(key: args.key, tab: args.tab));
    },
    BookListRoute.name: (routeData) {
      return _i1.MaterialPageX<dynamic>(
          routeData: routeData, child: _i8.BookListPage());
    },
    BookDetailsRoute.name: (routeData) {
      final pathParams = routeData.pathParams;
      final args = routeData.argsAs<BookDetailsRouteArgs>(
          orElse: () => BookDetailsRouteArgs(id: pathParams.getInt('id', -1)));
      return _i1.MaterialPageX<_i9.Book>(
          routeData: routeData, child: _i10.BookDetailsPage(id: args.id));
    },
    ProfileRoute.name: (routeData) {
      return _i1.MaterialPageX<dynamic>(
          routeData: routeData, child: _i11.ProfilePage());
    },
    MyBooksRoute.name: (routeData) {
      final queryParams = routeData.queryParams;
      final args = routeData.argsAs<MyBooksRouteArgs>(
          orElse: () => MyBooksRouteArgs(
              filter: queryParams.optString('filter', 'none')));
      return _i1.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i12.MyBooksPage(key: args.key, filter: args.filter));
    },
    NameFieldRoute.name: (routeData) {
      final args = routeData.argsAs<NameFieldRouteArgs>(
          orElse: () => const NameFieldRouteArgs());
      return _i1.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i13.SingleFieldPage(
              key: args.key,
              message: args.message,
              willPopMessage: args.willPopMessage,
              onNext: args.onNext));
    },
    FavoriteBookFieldRoute.name: (routeData) {
      final args = routeData.argsAs<FavoriteBookFieldRouteArgs>(
          orElse: () => const FavoriteBookFieldRouteArgs());
      return _i1.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i13.SingleFieldPage(
              key: args.key,
              message: args.message,
              willPopMessage: args.willPopMessage,
              onNext: args.onNext));
    },
    UserDataRoute.name: (routeData) {
      final args = routeData.argsAs<UserDataRouteArgs>(
          orElse: () => const UserDataRouteArgs());
      return _i1.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i14.UserDataPage(key: args.key, onResult: args.onResult));
    }
  };

  @override
  List<_i1.RouteConfig> get routes => [
        _i1.RouteConfig(HomeRoute.name, path: '/', children: [
          _i1.RouteConfig(BooksTab.name, path: 'books', children: [
            _i1.RouteConfig(BookListRoute.name, path: ''),
            _i1.RouteConfig(BookDetailsRoute.name,
                path: ':id', usesPathAsKey: true, guards: [authGuard])
          ]),
          _i1.RouteConfig(ProfileTab.name, path: 'profile', children: [
            _i1.RouteConfig(ProfileRoute.name, path: ''),
            _i1.RouteConfig(MyBooksRoute.name, path: 'my-books')
          ]),
          _i1.RouteConfig(SettingsTab.name, path: 'settings/:tab')
        ]),
        _i1.RouteConfig(UserDataCollectorRoute.name,
            path: '/user-data',
            children: [
              _i1.RouteConfig(NameFieldRoute.name, path: 'name'),
              _i1.RouteConfig(FavoriteBookFieldRoute.name,
                  path: 'favorite-book'),
              _i1.RouteConfig(UserDataRoute.name, path: 'results')
            ]),
        _i1.RouteConfig(LoginRoute.name, path: '/login'),
        _i1.RouteConfig('*#redirect',
            path: '*', redirectTo: '/', fullMatch: true)
      ];
}

class HomeRoute extends _i1.PageRouteInfo<void> {
  const HomeRoute({List<_i1.PageRouteInfo>? children})
      : super(name, path: '/', initialChildren: children);

  static const String name = 'HomeRoute';
}

class UserDataCollectorRoute
    extends _i1.PageRouteInfo<UserDataCollectorRouteArgs> {
  UserDataCollectorRoute(
      {_i15.Key? key,
      dynamic Function(_i5.UserData)? onResult,
      List<_i1.PageRouteInfo>? children})
      : super(name,
            path: '/user-data',
            args: UserDataCollectorRouteArgs(key: key, onResult: onResult),
            initialChildren: children);

  static const String name = 'UserDataCollectorRoute';
}

class UserDataCollectorRouteArgs {
  const UserDataCollectorRouteArgs({this.key, this.onResult});

  final _i15.Key? key;

  final dynamic Function(_i5.UserData)? onResult;
}

class LoginRoute extends _i1.PageRouteInfo<LoginRouteArgs> {
  LoginRoute(
      {_i15.Key? key,
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

  final _i15.Key? key;

  final void Function(bool)? onLoginResult;

  final bool showBackButton;
}

class BooksTab extends _i1.PageRouteInfo<void> {
  const BooksTab({List<_i1.PageRouteInfo>? children})
      : super(name, path: 'books', initialChildren: children);

  static const String name = 'BooksTab';
}

class ProfileTab extends _i1.PageRouteInfo<void> {
  const ProfileTab({List<_i1.PageRouteInfo>? children})
      : super(name, path: 'profile', initialChildren: children);

  static const String name = 'ProfileTab';
}

class SettingsTab extends _i1.PageRouteInfo<SettingsTabArgs> {
  SettingsTab({_i15.Key? key, required String tab})
      : super(name,
            path: 'settings/:tab',
            args: SettingsTabArgs(key: key, tab: tab),
            rawPathParams: {'tab': tab});

  static const String name = 'SettingsTab';
}

class SettingsTabArgs {
  const SettingsTabArgs({this.key, required this.tab});

  final _i15.Key? key;

  final String tab;
}

class BookListRoute extends _i1.PageRouteInfo<void> {
  const BookListRoute() : super(name, path: '');

  static const String name = 'BookListRoute';
}

class BookDetailsRoute extends _i1.PageRouteInfo<BookDetailsRouteArgs> {
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

class ProfileRoute extends _i1.PageRouteInfo<void> {
  const ProfileRoute() : super(name, path: '');

  static const String name = 'ProfileRoute';
}

class MyBooksRoute extends _i1.PageRouteInfo<MyBooksRouteArgs> {
  MyBooksRoute({_i15.Key? key, String? filter = 'none'})
      : super(name,
            path: 'my-books',
            args: MyBooksRouteArgs(key: key, filter: filter),
            rawQueryParams: {'filter': filter});

  static const String name = 'MyBooksRoute';
}

class MyBooksRouteArgs {
  const MyBooksRouteArgs({this.key, this.filter = 'none'});

  final _i15.Key? key;

  final String? filter;
}

class NameFieldRoute extends _i1.PageRouteInfo<NameFieldRouteArgs> {
  NameFieldRoute(
      {_i15.Key? key,
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

  final _i15.Key? key;

  final String message;

  final String willPopMessage;

  final void Function(String)? onNext;
}

class FavoriteBookFieldRoute
    extends _i1.PageRouteInfo<FavoriteBookFieldRouteArgs> {
  FavoriteBookFieldRoute(
      {_i15.Key? key,
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

  final _i15.Key? key;

  final String message;

  final String willPopMessage;

  final void Function(String)? onNext;
}

class UserDataRoute extends _i1.PageRouteInfo<UserDataRouteArgs> {
  UserDataRoute({_i15.Key? key, dynamic Function(_i5.UserData)? onResult})
      : super(name,
            path: 'results',
            args: UserDataRouteArgs(key: key, onResult: onResult));

  static const String name = 'UserDataRoute';
}

class UserDataRouteArgs {
  const UserDataRouteArgs({this.key, this.onResult});

  final _i15.Key? key;

  final dynamic Function(_i5.UserData)? onResult;
}
