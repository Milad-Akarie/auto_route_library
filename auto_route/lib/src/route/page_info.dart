class PageInfo {
  final String name;
  final String path;

  const PageInfo(this.name, this.path);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageInfo && runtimeType == other.runtimeType && name == other.name && path == other.path;

  @override
  int get hashCode => name.hashCode ^ path.hashCode;
}

