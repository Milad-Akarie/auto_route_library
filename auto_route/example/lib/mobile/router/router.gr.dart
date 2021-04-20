// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i2;
import 'package:flutter/cupertino.dart' as _i13;
import 'package:flutter/material.dart' as _i3;

import '../screens/books/book_details_page.dart' as _i5;
import '../screens/books/book_list_page.dart' as _i4;
import '../screens/home_page.dart' as _i6;
import '../screens/login_page.dart' as _i7;
import '../screens/profile/my_books_page.dart' as _i10;
import '../screens/profile/profile_page.dart' as _i9;
import '../screens/settings.dart' as _i8;
import '../screens/user-data/data_collector.dart' as _i1;
import '../screens/user-data/sinlge_field_page.dart' as _i11;
import '../screens/user-data/user_data_page.dart' as _i12;

class AppRouter extends _i2.RootStackRouter {
  AppRouter([_i3.GlobalKey<_i3.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i2.PageFactory> pagesMap = {
    BookListRoute.name: (routeData) {
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData, child: _i4.BookListPage());
    },
    BookDetailsRoute.name: (routeData) {
      var pathParams = routeData.pathParams;
      final args = routeData.argsAs<BookDetailsRouteArgs>(
          orElse: () => BookDetailsRouteArgs(id: pathParams.getInt('id', -1)));
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData, child: _i5.BookDetailsPage(id: args.id));
    },
    HomeRoute.name: (routeData) {
      final args =
          routeData.argsAs<HomeRouteArgs>(orElse: () => const HomeRouteArgs());
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i6.HomePage(
              key: args.key,
              enumValue: args.enumValue,
              userData: args.userData));
    },
    UserDataCollectorRoute.name: (routeData) {
      final args = routeData.argsAs<UserDataCollectorRouteArgs>(
          orElse: () => const UserDataCollectorRouteArgs());
      return _i2.MaterialPageX<_i1.UserData>(
          routeData: routeData,
          child: _i1.UserDataCollectorPage(
              key: args.key, onResult: args.onResult));
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i7.LoginPage(
              key: args.key,
              onLoginResult: args.onLoginResult,
              showBackButton: args.showBackButton));
    },
    BooksTab.name: (routeData) {
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i2.EmptyRouterPage());
    },
    ProfileTab.name: (routeData) {
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i2.EmptyRouterPage());
    },
    SettingsTab.name: (routeData) {
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData, child: _i8.SettingsPage());
    },
    ProfileRoute.name: (routeData) {
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData, child: _i9.ProfilePage());
    },
    MyBooksRoute.name: (routeData) {
      var queryParams = routeData.queryParams;
      final args = routeData.argsAs<MyBooksRouteArgs>(
          orElse: () => MyBooksRouteArgs(
              filter: queryParams.getString('filter', 'none')));
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i10.MyBooksPage(key: args.key, filter: args.filter));
    },
    NameFieldRoute.name: (routeData) {
      final args = routeData.argsAs<NameFieldRouteArgs>(
          orElse: () => const NameFieldRouteArgs());
      return _i2.CustomPage<dynamic>(
          routeData: routeData,
          child: _i11.SingleFieldPage(
              key: args.key,
              message: args.message,
              willPopMessage: args.willPopMessage,
              onNext: args.onNext),
          transitionsBuilder: _i2.TransitionsBuilders.slideRightWithFade,
          opaque: true,
          barrierDismissible: false);
    },
    FavoriteBookFieldRoute.name: (routeData) {
      final args = routeData.argsAs<FavoriteBookFieldRouteArgs>(
          orElse: () => const FavoriteBookFieldRouteArgs());
      return _i2.CustomPage<dynamic>(
          routeData: routeData,
          child: _i11.SingleFieldPage(
              key: args.key,
              message: args.message,
              willPopMessage: args.willPopMessage,
              onNext: args.onNext),
          transitionsBuilder: _i2.TransitionsBuilders.slideRightWithFade,
          opaque: true,
          barrierDismissible: false);
    },
    UserDataRoute.name: (routeData) {
      final args = routeData.argsAs<UserDataRouteArgs>(
          orElse: () => const UserDataRouteArgs());
      return _i2.CustomPage<dynamic>(
          routeData: routeData,
          child: _i12.UserDataPage(key: args.key, onResult: args.onResult),
          transitionsBuilder: _i2.TransitionsBuilders.slideRightWithFade,
          opaque: true,
          barrierDismissible: false);
    }
  };

  @override
  List<_i2.RouteConfig> get routes => [
        _i2.RouteConfig(BookListRoute.name, path: '/books'),
        _i2.RouteConfig(BookDetailsRoute.name, path: '/books/:id'),
        _i2.RouteConfig(HomeRoute.name,
            path: '/',
            usesTabsRouter: true,
            children: [
              _i2.RouteConfig('#redirect',
                  path: '', redirectTo: 'books', fullMatch: true),
              _i2.RouteConfig(BooksTab.name, path: 'books'),
              _i2.RouteConfig(ProfileTab.name, path: 'profile', children: [
                _i2.RouteConfig(ProfileRoute.name, path: ''),
                _i2.RouteConfig(MyBooksRoute.name, path: 'books')
              ]),
              _i2.RouteConfig(SettingsTab.name, path: 'settings')
            ]),
        _i2.RouteConfig(UserDataCollectorRoute.name,
            path: '/user-data',
            children: [
              _i2.RouteConfig(NameFieldRoute.name, path: 'name'),
              _i2.RouteConfig(FavoriteBookFieldRoute.name,
                  path: 'favorite-book'),
              _i2.RouteConfig(UserDataRoute.name, path: 'results')
            ]),
        _i2.RouteConfig('/user-data/*#redirect',
            path: '/user-data/*', redirectTo: '/user-data', fullMatch: true),
        _i2.RouteConfig(LoginRoute.name, path: '/login')
      ];
}

class BookListRoute extends _i2.PageRouteInfo {
  const BookListRoute() : super(name, path: '/books');

  static const String name = 'BookListRoute';
}

class BookDetailsRoute extends _i2.PageRouteInfo<BookDetailsRouteArgs> {
  BookDetailsRoute({int id = -1})
      : super(name,
            path: '/books/:id',
            args: BookDetailsRouteArgs(id: id),
            params: {'id': id});

  static const String name = 'BookDetailsRoute';
}

class BookDetailsRouteArgs {
  const BookDetailsRouteArgs({this.id = -1});

  final int id;
}

class HomeRoute extends _i2.PageRouteInfo<HomeRouteArgs> {
  HomeRoute(
      {_i13.Key? key,
      _i6.ConstEnum enumValue = _i6.ConstEnum.value1,
      _i1.UserData userData = const _i1.UserData(),
      List<_i2.PageRouteInfo>? children})
      : super(name,
            path: '/',
            args: HomeRouteArgs(
                key: key, enumValue: enumValue, userData: userData),
            children: children);

  static const String name = 'HomeRoute';
}

class HomeRouteArgs {
  const HomeRouteArgs(
      {this.key,
      this.enumValue = _i6.ConstEnum.value1,
      this.userData = const _i1.UserData()});

  final _i13.Key? key;

  final _i6.ConstEnum enumValue;

  final _i1.UserData userData;
}

class UserDataCollectorRoute
    extends _i2.PageRouteInfo<UserDataCollectorRouteArgs> {
  UserDataCollectorRoute(
      {_i13.Key? key,
      dynamic Function(_i1.UserData)? onResult,
      List<_i2.PageRouteInfo>? children})
      : super(name,
            path: '/user-data',
            args: UserDataCollectorRouteArgs(key: key, onResult: onResult),
            children: children);

  static const String name = 'UserDataCollectorRoute';
}

class UserDataCollectorRouteArgs {
  const UserDataCollectorRouteArgs({this.key, this.onResult});

  final _i13.Key? key;

  final dynamic Function(_i1.UserData)? onResult;
}

class LoginRoute extends _i2.PageRouteInfo<LoginRouteArgs> {
  LoginRoute(
      {_i13.Key? key,
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

  final _i13.Key? key;

  final void Function(bool)? onLoginResult;

  final bool showBackButton;
}

class BooksTab extends _i2.PageRouteInfo {
  const BooksTab() : super(name, path: 'books');

  static const String name = 'BooksTab';
}

class ProfileTab extends _i2.PageRouteInfo {
  const ProfileTab({List<_i2.PageRouteInfo>? children})
      : super(name, path: 'profile', children: children);

  static const String name = 'ProfileTab';
}

class SettingsTab extends _i2.PageRouteInfo {
  const SettingsTab() : super(name, path: 'settings');

  static const String name = 'SettingsTab';
}

class ProfileRoute extends _i2.PageRouteInfo {
  const ProfileRoute() : super(name, path: '');

  static const String name = 'ProfileRoute';
}

class MyBooksRoute extends _i2.PageRouteInfo<MyBooksRouteArgs> {
  MyBooksRoute({_i13.Key? key, String filter = 'none'})
      : super(name,
            path: 'books',
            args: MyBooksRouteArgs(key: key, filter: filter),
            queryParams: {'filter': filter});

  static const String name = 'MyBooksRoute';
}

class MyBooksRouteArgs {
  const MyBooksRouteArgs({this.key, this.filter = 'none'});

  final _i13.Key? key;

  final String filter;
}

class NameFieldRoute extends _i2.PageRouteInfo<NameFieldRouteArgs> {
  NameFieldRoute(
      {_i13.Key? key,
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

  final _i13.Key? key;

  final String message;

  final String willPopMessage;

  final void Function(String)? onNext;
}

class FavoriteBookFieldRoute
    extends _i2.PageRouteInfo<FavoriteBookFieldRouteArgs> {
  FavoriteBookFieldRoute(
      {_i13.Key? key,
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

  final _i13.Key? key;

  final String message;

  final String willPopMessage;

  final void Function(String)? onNext;
}

class UserDataRoute extends _i2.PageRouteInfo<UserDataRouteArgs> {
  UserDataRoute({_i13.Key? key, dynamic Function(_i1.UserData)? onResult})
      : super(name,
            path: 'results',
            args: UserDataRouteArgs(key: key, onResult: onResult));

  static const String name = 'UserDataRoute';
}

class UserDataRouteArgs {
  const UserDataRouteArgs({this.key, this.onResult});

  final _i13.Key? key;

  final dynamic Function(_i1.UserData)? onResult;
}
