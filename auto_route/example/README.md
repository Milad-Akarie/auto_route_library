```dart

class HomeScreen extends StatelessWidget{}

class LoginScreen extends StatelessWidget {}

@MaterialAutoRouter(
  routes: <AutoRoute>[
    AutoRoute(page: HomeScreen, initial: true),
    AutoRoute( page: LoginScreen, fullscreenDialog: true),
  ],
)
class $AppRouter {}
```