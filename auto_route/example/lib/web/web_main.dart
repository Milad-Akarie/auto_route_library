import 'package:example/web/router/web_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(App());
}

class App extends StatefulWidget {
  @override
  AppState createState() => AppState();

  static AppState of(BuildContext context) {
    return context.findAncestorStateOfType<AppState>()!;
  }
}

class AppState extends State<App> {
  final _appRouter = WebAppRouter();
  var loggedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      routeInformationProvider: _appRouter.routeInfoProvider(),
      routerDelegate: _appRouter.delegate(
          // routes: (_) => [
          //   if (loggedIn)
          //     UserRoute(id: 1)
          //   else
          //     LoginRoute(onLoginResult: (_) {
          //       setState(() {
          //         loggedIn = true;
          //       });
          //     })
          // ],
          ),
      routeInformationParser: _appRouter.defaultRouteParser(),
    );
  }
}

class LoginPage extends StatelessWidget {
  final void Function(bool isLoggedIn)? onLoginResult;

  const LoginPage({Key? key, this.onLoginResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Login to continue'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              // context.read<AuthService>().isAuthenticated = true;
              onLoginResult?.call(true);
            },
            child: Text('Login'),
          ),
        ),
      ),
    );
  }
}
