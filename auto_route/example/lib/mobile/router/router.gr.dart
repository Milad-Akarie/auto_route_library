// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i1;
import 'package:flutter/material.dart' as _i13;

import '../screens/books/book_details_page.dart' as _i8;
import '../screens/books/book_list_page.dart' as _i7;
import '../screens/home_page.dart' as _i3;
import '../screens/login_page.dart' as _i5;
import '../screens/profile/my_books_page.dart' as _i10;
import '../screens/profile/profile_page.dart' as _i9;
import '../screens/settings.dart' as _i6;
import '../screens/user-data/data_collector.dart' as _i4;
import '../screens/user-data/sinlge_field_page.dart' as _i11;
import '../screens/user-data/user_data_page.dart' as _i12;
import 'auth_guard.dart' as _i2;

class AppRouter extends _i1.RootStackRouter {
  AppRouter({required this.authGuard});

  final _i2.AuthGuard authGuard;

  @override
  final Map<String, _i1.PageFactory> pagesMap = {
    HomeRoute.name: (entry) {
      return _i1.MaterialPageX(
          entry: entry,
          child: _i3.HomePage(),
          maintainState: true,
          fullscreenDialog: false);
    },
    UserDataCollectorRoute.name: (entry) {
      var args = entry.routeData.argsAs<UserDataCollectorRouteArgs>(
          orElse: () => UserDataCollectorRouteArgs());
      return _i1.MaterialPageX(
          entry: entry,
          child:
              _i4.UserDataCollectorPage(key: args.key, onResult: args.onResult),
          maintainState: true,
          fullscreenDialog: false);
    },
    LoginRoute.name: (entry) {
      var args = entry.routeData
          .argsAs<LoginRouteArgs>(orElse: () => LoginRouteArgs());
      return _i1.MaterialPageX(
          entry: entry,
          child: _i5.LoginPage(
              key: args.key,
              onLoginResult: args.onLoginResult,
              showBackButton: args.showBackButton),
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
          child: _i6.SettingsPage(),
          maintainState: true,
          fullscreenDialog: false);
    },
    BookListRoute.name: (entry) {
      return _i1.MaterialPageX(
          entry: entry,
          child: _i7.BookListPage(),
          maintainState: true,
          fullscreenDialog: false);
    },
    BookDetailsRoute.name: (entry) {
      var args = entry.routeData
          .argsAs<BookDetailsRouteArgs>(orElse: () => BookDetailsRouteArgs());
      var pathParams = entry.routeData.pathParams;
      return _i1.MaterialPageX(
          entry: entry,
          child: _i8.BookDetailsPage(id: pathParams.getInt('id', args.id)),
          maintainState: true,
          fullscreenDialog: false);
    },
    ProfileRoute.name: (entry) {
      return _i1.MaterialPageX(
          entry: entry,
          child: _i9.ProfilePage(),
          maintainState: true,
          fullscreenDialog: false);
    },
    MyBooksRoute.name: (entry) {
      var args = entry.routeData
          .argsAs<MyBooksRouteArgs>(orElse: () => MyBooksRouteArgs());
      var queryParams = entry.routeData.queryParams;
      return _i1.MaterialPageX(
          entry: entry,
          child: _i10.MyBooksPage(
              key: args.key,
              filter: queryParams.getString('filter', args.filter)),
          maintainState: true,
          fullscreenDialog: false);
    },
    SingleFieldRoute.name: (entry) {
      var args = entry.routeData.argsAs<SingleFieldRouteArgs>();
      return _i1.CustomPage(
          entry: entry,
          child: _i11.SingleFieldPage(
              key: args.key,
              message: args.message,
              willPopMessage: args.willPopMessage,
              onNext: args.onNext),
          maintainState: true,
          fullscreenDialog: false,
          transitionsBuilder: _i1.TransitionsBuilders.slideRightWithFade,
          opaque: true,
          barrierDismissible: false);
    },
    UserDataRoute.name: (entry) {
      var args = entry.routeData
          .argsAs<UserDataRouteArgs>(orElse: () => UserDataRouteArgs());
      return _i1.CustomPage(
          entry: entry,
          child: _i12.UserDataPage(key: args.key, onResult: args.onResult),
          maintainState: true,
          fullscreenDialog: false,
          transitionsBuilder: _i1.TransitionsBuilders.slideRightWithFade,
          opaque: true,
          barrierDismissible: false);
    }
  };

  @override
  List<_i1.RouteConfig> get routes => [
        _i1.RouteConfig(HomeRoute.name,
            path: '/',
            fullMatch: false,
            usesTabsRouter: true,
            guards: [
              authGuard
            ],
            children: [
              _i1.RouteConfig('#redirect',
                  path: '', redirectTo: 'books', fullMatch: true),
              _i1.RouteConfig(BooksTab.name,
                  path: 'books',
                  fullMatch: false,
                  usesTabsRouter: false,
                  children: [
                    _i1.RouteConfig(BookListRoute.name,
                        path: '', fullMatch: false, usesTabsRouter: false),
                    _i1.RouteConfig(BookDetailsRoute.name,
                        path: ':id', fullMatch: false, usesTabsRouter: false)
                  ]),
              _i1.RouteConfig(ProfileTab.name,
                  path: 'profile',
                  fullMatch: false,
                  usesTabsRouter: false,
                  children: [
                    _i1.RouteConfig(ProfileRoute.name,
                        path: '', fullMatch: false, usesTabsRouter: false),
                    _i1.RouteConfig(MyBooksRoute.name,
                        path: 'books', fullMatch: false, usesTabsRouter: false)
                  ]),
              _i1.RouteConfig(SettingsTab.name,
                  path: 'settings', fullMatch: false, usesTabsRouter: false)
            ]),
        _i1.RouteConfig(UserDataCollectorRoute.name,
            path: '/user-data',
            fullMatch: false,
            usesTabsRouter: false,
            children: [
              _i1.RouteConfig(SingleFieldRoute.name,
                  path: 'single-field-page',
                  fullMatch: false,
                  usesTabsRouter: false),
              _i1.RouteConfig(UserDataRoute.name,
                  path: 'user-data-page',
                  fullMatch: false,
                  usesTabsRouter: false)
            ]),
        _i1.RouteConfig(LoginRoute.name,
            path: '/login', fullMatch: false, usesTabsRouter: false),
        _i1.RouteConfig('*#redirect',
            path: '*', redirectTo: '/', fullMatch: true)
      ];
}

class HomeRoute extends _i1.PageRouteInfo {
  const HomeRoute({List<_i1.PageRouteInfo>? children})
      : super(name, path: '/', initialChildren: children);

  static const String name = 'HomeRoute';
}

class UserDataCollectorRoute
    extends _i1.PageRouteInfo<UserDataCollectorRouteArgs> {
  UserDataCollectorRoute(
      {this.key, this.onResult, List<_i1.PageRouteInfo>? children})
      : super(name,
            path: '/user-data',
            args: UserDataCollectorRouteArgs(key: key, onResult: onResult),
            initialChildren: children);

  final _i13.Key? key;

  final dynamic Function(_i4.UserData)? onResult;

  static const String name = 'UserDataCollectorRoute';
}

class UserDataCollectorRouteArgs {
  const UserDataCollectorRouteArgs({this.key, this.onResult});

  final _i13.Key? key;

  final dynamic Function(_i4.UserData)? onResult;
}

class LoginRoute extends _i1.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({this.key, this.onLoginResult, this.showBackButton = true})
      : super(name,
            path: '/login',
            args: LoginRouteArgs(
                key: key,
                onLoginResult: onLoginResult,
                showBackButton: showBackButton));

  final _i13.Key? key;

  final void Function(bool)? onLoginResult;

  final bool showBackButton;

  static const String name = 'LoginRoute';
}

class LoginRouteArgs {
  const LoginRouteArgs(
      {this.key, this.onLoginResult, this.showBackButton = true});

  final _i13.Key? key;

  final void Function(bool)? onLoginResult;

  final bool showBackButton;
}

class BooksTab extends _i1.PageRouteInfo {
  const BooksTab({List<_i1.PageRouteInfo>? children})
      : super(name, path: 'books', initialChildren: children);

  static const String name = 'BooksTab';
}

class ProfileTab extends _i1.PageRouteInfo {
  const ProfileTab({List<_i1.PageRouteInfo>? children})
      : super(name, path: 'profile', initialChildren: children);

  static const String name = 'ProfileTab';
}

class SettingsTab extends _i1.PageRouteInfo {
  const SettingsTab() : super(name, path: 'settings');

  static const String name = 'SettingsTab';
}

class BookListRoute extends _i1.PageRouteInfo {
  const BookListRoute() : super(name, path: '');

  static const String name = 'BookListRoute';
}

class BookDetailsRoute extends _i1.PageRouteInfo<BookDetailsRouteArgs> {
  BookDetailsRoute({this.id = -1})
      : super(name, path: ':id', args: BookDetailsRouteArgs(id: id));

  final int id;

  static const String name = 'BookDetailsRoute';
}

class BookDetailsRouteArgs {
  const BookDetailsRouteArgs({this.id = -1});

  final int id;
}

class ProfileRoute extends _i1.PageRouteInfo {
  const ProfileRoute() : super(name, path: '');

  static const String name = 'ProfileRoute';
}

class MyBooksRoute extends _i1.PageRouteInfo<MyBooksRouteArgs> {
  MyBooksRoute({this.key, this.filter = 'none'})
      : super(name,
            path: 'books',
            args: MyBooksRouteArgs(key: key, filter: filter),
            queryParams: {'filter': filter});

  final _i13.Key? key;

  final String filter;

  static const String name = 'MyBooksRoute';
}

class MyBooksRouteArgs {
  const MyBooksRouteArgs({this.key, this.filter = 'none'});

  final _i13.Key? key;

  final String filter;
}

class SingleFieldRoute extends _i1.PageRouteInfo<SingleFieldRouteArgs> {
  SingleFieldRoute(
      {this.key,
      required this.message,
      required this.willPopMessage,
      required this.onNext})
      : super(name,
            path: 'single-field-page',
            args: SingleFieldRouteArgs(
                key: key,
                message: message,
                willPopMessage: willPopMessage,
                onNext: onNext));

  final _i13.Key? key;

  final String message;

  final String willPopMessage;

  final void Function(String) onNext;

  static const String name = 'SingleFieldRoute';
}

class SingleFieldRouteArgs {
  const SingleFieldRouteArgs(
      {this.key,
      required this.message,
      required this.willPopMessage,
      required this.onNext});

  final _i13.Key? key;

  final String message;

  final String willPopMessage;

  final void Function(String) onNext;
}

class UserDataRoute extends _i1.PageRouteInfo<UserDataRouteArgs> {
  UserDataRoute({this.key, this.onResult})
      : super(name,
            path: 'user-data-page',
            args: UserDataRouteArgs(key: key, onResult: onResult));

  final _i13.Key? key;

  final dynamic Function(_i4.UserData)? onResult;

  static const String name = 'UserDataRoute';
}

class UserDataRouteArgs {
  const UserDataRouteArgs({this.key, this.onResult});

  final _i13.Key? key;

  final dynamic Function(_i4.UserData)? onResult;
}
