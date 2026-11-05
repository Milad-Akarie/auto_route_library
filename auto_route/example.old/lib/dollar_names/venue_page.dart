import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

// A page whose class and parameters are named with a `$`, each kind once: a
// plain argument, a path parameter and a query parameter.

@RoutePage()
class Venue$Page extends StatelessWidget {
  const new({
    super.key,
    this.venue$id,
    @PathParam() required this.user$id,
    @QueryParam() this.tab$name,
  });

  final String? venue$id;
  final String user$id;
  final String? tab$name;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Text(
      'user ${user$id}, venue ${venue$id ?? 'none'}, tab ${tab$name ?? 'none'}',
    ),
  );
}
