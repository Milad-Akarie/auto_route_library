```dart
@AutoRoute()
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

// use @InitialRoute() or @initialRoute to annotate the initial route.
@initialRoute
class HomeScreen extends StatelessWidget {}
```