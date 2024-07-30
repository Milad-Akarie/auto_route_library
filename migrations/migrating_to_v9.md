## Migrating to v9

#### 1. You now need to extend `RootStackRouter` from the `auto_route` package instead of the generated `$YOUR_APP_NAME`.

#### Before

```dart
  
@AutoRouterConfig()
class AppRouter extends $AppRouter {

  @override
  List<AutoRoute> get routes => [
    /// routes go here
  ];
}
```
#### After

```dart
  
@AutoRouterConfig()
class AppRouter extends RootStackRouter {

  @override
  List<AutoRoute> get routes => [
    /// routes go here
  ];
}
```

#### 2. You no longer need to provide the return type of a page inside `@RoutePage<RETURN_TYPE>()` instead provide the return type as you push your page. 

#### Before

```dart
@RoutePage<bool>()
class LoginPage extends StatelessWidget {}

```

```dart
 /// pushing the route
bool didLogin = await context.pushRoute<bool>();
```

#### After

```dart
/// provide the return type as you push your page
 bool didLogin = await context.pushRoute<bool>();
```

#### 3. Global guards are now provided as a list of `AutoRouteGuard` instead implementing `AutoRouteGuard` directly.

#### Before

```dart
@AutoRouterConfig()
class AppRouter extends $AppRouter implements AutoRouteGuard {

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
     /// guard logic
  }
 
}
```
#### After

```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter{
  
  final authGuard = AuthGuard();
  
  @override
  late final List<AutoRouteGuard> guards = [
    authGuard, ///add  guard instance
  ///
   /// or use a simple guard wrapper
    AutoRouteGuard.simple((resolver, router) {
        /// guard logic
    ),
        
  ];
}
```

#### 4. AutoRouterConfig.module is no longer used, generated `PageRouteInfos` are now self-sufficient. they contain the page builder inside `PageRouteInfo.page`. 
What you do now is generated the routes inside the micro package like normal, then either use the generated routes inside your main router individually,
or declare them inside your micro router then merge them with the main router. 

#### Before
```dart
@AutoRouterConfig.module()
class MyPackageModule extends $MyPackageModule {}
```
```dart
@AutoRouterConfig(modules: [MyPackageModule])
class AppRouter extends $AppRouter {}
```

#### After

```dart
/// normal auto router config
@AutoRouterConfig()
class MyMicroRouter extends RootStackRouter{}
```

```dart
  final myMicroRouter = MyMicroRouter();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: HomeRoute.page, initial: true),
        /// use micro routes individually
        AutoRoute(page: RouteFromMicroPackage.page),
        /// or merge all routes from micro router
        ...myMicroRouter.routes,
      ];
```