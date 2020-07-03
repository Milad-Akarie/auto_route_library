```dart

class HomeScreen extends StatelessWidget{}

class LoginScreen extends StatelessWidget {}

@MaterialAutoRouter(
  routes: <AutoRoute>[
    MaterialRoute(page: HomeScreen, initial: true),
    MaterialRoute( page: LoginScreen, fullscreenDialog: true),
  ],
)
class $Router {}
```
