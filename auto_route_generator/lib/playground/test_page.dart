
import 'package:auto_route/auto_route.dart';
import 'package:vertex_auth/vertex_auth.dart';

import 'index_2.dart';
import 'ui.dart';

// ignore_for_file: public_member_api_docs
@RoutePage<Generice<List<String>>>()
class TestPage extends StatelessWidget {
  final Generice<DemoModel> model;
  TestPage({
    Key? key,
    required this.model,
    AuthState? state,
  });

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}