import 'package:collection/collection.dart';

final _exportParseRegex = RegExp("(export|part)\\s*['|\"](.*?)['|\"]\\s*(;|show|hide)\\s*(.*[^,;])?");

class ExportStatement {
  final Uri uri;
  final Set<String> show;
  final Set<String> hide;

  static ExportStatement? parse(String source) {
    final match = _exportParseRegex.matchAsPrefix(source);
    if (match == null) return null;
    final path = match.group(2);
    if (path == null) return null;
    if (match.group(0) == 'part') return ExportStatement(uri: Uri.parse(path));
    final show = match.group(3) == 'show' && match.group(4) != null
        ? match.group(4)!.split(',').map((e) => e.trim()).toSet()
        : <String>{};
    final hide = match.group(3) == 'hide' && match.group(4) != null
        ? match.group(4)!.split(',').map((e) => e.trim()).toSet()
        : <String>{};
    return ExportStatement(uri: Uri.parse(path), show: show, hide: hide);
  }

  ExportStatement({required this.uri, this.show = const {}, this.hide = const {}});

  bool shows(String identifier) => show.contains(identifier);

  bool hides(String identifier) => hide.contains(identifier);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExportStatement &&
        other.uri == uri &&
        const SetEquality().equals(other.show, other.show) &&
        const SetEquality().equals(other.hide, other.hide);
  }

  @override
  int get hashCode => uri.hashCode ^ const SetEquality().hash(show) ^ const SetEquality().hash(hide);

  @override
  String toString() {
    return 'ExportStatement{path: $uri, show: $show, hide: $hide}';
  }
}
