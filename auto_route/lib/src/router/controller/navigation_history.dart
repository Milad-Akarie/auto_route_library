import 'package:auto_route/auto_route.dart';

class NavigationHistory {
  final entries = <RouteMatch>[];

  bool get canNavigateBack => entries.length > 1;

  RouteMatch get currentEntry => entries.last;

  void removeLast() => entries.removeLast();

  void add(List<RouteMatch> flatSegments) {
    if (flatSegments.isEmpty) return;

    RouteMatch toHierarchy(List<RouteMatch> segments) {
      if (segments.length == 1) {
        return segments.first;
      } else {
        return segments.first.copyWith(children: [
          toHierarchy(
            segments.sublist(1, segments.length),
          ),
        ]);
      }
    }

    final entry = toHierarchy(flatSegments);

    final entryIndex = entries.lastIndexWhere((e) => e == entry);
    if (entryIndex != -1) {
      entries.removeRange(entryIndex, entries.length);
    }
    entries.add(entry);
    print('------------------');
    entries.forEach((element) {
      print(element.allSegments.join('/'));
    });
  }
}
