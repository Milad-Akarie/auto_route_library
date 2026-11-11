import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// Page of a user, with a nested router for the profile and the posts.
@RoutePage()
class UserPage extends StatelessWidget {
  /// All arguments are optional.
  const new({
    super.key,
    @PathParam('userID') this.id = -1,
    @QueryParam() this.query,
    @urlFragment this.fragment,
  });

  /// The user id, taken from the `userID` path parameter; -1 when the url has
  /// none.
  final int id;

  /// The `query` values from the url, or `null` when there are none.
  final List<String>? query;

  /// The url fragment, or `null` when there is none.
  final String? fragment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      appBar: AppBar(
        leading: const AutoLeadingButton(),
        title: Builder(
          builder: (context) {
            return Text(
              '${context.topRouteMatch.name} $id query: '
              '${query ?? 'null'}, fragment: '
              '${fragment ?? 'null'}',
            );
          },
        ),
      ),
      body: const AutoRouter(),
    );
  }
}
