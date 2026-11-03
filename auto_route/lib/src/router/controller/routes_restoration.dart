part of 'routing_controller.dart';

// Saves the pages of every router for state restoration, and reads them back.
//
// Flutter's Router saves only the route information, so the pages are saved
// in its state: a list with one map per page, holding plain values the
// platform's codecs can write. 'name' is the route name, 'path' and 'query'
// its path and query params, 'fragment' its fragment, and 'children' the pages
// of its nested router. A tabs router lists all its tabs, the active one
// last. Route args are objects of the app, which can't be saved.
extension on RoutingController {
  List<Object?> _savedRoutes() {
    final pages = _pages.map((page) => page.routeData).toList();
    if (this case final TabsRouter tabs when tabs.activeIndex < pages.length) {
      pages.add(pages.removeAt(tabs.activeIndex));
    }
    return [for (final data in pages) _savedRoute(data)];
  }

  Map<String, Object?> _savedRoute(RouteData data) {
    final child = _innerControllerOfMatch(data.matchId);
    final List<Object?>? children;
    if (child != null) {
      // A declarative router builds its pages from the app's own state.
      children = child.managedByWidget ? null : child._savedRoutes();
    } else {
      // A nested router that isn't built yet holds its routes as pending children.
      children = [for (final match in data.pendingChildren) _savedMatch(match)];
    }
    // A route pushed on top shares its query params and fragment with the
    // pages under it, which keep the ones they were opened with apart.
    return _savedMatch(
      data.route,
      queryParams: data._ownQueryParams,
      fragment: data._ownFragment,
      children: children,
    );
  }
}

Map<String, Object?> _savedMatch(
  RouteMatch match, {
  Parameters? queryParams,
  String? fragment,
  List<Object?>? children,
}) {
  queryParams ??= match.queryParams;
  fragment ??= match.fragment;
  children ??= [for (final child in match.children ?? const <RouteMatch>[]) _savedMatch(child)];
  return {
    'name': match.name,
    if (match.params.isNotEmpty) 'path': _plainValues(match.params.rawMap),
    if (queryParams.isNotEmpty) 'query': _plainValues(queryParams.rawMap),
    if (fragment.isNotEmpty) 'fragment': fragment,
    if (children.isNotEmpty) 'children': children,
  };
}

Map<String, Object?> _plainValues(Map<String, dynamic> values) {
  Object? plain(Object? value) => switch (value) {
        null || String() || num() || bool() => value,
        Iterable() => [for (final item in value) plain(item)],
        _ => value.toString(),
      };
  return {for (final entry in values.entries) entry.key: plain(entry.value)};
}

// Reads back the routes saved by _savedRoutes; null if [saved] isn't such a list.
List<PageRouteInfo>? _restoredRoutes(Object? saved) {
  if (saved is! List) return null;
  final routes = <PageRouteInfo>[];
  for (final item in saved) {
    if (item is! Map) return null;
    final name = item['name'];
    final path = item['path'];
    final query = item['query'];
    final fragment = item['fragment'];
    final children = item['children'];
    if (name is! String ||
        (path != null && path is! Map) ||
        (query != null && query is! Map) ||
        (fragment != null && fragment is! String)) {
      return null;
    }
    final restoredChildren = children == null ? null : _restoredRoutes(children);
    if (children != null && restoredChildren == null) return null;
    routes.add(PageRouteInfo(
      name,
      rawPathParams: path == null ? const {} : Map<String, dynamic>.from(path as Map),
      rawQueryParams: query == null ? const {} : Map<String, dynamic>.from(query as Map),
      fragment: fragment as String?,
      initialChildren: restoredChildren,
    ));
  }
  return routes;
}
