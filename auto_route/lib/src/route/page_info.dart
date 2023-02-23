class PageInfo<Args> {
  final String name;

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
