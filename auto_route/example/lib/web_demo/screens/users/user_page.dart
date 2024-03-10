//ignore_for_file: public_member_api_docs
import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/widgets/router_app_bar.dart';
import 'package:flutter/material.dart';

@RoutePage()
class UserPage extends StatefulWidget {
  final int id;
  final List<String>? query;

  UserPage({
    Key? key,
    @PathParam('userID') this.id = -1,
    @QueryParam() this.query,
  }) : super(key: key);

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      appBar: RouterAppBar(
        title: Builder(
          builder: (context) {
            return Text(context.topRouteMatch.name + ' ${widget.id} query: ${widget.query}');
          },
        )
      ),
      body: AutoRouter(),
    );
  }
}