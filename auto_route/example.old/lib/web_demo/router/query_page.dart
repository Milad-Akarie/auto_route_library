import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// Page that shows its `id` path parameter; not part of any route.
class QueryPage extends StatelessWidget {
  /// Takes the [id] path parameter.
  const new({super.key, @pathParam this.id = '-'});

  /// The id from the path, `-` when the url has none.
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Query: $id')));
  }
}
