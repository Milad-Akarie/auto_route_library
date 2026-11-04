// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'list_router.dart';

/// generated route for
/// [ItemsView]
class ItemsRoute extends PageRouteInfo<ItemsRouteArgs> {
  ItemsRoute({
    Key? key,
    List<int>? ids,
    List<double>? prices,
    List<bool>? flags,
    List<Sort>? sorts,
    List<int> picked = const [1, 2],
    List<PageRouteInfo>? children,
  }) : super(
          ItemsRoute.name,
          args: ItemsRouteArgs(
            key: key,
            ids: ids,
            prices: prices,
            flags: flags,
            sorts: sorts,
            picked: picked,
          ),
          rawQueryParams: {
            'ids': ids,
            'prices': prices,
            'flags': flags,
            'sorts': sorts?.map((item) => item.name).toList(),
            'picked': picked,
          },
          initialChildren: children,
        );

  static const String name = 'ItemsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<ItemsRouteArgs>(
        orElse: () => ItemsRouteArgs(
          ids: queryParams
              .optList('ids')
              ?.map(int.tryParse)
              .whereType<int>()
              .toList(),
          prices: queryParams
              .optList('prices')
              ?.map(double.tryParse)
              .whereType<double>()
              .toList(),
          flags: queryParams
              .optList('flags')
              ?.map(
                (text) => text.toLowerCase() == 'true'
                    ? true
                    : text.toLowerCase() == 'false'
                        ? false
                        : null,
              )
              .whereType<bool>()
              .toList(),
          sorts: queryParams
              .optList('sorts')
              ?.map((name) => Sort.values.asNameMap()[name])
              .whereType<Sort>()
              .toList(),
          picked: queryParams
                  .optList('picked')
                  ?.map(int.tryParse)
                  .whereType<int>()
                  .toList() ??
              const [1, 2],
        ),
      );
      return ItemsView(
        key: args.key,
        ids: args.ids,
        prices: args.prices,
        flags: args.flags,
        sorts: args.sorts,
        picked: args.picked,
      );
    },
  );
}

class ItemsRouteArgs {
  const ItemsRouteArgs({
    this.key,
    this.ids,
    this.prices,
    this.flags,
    this.sorts,
    this.picked = const [1, 2],
  });

  final Key? key;

  final List<int>? ids;

  final List<double>? prices;

  final List<bool>? flags;

  final List<Sort>? sorts;

  final List<int> picked;

  @override
  String toString() {
    return 'ItemsRouteArgs{key: $key, ids: $ids, prices: $prices, flags: $flags, sorts: $sorts, picked: $picked}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ItemsRouteArgs) return false;
    return key == other.key &&
        const ListEquality<int>().equals(ids, other.ids) &&
        const ListEquality<double>().equals(prices, other.prices) &&
        const ListEquality<bool>().equals(flags, other.flags) &&
        const ListEquality<Sort>().equals(sorts, other.sorts) &&
        const ListEquality<int>().equals(picked, other.picked);
  }

  @override
  int get hashCode =>
      key.hashCode ^
      const ListEquality<int>().hash(ids) ^
      const ListEquality<double>().hash(prices) ^
      const ListEquality<bool>().hash(flags) ^
      const ListEquality<Sort>().hash(sorts) ^
      const ListEquality<int>().hash(picked);
}

/// generated route for
/// [ListHomeView]
class ListHomeRoute extends PageRouteInfo<void> {
  const ListHomeRoute({List<PageRouteInfo>? children})
      : super(ListHomeRoute.name, initialChildren: children);

  static const String name = 'ListHomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ListHomeView();
    },
  );
}
