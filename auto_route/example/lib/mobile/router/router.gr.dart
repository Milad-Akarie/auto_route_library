// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i8;
import 'package:example/data/db.dart' as _i9;
import 'package:example/mobile/screens/books/book_details_page.dart' as _i1;
import 'package:example/mobile/screens/books/book_list_page.dart' as _i2;
import 'package:example/mobile/screens/home_page.dart' as _i3;
import 'package:example/mobile/screens/login_page.dart' as _i4;
import 'package:example/mobile/screens/profile/my_books_page.dart' as _i5;
import 'package:example/mobile/screens/profile/profile_page.dart' as _i6;
import 'package:example/mobile/screens/settings_page.dart' as _i7;
import 'package:flutter/material.dart' as _i10;

/// generated route for
/// [_i1.BookDetailsPage]
class BookDetailsRoute extends _i8.PageRouteInfo<BookDetailsRouteArgs> {
  BookDetailsRoute({
    int id = -3,
    _i9.Book? book,
    List<_i8.PageRouteInfo>? children,
  }) : super(
         BookDetailsRoute.name,
         args: BookDetailsRouteArgs(id: id, book: book),
         rawPathParams: {'id': id},
         initialChildren: children,
       );

  static const String name = 'BookDetailsRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<BookDetailsRouteArgs>(
        orElse: () => BookDetailsRouteArgs(id: pathParams.getInt('id', -3)),
      );
      return _i1.BookDetailsPage(id: args.id, book: args.book);
    },
  );
}

class BookDetailsRouteArgs {
  const BookDetailsRouteArgs({this.id = -3, this.book});

  final int id;

  final _i9.Book? book;

  @override
  String toString() {
    return 'BookDetailsRouteArgs{id: $id, book: $book}';
  }
}

/// generated route for
/// [_i2.BookListScreen]
class BookListRoute extends _i8.PageRouteInfo<void> {
  const BookListRoute({List<_i8.PageRouteInfo>? children})
    : super(BookListRoute.name, initialChildren: children);

  static const String name = 'BookListRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return _i2.BookListScreen();
    },
  );
}

/// generated route for
/// [_i3.HomePage]
class HomeRoute extends _i8.PageRouteInfo<void> {
  const HomeRoute({List<_i8.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i3.HomePage();
    },
  );
}

/// generated route for
/// [_i4.LoginPage]
class LoginRoute extends _i8.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i10.Key? key,
    void Function(bool)? onLoginResult,
    bool showBackButton = true,
    List<_i8.PageRouteInfo>? children,
  }) : super(
         LoginRoute.name,
         args: LoginRouteArgs(
           key: key,
           onLoginResult: onLoginResult,
           showBackButton: showBackButton,
         ),
         initialChildren: children,
       );

  static const String name = 'LoginRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LoginRouteArgs>(
        orElse: () => const LoginRouteArgs(),
      );
      return _i4.LoginPage(
        key: args.key,
        onLoginResult: args.onLoginResult,
        showBackButton: args.showBackButton,
      );
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({
    this.key,
    this.onLoginResult,
    this.showBackButton = true,
  });

  final _i10.Key? key;

  final void Function(bool)? onLoginResult;

  final bool showBackButton;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, onLoginResult: $onLoginResult, showBackButton: $showBackButton}';
  }
}

/// generated route for
/// [_i5.MyBooksPage]
class MyBooksRoute extends _i8.PageRouteInfo<MyBooksRouteArgs> {
  MyBooksRoute({
    _i10.Key? key,
    String? filter = 'none',
    List<_i8.PageRouteInfo>? children,
  }) : super(
         MyBooksRoute.name,
         args: MyBooksRouteArgs(key: key, filter: filter),
         rawQueryParams: {'filter': filter},
         initialChildren: children,
       );

  static const String name = 'MyBooksRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<MyBooksRouteArgs>(
        orElse:
            () => MyBooksRouteArgs(
              filter: queryParams.optString('filter', 'none'),
            ),
      );
      return _i5.MyBooksPage(key: args.key, filter: args.filter);
    },
  );
}

class MyBooksRouteArgs {
  const MyBooksRouteArgs({this.key, this.filter = 'none'});

  final _i10.Key? key;

  final String? filter;

  @override
  String toString() {
    return 'MyBooksRouteArgs{key: $key, filter: $filter}';
  }
}

/// generated route for
/// [_i6.ProfilePage]
class ProfileRoute extends _i8.PageRouteInfo<void> {
  const ProfileRoute({List<_i8.PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return _i6.ProfilePage();
    },
  );
}

/// generated route for
/// [_i7.SettingsPage]
class SettingsTab extends _i8.PageRouteInfo<SettingsTabArgs> {
  SettingsTab({
    _i10.Key? key,
    String tab = 'none',
    String query = 'none',
    List<_i8.PageRouteInfo>? children,
  }) : super(
         SettingsTab.name,
         args: SettingsTabArgs(key: key, tab: tab, query: query),
         rawPathParams: {'tab': tab},
         rawQueryParams: {'query': query},
         initialChildren: children,
       );

  static const String name = 'SettingsTab';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<SettingsTabArgs>(
        orElse:
            () => SettingsTabArgs(
              tab: pathParams.getString('tab', 'none'),
              query: queryParams.getString('query', 'none'),
            ),
      );
      return _i7.SettingsPage(key: args.key, tab: args.tab, query: args.query);
    },
  );
}

class SettingsTabArgs {
  const SettingsTabArgs({this.key, this.tab = 'none', this.query = 'none'});

  final _i10.Key? key;

  final String tab;

  final String query;

  @override
  String toString() {
    return 'SettingsTabArgs{key: $key, tab: $tab, query: $query}';
  }
}

/// generated route for
/// [_i3.WelcomeScreen]
class WelcomeRoute extends _i8.PageRouteInfo<void> {
  const WelcomeRoute({List<_i8.PageRouteInfo>? children})
    : super(WelcomeRoute.name, initialChildren: children);

  static const String name = 'WelcomeRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i3.WelcomeScreen();
    },
  );
}
