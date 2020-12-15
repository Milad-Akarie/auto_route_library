import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';

abstract class AutoRouterBuilderWidget extends StatelessWidget {
  Widget buildContent(BuildContext context, Widget child);
  @override
  Widget build(BuildContext context) {
    return AutoRouter(builder: buildContent);
  }
}
