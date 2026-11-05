// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'user_router.dart';

/// generated route for
/// [UserHomeView]
class UserHomeRoute extends PageRouteInfo<void> {
  const UserHomeRoute({List<PageRouteInfo>? children})
    : super(UserHomeRoute.name, initialChildren: children);

  static const String name = 'UserHomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const UserHomeView();
    },
  );
}

/// generated route for
/// [UserProfileView]
class UserProfileRoute extends PageRouteInfo<UserProfileRouteArgs> {
  UserProfileRoute({
    required UserId id,
    Key? key,
    UserId? by,
    List<PageRouteInfo>? children,
  }) : super(
         UserProfileRoute.name,
         args: UserProfileRouteArgs(id: id, key: key, by: by),
         rawPathParams: {'id': userIdConverter.toParam(id)},
         rawQueryParams: {
           'by': by == null ? null : userIdConverter.toParam(by),
         },
         initialChildren: children,
       );

  static const String name = 'UserProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<UserProfileRouteArgs>(
        orElse: () => UserProfileRouteArgs(
          id: pathParams.getTyped<UserId>('id', userIdConverter),
          by: queryParams.optTyped<UserId>('by', userIdConverter),
        ),
      );
      return UserProfileView(id: args.id, key: args.key, by: args.by);
    },
  );
}

class UserProfileRouteArgs {
  const UserProfileRouteArgs({required this.id, this.key, this.by});

  final UserId id;

  final Key? key;

  final UserId? by;

  @override
  String toString() {
    return 'UserProfileRouteArgs{id: $id, key: $key, by: $by}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserProfileRouteArgs) return false;
    return id == other.id && key == other.key && by == other.by;
  }

  @override
  int get hashCode => id.hashCode ^ key.hashCode ^ by.hashCode;
}
