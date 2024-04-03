// import 'package:auto_route/auto_route.dart';
// import 'package:vertex_auth/vertex_auth.dart';
import 'package:auto_route/annotations.dart';
// import 'ui.dart';
import 'package:flutter/material.dart';

import 'model_index.dart';
// ignore_for_file: public_member_api_docs

@RoutePage(name: 'TestRoute')
class TestPage extends StatelessWidget {
  final Generice model;
  DemoModel? demoModel;
  TestPage({
    @PathParam.inherit('alias') String? query,
    Size? key,
    // required this.model,
    // AuthState? state,
  });

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}
