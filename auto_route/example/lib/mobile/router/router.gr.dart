// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

import 'package:auto_route/auto_route.dart' as _i4;
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

class RootRouter extends _i4.RootStackRouter {
  RootRouter([_i12.GlobalKey<_i12.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i4.PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      return _i4.MaterialPageX<String>(
          routeData: routeData, child: const _i1.HomePage());
    },
    UserDataCollectorRoute.name: (routeData) {
      final args = routeData.argsAs<UserDataCollectorRouteArgs>(
          orElse: () => const UserDataCollectorRouteArgs());
      return _i4.MaterialPageX<_i2.UserData>(
          routeData: routeData,
          child: _i4.WrappedRoute(
              child: _i2.UserDataCollectorPage(
                  key: args.key, onResult: args.onResult)));
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i3.LoginPage(
              key: args.key,
              onLoginResult: args.onLoginResult,
              showBackButton: args.showBackButton));
    },
    BooksTab.name: (routeData) {
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i4.EmptyRouterPage());
    },
    ProfileTab.name: (routeData) {
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i4.EmptyRouterPage());
    },
    SettingsTab.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final queryParams = routeData.queryParams;
      final args = routeData.argsAs<SettingsTabArgs>(
          orElse: () => SettingsTabArgs(
              tab: pathParams.getString('tab'),
              query: queryParams.getString('query', 'none')));
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i5.SettingsPage(
              key: args.key, tab: args.tab, query: args.query));
    },
    BookListRoute.name: (routeData) {
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData, child: _i6.BookListScreen());
    },
    BookDetailsRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<BookDetailsRouteArgs>(
          orElse: () => BookDetailsRouteArgs(id: pathParams.getInt('id', -1)));
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i7.BookDetailsPage(id: args.id),
          fullscreenDialog: true);
    },
    ProfileRoute.name: (routeData) {
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData, child: _i8.ProfilePage());
    },
    MyBooksRoute.name: (routeData) {
      final queryParams = routeData.queryParams;
      final args = routeData.argsAs<MyBooksRouteArgs>(
          orElse: () => MyBooksRouteArgs(
              filter: queryParams.optString('filter', 'none')));
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i9.MyBooksPage(key: args.key, filter: args.filter));
    },
    NameFieldRoute.name: (routeData) {
      final args = routeData.argsAs<NameFieldRouteArgs>(
          orElse: () => const NameFieldRouteArgs());
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i10.SingleFieldPage(
              key: args.key,
              message: args.message,
              willPopMessage: args.willPopMessage,
              onNext: args.onNext));
    },
    FavoriteBookFieldRoute.name: (routeData) {
      final args = routeData.argsAs<FavoriteBookFieldRouteArgs>(
          orElse: () => const FavoriteBookFieldRouteArgs());
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i10.SingleFieldPage(
              key: args.key,
              message: args.message,
              willPopMessage: args.willPopMessage,
              onNext: args.onNext));
    },
    UserDataRoute.name: (routeData) {
      final args = routeData.argsAs<UserDataRouteArgs>(
          orElse: () => const UserDataRouteArgs());
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i11.UserDataPage(key: args.key, onResult: args.onResult));
    }
  };

  @override
  List<_i4.RouteConfig> get routes => [
        _i4.RouteConfig(HomeRoute.name, path: '/', children: [
          _i4.RouteConfig('#redirect',
              path: '',
              parent: HomeRoute.name,
              redirectTo: 'books',
              fullMatch: true),
          _i4.RouteConfig(BooksTab.name,
              path: 'books',
              parent: HomeRoute.name,
              children: [
                _i4.RouteConfig(BookListRoute.name,
                    path: '', parent: BooksTab.name),
                _i4.RouteConfig(BookDetailsRoute.name,
                    path: ':id', parent: BooksTab.name)
              ]),
          _i4.RouteConfig(ProfileTab.name,
              path: 'profile',
              parent: HomeRoute.name,
              children: [
                _i4.RouteConfig(ProfileRoute.name,
                    path: '', parent: ProfileTab.name),
                _i4.RouteConfig(MyBooksRoute.name,
                    path: 'my-books', parent: ProfileTab.name)
              ]),
          _i4.RouteConfig(SettingsTab.name,
              path: 'settings/:tab', parent: HomeRoute.name)
        ]),
        _i4.RouteConfig(UserDataCollectorRoute.name,
            path: '/user-data',
            children: [
              _i4.RouteConfig(NameFieldRoute.name,
                  path: 'name', parent: UserDataCollectorRoute.name),
              _i4.RouteConfig(FavoriteBookFieldRoute.name,
                  path: 'favorite-book', parent: UserDataCollectorRoute.name),
              _i4.RouteConfig(UserDataRoute.name,
                  path: 'results', parent: UserDataCollectorRoute.name)
            ]),
        _i4.RouteConfig(LoginRoute.name, path: '/login'),
        _i4.RouteConfig('*#redirect',
            path: '*', redirectTo: '/', fullMatch: true)
      ];
}

/// generated route for
/// [_i1.HomePage]
class HomeRoute extends _i4.PageRouteInfo<void> {
  const HomeRoute({List<_i4.PageRouteInfo>? children})
      : super(HomeRoute.name, path: '/', initialChildren: children);

  static const String name = 'HomeRoute';
}

/// generated route for
/// [_i2.UserDataCollectorPage]
class UserDataCollectorRoute
    extends _i4.PageRouteInfo<UserDataCollectorRouteArgs> {
  UserDataCollectorRoute(
      {_i12.Key? key,
      dynamic Function(_i2.UserData)? onResult,
      List<_i4.PageRouteInfo>? children})
      : super(UserDataCollectorRoute.name,
            path: '/user-data',
            args: UserDataCollectorRouteArgs(key: key, onResult: onResult),
            initialChildren: children);

  static const String name = 'UserDataCollectorRoute';
}

class UserDataCollectorRouteArgs {
  const UserDataCollectorRouteArgs({this.key, this.onResult});

  final _i12.Key? key;

  final dynamic Function(_i2.UserData)? onResult;

  @override
  String toString() {
    return 'UserDataCollectorRouteArgs{key: $key, onResult: $onResult}';
  }
}

/// generated route for
/// [_i3.LoginPage]
class LoginRoute extends _i4.PageRouteInfo<LoginRouteArgs> {
  LoginRoute(
      {_i12.Key? key,
      void Function(bool)? onLoginResult,
      bool showBackButton = true})
      : super(LoginRoute.name,
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

  final _i12.Key? key;

  final void Function(bool)? onLoginResult;

  final bool showBackButton;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, onLoginResult: $onLoginResult, showBackButton: $showBackButton}';
  }
}

/// generated route for
/// [_i4.EmptyRouterPage]
class BooksTab extends _i4.PageRouteInfo<void> {
  const BooksTab({List<_i4.PageRouteInfo>? children})
      : super(BooksTab.name, path: 'books', initialChildren: children);

  static const String name = 'BooksTab';
}

/// generated route for
/// [_i4.EmptyRouterPage]
class ProfileTab extends _i4.PageRouteInfo<void> {
  const ProfileTab({List<_i4.PageRouteInfo>? children})
      : super(ProfileTab.name, path: 'profile', initialChildren: children);

  static const String name = 'ProfileTab';
}

/// generated route for
/// [_i5.SettingsPage]
class SettingsTab extends _i4.PageRouteInfo<SettingsTabArgs> {
  SettingsTab({_i12.Key? key, required String tab, String query = 'none'})
      : super(SettingsTab.name,
            path: 'settings/:tab',
            args: SettingsTabArgs(key: key, tab: tab, query: query),
            rawPathParams: {'tab': tab},
            rawQueryParams: {'query': query});

  static const String name = 'SettingsTab';
}

class SettingsTabArgs {
  const SettingsTabArgs({this.key, required this.tab, this.query = 'none'});

  final _i12.Key? key;

  final String tab;

  final String query;

  @override
  String toString() {
    return 'SettingsTabArgs{key: $key, tab: $tab, query: $query}';
  }
}

/// generated route for
/// [_i6.BookListScreen]
class BookListRoute extends _i4.PageRouteInfo<void> {
  const BookListRoute() : super(BookListRoute.name, path: '');

  static const String name = 'BookListRoute';
}

/// generated route for
/// [_i7.BookDetailsPage]
class BookDetailsRoute extends _i4.PageRouteInfo<BookDetailsRouteArgs> {
  BookDetailsRoute({int id = -1})
      : super(BookDetailsRoute.name,
            path: ':id',
            args: BookDetailsRouteArgs(id: id),
            rawPathParams: {'id': id});

  static const String name = 'BookDetailsRoute';
}

class BookDetailsRouteArgs {
  const BookDetailsRouteArgs({this.id = -1});

  final int id;

  @override
  String toString() {
    return 'BookDetailsRouteArgs{id: $id}';
  }
}

/// generated route for
/// [_i8.ProfilePage]
class ProfileRoute extends _i4.PageRouteInfo<void> {
  const ProfileRoute() : super(ProfileRoute.name, path: '');

  static const String name = 'ProfileRoute';
}

/// generated route for
/// [_i9.MyBooksPage]
class MyBooksRoute extends _i4.PageRouteInfo<MyBooksRouteArgs> {
  MyBooksRoute({_i12.Key? key, String? filter = 'none'})
      : super(MyBooksRoute.name,
            path: 'my-books',
            args: MyBooksRouteArgs(key: key, filter: filter),
            rawQueryParams: {'filter': filter});

  static const String name = 'MyBooksRoute';
}

class MyBooksRouteArgs {
  const MyBooksRouteArgs({this.key, this.filter = 'none'});

  final _i12.Key? key;

  final String? filter;

  @override
  String toString() {
    return 'MyBooksRouteArgs{key: $key, filter: $filter}';
  }
}

/// generated route for
/// [_i10.SingleFieldPage]
class NameFieldRoute extends _i4.PageRouteInfo<NameFieldRouteArgs> {
  NameFieldRoute(
      {_i12.Key? key,
      String message = '',
      String willPopMessage = '',
      void Function(String)? onNext})
      : super(NameFieldRoute.name,
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

  final _i12.Key? key;

  final String message;

  final String willPopMessage;

  final void Function(String)? onNext;

  @override
  String toString() {
    return 'NameFieldRouteArgs{key: $key, message: $message, willPopMessage: $willPopMessage, onNext: $onNext}';
  }
}

/// generated route for
/// [_i10.SingleFieldPage]
class FavoriteBookFieldRoute
    extends _i4.PageRouteInfo<FavoriteBookFieldRouteArgs> {
  FavoriteBookFieldRoute(
      {_i12.Key? key,
      String message = '',
      String willPopMessage = '',
      void Function(String)? onNext})
      : super(FavoriteBookFieldRoute.name,
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

  final _i12.Key? key;

  final String message;

  final String willPopMessage;

  final void Function(String)? onNext;

  @override
  String toString() {
    return 'FavoriteBookFieldRouteArgs{key: $key, message: $message, willPopMessage: $willPopMessage, onNext: $onNext}';
  }
}

/// generated route for
/// [_i11.UserDataPage]
class UserDataRoute extends _i4.PageRouteInfo<UserDataRouteArgs> {
  UserDataRoute({_i12.Key? key, dynamic Function(_i2.UserData)? onResult})
      : super(UserDataRoute.name,
            path: 'results',
            args: UserDataRouteArgs(key: key, onResult: onResult));

  static const String name = 'UserDataRoute';
}

class UserDataRouteArgs {
  const UserDataRouteArgs({this.key, this.onResult});

  final _i12.Key? key;

  final dynamic Function(_i2.UserData)? onResult;

  @override
  String toString() {
    return 'UserDataRouteArgs{key: $key, onResult: $onResult}';
  }
}
