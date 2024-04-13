// import 'package:auto_route/auto_route.dart';
// import 'package:vertex_auth/vertex_auth.dart';
// import 'package:auto_route/annotations.dart';

import 'index_2.dart';
import 'ui.dart';

// ignore_for_file: public_member_api_docs

@RoutePage(name: 'TestRoute')
class TestPage extends StatelessWidget {
  final Model model;
  TestPage({
    @PathParam.inherit('alias') String? query,
    Size? size,
    VoidCallback? onPop,
    required this.model,
    Key? key,
    // required this.model,
    // AuthState? state,
  });

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}
