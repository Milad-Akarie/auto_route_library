import 'package:auto_route/auto_route.dart' show RoutePage;
import 'package:vertex_auth/vertex_auth.dart';

import 'index_2.dart';
import 'ui.dart';

// ignore_for_file: public_member_api_docs
@RoutePage<Generice<List<String>>>()
class TestPage3 extends StatelessWidget {
  final Generice model;

  TestPage3({
    super.key,
    required this.model,
    AuthState? state,
  });

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}
