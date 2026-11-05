// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'cart_router.dart';

/// generated route for
/// [CartHomeView]
class CartHomeRoute extends PageRouteInfo<void> {
  const CartHomeRoute({List<PageRouteInfo>? children})
    : super(CartHomeRoute.name, initialChildren: children);

  static const String name = 'CartHomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CartHomeView();
    },
  );
}

/// generated route for
/// [MfUserCartView]
class MfUserCartRoute extends PageRouteInfo<MfUserCartRouteArgs> {
  MfUserCartRoute({
    required MfUserCartTypes? userCartType,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         MfUserCartRoute.name,
         args: MfUserCartRouteArgs(userCartType: userCartType, key: key),
         rawQueryParams: {'type': userCartType?.name},
         initialChildren: children,
       );

  static const String name = 'MfUserCartRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<MfUserCartRouteArgs>(
        orElse: () => MfUserCartRouteArgs(
          userCartType: MfUserCartTypes.values
              .asNameMap()[queryParams.optString('type')],
        ),
      );
      return MfUserCartView(userCartType: args.userCartType, key: args.key);
    },
  );
}

class MfUserCartRouteArgs {
  const MfUserCartRouteArgs({required this.userCartType, this.key});

  final MfUserCartTypes? userCartType;

  final Key? key;

  @override
  String toString() {
    return 'MfUserCartRouteArgs{userCartType: $userCartType, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MfUserCartRouteArgs) return false;
    return userCartType == other.userCartType && key == other.key;
  }

  @override
  int get hashCode => userCartType.hashCode ^ key.hashCode;
}
