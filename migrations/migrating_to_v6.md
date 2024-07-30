## Migrating to v6

In version 6.0 **AutoRoute** aims for less generated code for more flexibility and less generation time.

#### 1. Instead of using `MaterialAutoRouter`, `CupertinoAutoRouter`, etc,  we now only have one annotation for our router which is `@AutoRouterConfig()` and instead of passing our routes list to the annotation we now pass it to the overridable getter `routes` inside of the generated router class and for the default route type you can override `defaultRouteType`

#### Before

```dart
// @CupertinoAutoRouter
// @AdaptiveAutoRouter
// @CustomAutoRouter
@MaterialAutoRouter(
  routes: <AutoRoute>[
    // routes go here
  ],
)
class $AppRouter {}
```

#### After

 ```dart
@AutoRouterConfig()
class AppRouter extends $AppRouter {

  @override
  RouteType get defaultRouteType => RouteType.material(); //.cupertino, .adaptive ..etc

  @override
  List<AutoRoute> get routes => [
    // routes go here
  ];
}
```

#### 2. Passing page components as types is changed, now you'd annotate the target page with `@RoutePage()` annotation and pass the generated `result.page` to AutoRoute():

#### Before

```dart
class ProductDetailsPage extends StatelessWidget {}
```

```dart
AutoRoute(page: ProductDetailsPage) // as Type
```

#### After

```dart
@RoutePage() // Add this annotation to your routable pages
class ProductDetailsPage extends StatelessWidget {}
```

```dart
AutoRoute(page: ProductDetailsRoute.page) // ProductDetailsRoute is generated
```

#### 3. `EmptyRoutePage` no longer exists, instead you will now make your own empty pages by extending the `AutoRouter` widget

#### Before

```dart
AutoRoute(page: EmptyRoutePage, name: 'ProductsRouter') // as Type
```

#### After

```dart
@RoutePage(name: 'ProductsRouter')
class ProductsRouterPage extends AutoRouter {}
```

```dart
AutoRoute(page: ProductsRouter.page)
```

#### 4. Passing route guards is also changed now, instead of passing guards as types you now pass instances.

#### Before

```dart
AutoRoute(page: ProfilePage, guards:[AuthGuard]) // as Type
```

#### After

```dart
AutoRoute(page: ProfilePage, guards:[AuthGuard(<params>)]) // as Instance
```