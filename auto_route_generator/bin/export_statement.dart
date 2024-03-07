final _exportParseRegex = RegExp("export\\s*['|\"](.*?)['|\"]\\s*(;|show|hide)\\s*(.*[^,;])?");

class ExportStatement {
  final Uri uri;
  final Set<String> show;
  final Set<String> hide;

  static ExportStatement? parse(String source) {
    final match = _exportParseRegex.matchAsPrefix(source);
    if (match == null) return null;
    final path = match.group(1);
    final show = match.group(2) == 'show' && match.group(3) != null
        ? match.group(3)!.split(',').map((e) => e.trim()).toSet()
        : <String>{};
    final hide = match.group(2) == 'hide' && match.group(3) != null
        ? match.group(3)!.split(',').map((e) => e.trim()).toSet()
        : <String>{};
    return ExportStatement(uri: Uri.parse(path!), show: show, hide: hide);
  }

  ExportStatement({required this.uri, this.show = const {}, this.hide = const {}});

  bool shows(String identifier) => show.contains(identifier);

  bool hides(String identifier) => hide.contains(identifier);

  @override
  String toString() {
    return 'ExportStatement{path: $uri, show: $show, hide: $hide}';
  }
}
