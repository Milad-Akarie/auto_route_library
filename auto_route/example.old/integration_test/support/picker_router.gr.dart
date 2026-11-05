// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'picker_router.dart';

/// generated route for
/// [PickerHomeView]
class PickerHomeRoute extends PageRouteInfo<void> {
  const PickerHomeRoute({List<PageRouteInfo>? children})
    : super(PickerHomeRoute.name, initialChildren: children);

  static const String name = 'PickerHomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PickerHomeView();
    },
  );
}

/// generated route for
/// [PickerView]
class PickerRoute<T> extends PageRouteInfo<PickerRouteArgs<T>> {
  PickerRoute({
    Key? key,
    List<T> items = const [],
    String title = 'Pick',
    List<PageRouteInfo>? children,
  }) : super(
         PickerRoute.name,
         args: PickerRouteArgs<T>(key: key, items: items, title: title),
         rawQueryParams: {'title': title},
         initialChildren: children,
       );

  static const String name = 'PickerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<PickerRouteArgs>(
        orElse: () =>
            PickerRouteArgs(title: queryParams.getString('title', 'Pick')),
      );
      return args.buildPage();
    },
  );
}

class PickerRouteArgs<T> {
  const PickerRouteArgs({this.key, this.items = const [], this.title = 'Pick'});

  final Key? key;

  final List<T> items;

  final String title;

  /// Builds the page with this route's type arguments.
  PickerView<T> buildPage() =>
      PickerView<T>(key: key, items: items, title: title);

  @override
  String toString() {
    return 'PickerRouteArgs{key: $key, items: $items, title: $title}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PickerRouteArgs<T>) return false;
    return key == other.key &&
        const ListEquality<Object?>().equals(items, other.items) &&
        title == other.title;
  }

  @override
  int get hashCode =>
      key.hashCode ^ const ListEquality<Object?>().hash(items) ^ title.hashCode;
}
