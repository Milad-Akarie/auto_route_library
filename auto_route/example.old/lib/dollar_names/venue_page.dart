import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

// A page whose class and parameters are named with a `$`, each kind once: a
// plain argument, a path parameter and a query parameter.

/// A page whose class and parameter names contain a `$`.
///
/// Each kind of route argument appears once: a plain argument, a path parameter
/// and a query parameter.
@RoutePage()
class Venue$Page extends StatelessWidget {
  /// Only [user$id] is required.
  const new({
    @PathParam() required this.user$id,
    super.key,
    this.venue$id,
    @QueryParam() this.tab$name,
  });

  /// A plain route argument, `null` when not given.
  final String? venue$id;

  /// The path parameter of the route.
  final String user$id;

  /// The query parameter of the route, `null` when absent from the url.
  final String? tab$name;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Text(
      'user ${user$id}, venue ${venue$id ?? 'none'}, tab ${tab$name ?? 'none'}',
    ),
  );
}
