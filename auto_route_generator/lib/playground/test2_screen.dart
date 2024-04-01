import 'package:auto_route/auto_route.dart' show RoutePage;
import 'package:vertex_auth/vertex_auth.dart';

import 'model.dart';
import 'ui.dart';

// ignore_for_file: public_member_api_docs
@RoutePage<Generice<List<String>>>()
class TestPage2 extends StatelessWidget {
  final Generice model;
  final AuthState? statex;

  TestPage2({
    Key? key,
    required this.model,
    this.statex,
    AuthState? state,
    ValueChanged<AuthState>? onAuthStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TestffffPage2'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('TestPage2'),
            ElevatedButton(
              onPressed: () {},
              child: Text('Go to TestPage3'),
            ),
          ],
        ),
      ),
    );
  }
}
