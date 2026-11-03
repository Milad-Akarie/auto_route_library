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
    Key? key,
    required MfUserCartTypes? userCartType,
    List<PageRouteInfo>? children,
  }) : super(
         MfUserCartRoute.name,
         args: MfUserCartRouteArgs(key: key, userCartType: userCartType),
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
      return MfUserCartView(key: args.key, userCartType: args.userCartType);
    },
  );
}

class MfUserCartRouteArgs {
  const MfUserCartRouteArgs({this.key, required this.userCartType});

  final Key? key;

  final MfUserCartTypes? userCartType;

  @override
  String toString() {
    return 'MfUserCartRouteArgs{key: $key, userCartType: $userCartType}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MfUserCartRouteArgs) return false;
    return key == other.key && userCartType == other.userCartType;
  }

  @override
  int get hashCode => key.hashCode ^ userCartType.hashCode;
}
