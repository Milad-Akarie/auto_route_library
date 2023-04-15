/// Holds information of the generated [RoutePage] page
///
/// Might hold more info in the future
class PageInfo<Args> {
  /// The name of the generated [RoutePage]
  final String name;

  /// Default constructor
  const PageInfo(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageInfo &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}
