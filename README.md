# auto_route:

AutoRoute is a declartive routing solution, where everything needed for navigation is automatically generated for you.


---

- [Installation](#installation)
- [Setup and Usage](#setup-and-usage)
- [Customizing routes](#Customizing-routes)
- [Passing arguments to routes](#passing-arguments-to-routes)
- [Dynamic routing (path parameters)](#dynamic-routing-(path-parameters))
- [Extracting route parameters](#dynamic-routing-(path-parameters))
- [Hanlding unknown routes](#handling-unknown-routes)
- [Nested routes](#nested-routes)
- [Navigation](#navigation)
- [Route guards](#route-guards)
- [Handling wrapped routes](#handling-wrapped-routes)
- [Custom route transitions](#custom-route-transitions)
- [Migration guide](#migration-guide)

### Installation

```yaml
dependencies:
  auto_route: [latest-version]

dev_dependencies:
  auto_route_generator: [latest-version]
  build_runner:
```

### Setup and Usage

---

First create a router class and annotate it with @MaterialAutoRouter, @CupertinoAutoRouter, @AdaptiveAutoRouteror @CustomAutoRoute. It's name must be prefixed with **\$** to get a generated class with the same name minus the $.
$Router => Router

##### Note: using \$ prefix is mandatory.

```dart
@MaterialAutoRouter(...config)  //CustomAutoRoute(..config)
class $Router {}
```

#### Declare your AutoRoutes in MaterialAutoRouter() annotation

```dart
@MaterialAutoRouter(
  routes: <AutoRoute>[
    // intial route is named "/"
    MaterialRoute(page: HomeScreen, initial: true),
    MaterialRoute(page: UsersScreen, ..config),
  ],
)
class $Router {}
```

#### Now simply run the generator

Use the [watch] flag to watch the files system for edits and rebuild as necessary.

```terminal
flutter packages pub run build_runner watch
```

if you want the generator to run one time and exits use

```terminal
flutter packages pub run build_runner build
```

#### Finalize the setup

after you run the generator your router class will be generated

```dart

    MaterialApp(
    // Let MaterialApp use ExtendedNavigator instead of
    // the native one by assigning it to it's builder
     builder: ExtendedNavigator<Router>(router: Router()),

     // ExtendedNavigator is just a widget so you can still wrap it
     // with other widgets if you need to
     builder: (ctx, nativeNavigator) => Theme(
       data:...,
       child: ExtendedNavigator<Router>(router: Router())
     ,)
    );

```

##### Using the native navigator
**Note** Without ExtendedNavigator you will lose support for RouteGuards and auto-nested navigation handling.
```dart
     MaterialApp(
      // assign your generated Router directly to onGenerateRoute property
        onGenerateRoute: Router()
    );
```

#### Inside of the generated file

```dart
// a Routes class that holds all of your static route names
class Routes {
  static const String homeScreen = '/';
  static const String usersScreen = '/users-screen';
  static const all = <String>{
    homeScreen,
    usersScreen,
  };
}

class Router extends RouterBase {
  @override
  List<RouteDef> get routes => _routes;
  final _routes = <RouteDef>[
    RouteDef(Routes.homeScreen, page: HomeScreen),
    RouteDef(Routes.usersScreen, page: UsersScreen),
  ];
  @override
  Map<Type, AutoRouteFactory> get pagesMap => _pagesMap;
  final _pagesMap = <Type, AutoRouteFactory>{
    HomeScreen: (RouteData data) {
      return MaterialPageRoute<dynamic>(
        builder: (context) => HomeScreen(),
        settings: data,
      );
    },
    ...
 // Argument holder classes if exist ...
```

## Customizing routes
---
There are several avalaible auto-route types which you can customize
* MaterialRoute -> will generate a MaterialRoutePage
* CupertinoRoute -> will generate a CupertionRoutePage
* AdaptiveRoute -> will generate Cupertion or Material route page based on the Platform
* CustomRoute -> will generate a PageRouteBuilder with the provided Customizations

```dart
@MaterialAutoRouter(
  routes: <AutoRoute>[
    MaterialRoute(page: HomeScreen, initial: true, name: "IntialRoute"),
    CupertinoRoute(page: UsersScreen, fullscreenDialog: true),
    //This route returns result of type [bool]
    CustomRoute<bool>(page: LoginScreen, transitionsBuilder: TransitionsBuilders.fadeIn),
  ],
)
class $Router {}
```

#### Custom path names
AutoRoute automatically generates paths based on page type, for example the generated path for HomeScreen is "/home-screen". You properlly won't need to customize your paths unless your're building a web application.
To use a custom path name use the path property inside of AutoRoute
```dart
MaterialRoute(path: "/users", page: UsersScreen)
```

#### Available customizations

##### MaterialAutoRouter | CupertinoAutoRouter | AdaptiveAutoRouter

| Property                                 | Default value | Definition                                                                               |
| ---------------------------------------- | ------------- | ---------------------------------------------------------------------------------------- |
| generateNavigationHelperExtension [bool] | false         | if true a Navigator extenstion will be generated with helper push methods of all routes |
| routePrefix [String] |    ''     | all route paths will be prefixed with this routePrefix String |
| routesClassName [string] | 'Routes'         | the name of the generated Routes class |
#### CustomAutoRouter

| Property                        | Default value | Definition                                                                       |
| ------------------------------- | :-----------: | -------------------------------------------------------------------------------- |
| transitionsBuilder    |     null      | extension for the transitionsBuilder property in PageRouteBuilder                |
| opaque                   |     true      | extension for the opaque property in PageRouteBuilder                            |
| barrierDismissible       |     false     | extension for the barrierDismissible property in PageRouteBuilder                |
| durationInMilliseconds  |     null      | extension for the transitionDuration(millieSeconds) property in PageRouteBuilder |

#### MaterialRoute | CupertinoRoute | AdaptiveRoute | CustomRoute

| Property                | Default value | Definition                                                                                 |
| ----------------------- | :-----------: | ------------------------------------------------------------------------------------------ |
| initial          |     false     | mark the route as initial '\\'                                                             |
| path           |     null      | an auto generated path will be used if not provided|
| name           |     null      | this will be assigned to the route variable name  if provided and it will be used to name the route's nested Router if it has one (String homeScreen = [name]); |
| fullscreenDialog  |     false     | extension for the fullscreenDialog property in PageRoute                                   |
| maintainState    |     true      | extension for the maintainState property in PageRoute                                      |


#### CupertinoRoute Specific => CupertinoPageRoute

| Property       | Default value | Definition                                             |
| -------------- | :-----------: | ------------------------------------------------------ |
| title  |     null      | extension for the title property in CupertinoPageRoute |

#### CustomRoute Specific => PageRouteBuilder

| Property                        | Default value | Definition                                                                       |
| ------------------------------- | :-----------: | -------------------------------------------------------------------------------- |
| transitionsBuilder    |     null      | extension for the transitionsBuilder property in PageRouteBuilder                |
| opaque                  |     true      | extension for the opaque property in PageRouteBuilder                            |
| barrierDismissible       |     false     | extension for the barrierDismissible property in PageRouteBuilder                |
| durationInMilliseconds  |     null      | extension for the transitionDuration(millieSeconds) property in PageRouteBuilder |

## Passing aurguments to routes

---

##### That's the fun part!
You don't actually need to do anything extra. AutoRoute automatically detects your route parameters and handles them for you, it will automatically generate a class that holds your screen arguments and keep them typed.

```dart
class WelcomeScreen extends StatelessWidget {
  final String title;
  final String message;
  const WelcomeScreen({this.title = "Default Title",@required this.message});

  @override
  Widget build(BuildContext context)...
}
```

#### Generated arguments holder for the above example

- Default values are respected.
- Required fields are also respected and handled properly.

```dart
class WelcomeScreenArguments {
  final String title;
  final String message;
  // you're not going to lose your default values;
  WelcomeScreenArguments({this.title = "Default Title",@required this.message});
}
```

##### Pass your typed args using the generated arguments holder class

```dart
ExtendedNavigator.of(ctx).pushNamed(Router.welcomeScreenRoute,
    arguments: WelcomeScreenArguments(
        title: "Hello World!"
        message: "Let's AutoRoute!"
        )
    );
```

## Dynamic routing (Path parameters)
---
requires **AutoRoute: >= 0.6.0**
Define a dynamic segment by prefixing it with a colon
```dart
MaterialRoute(path: "/users/:id", page: UsersScreen);
```
Now pushing `users/1` will match `/users:id` and the path parameter `id` will be extracted and exposed in **RouteData**

##  Extracting route parameters
---
Extracted path parameters & queryParameters are bundled inside of an object called **RouteData** wihch you can get by calling `RouteData.of(context)` inside of the current route page.

```dart
class UsersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
   var routeData = RouteData.of(context)
    // .value will return the raw string value
     var userId = routeData.pathParams['id'].value;
     // .intValue will return a parsed int or null if parsing fails
   int userId = routeData.pathParams['id'].intValue;
   var queryParams = routeData.queryParams;
     ...
```
### isn't there a better way to extract route parameters? This doesn't feel very auto!
of course there is! simply annotate your constructor parameters with `@PathParam()` or `@QueryParam()` and let auto_route do the work for you
```dart
class UsersScreen extends StatefulWidget {
  const UsersScreen({
    @PathParam() this.id,
    // if your var name is different from the param name you
    // can pass it's expected name to the annotation
    // e.g [/users/1?filter=testers]
    @QueryParam('filter') this.filterFromQuery,
  });
 ```
 Generated code for UsersScreen
 ```dart
  MaterialPageRoute<dynamic>(
       builder: (context,) => UsersScreen(
       // auto_route will know the right type to parse the raw value to
       id: data.pathParams['id'].intValue,
       filterFromQuery: data.queryParams['filter'].stringValue)
```
**Note** constructor paramters annoated with `@PathParam()` or `@QueryParam` will not be considered as argument paramters and will be excluded from the generated argument class holder

## Hanlding unknown routes
---
requires **AutoRoute: >= 0.6.0**
#### Using a wildcard
AutoRoute 0.6.0 supports wildcard matching, you can simpley declare a wildcard at the end of your routes list to catch any undefined routes.
```dart
@MaterialAutoRouter(
  routes: <AutoRoute>[
    MaterialRoute(page: HomeScreen, initial: true),
    MaterialRoute(page: UsersScreen),
    // This should be at the end of your routes list
    // wildcards are represented by '*'
    MaterialRoute(path: "*", page: UnknownRouteScreen)
  ],
)
class $Router {}
```
#### Using the onUnknownRoute callback function in ExtendedNavigator
This function is called when the matcher fails to find a route to return, a defualt error page is returned if onUnkownRoute is not provided
```dart
ExtendedNavigator(
    router: Router(),
    onUnknownRoute:(RouteSettings settings){
        // return your Error page
    } ,
   ...
```


### Nested Routes
---
Declaring your nested routes inside of the parent route's children property will generate a nested router class called **UsersScreenRouter**, if you provide a custom name for the parent route the nested router name will be customName+Router

```dart
@MaterialAutoRouter(
  routes: <AutoRoute>[
    MaterialRoute(page: HomeScreen, initial: true),
    MaterialRoute(
      path: '/users:id',
      page: UsersScreen,
      children: <AutoRoute>[
        // path: '/' is the same as setting initial to true
        MaterialRoute(path: '/', page: ProfileScreen),
        MaterialRoute(path: '/posts', page: PostsScreen),
      ],
    ),
  ],
)
class $Router {}
```
Now we need to render these nested routes inside of their parent **UsersScreen** and for that we use a `NestedNavigator()`, this widget will build an ExtendedNavigator and provide it with the right router.
this's the same as using `<router-outlet>` in Angular or `<router-view>` in Vue.
```dart
class UsersScreen extends StatelessWidget {
  ...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Users Page")),
      // this navigator will obtain it's router
      // on it's own
      body: NestedNavigator(),
    );
  }
}
```

## Navigation
---
You can either use context to look up your Navigator in your widgets tree or without context,
by router or name.

 with context
 ```dart
ExtendedNavigator.of(context).pushNamed(..)
```
 by Router
```dart
ExtendedNavigator.ofRouter<Router>().pushNamed(..)
```
 by Name -> this's useful when using nested Navigators

```dart
// give your navigator a name
ExtendedNavigator(router: Router(), name: "root")
NestedNavigaotr(name: "nestedNav")
//call it by it's name
ExtendedNavigator.byName("nestedNav").pushNamed(..)
```
 if you're working with only one navigator
```dart
ExtenedNavigator.root.pushNamed(..)
```

### Navigation helper methods extension

to generate extension methods set the generateNavigationHelperExtension property inside of MaterialAutoRouter() to true

This will generate

```dart
extension RouterNavigationHelperMethods on ExtendedNavigatorState {
  Future pushHomeScreen() => pushNamed(Routes.homeScreen);
  Future<bool> pushSecondScreen(
          {@required String title, String message}) =>
      pushNamed<bool>(Routes.secondScreen,
          arguments: SecondScreenArguments(title: title, message: message));
}
```

Then use it like follows

```dart
ExtendedNavigator.of(context).pushSecondScreen(args...);
//or
ExtendedNavigator.ofRouter<Router>().pushSecondScreen(args...)
```


### Route guards

---

Implementing route guards requires a little bit of setup:

1. Create your route guard by extending RouteGuard from the autoRoute package

```dart
class AuthGuard extends RouteGuard {
 @override
 Future<bool> canNavigate(
     ExtendedNavigatorState navigator, String routeName, Object arguments) async {

   SharedPreferences prefs = await SharedPreferences.getInstance();
   return prefs.getString('token_key') != null;
 }
}
```

2.  Register the guards inside of ExtendedNavigator

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: ExtendedNavigator<Router>(
        router: Router(),
        guards: [AuthGuard()],
      ),
    );
  }
}
```

Finally assign the guards to the route you want to protect

```dart
 MaterialRoute(page: ProfileScreen, guards: [AuthGuard])
```

### Handling Wrapped Routes

---

To wrap your route with a parent widget like a Provider or such, simply implement AutoRouteWrapper, and let wrappedRoute(context) method return (this) as the child of your wrapper widget.

```dart
class ProductsScreen extends StatelessWidget implements AutoRouteWrapper {
  @override
  Widget wrappedRoute(BuildContext context) {
  return Provider(create: (ctx) => ProductsBloc(), child: this);
  ...

```

### Custom Route Transitions

---

To use custom Transitions use the @CustomRoute() annotation and pass in your preferences.
The TransitionsBuilder function needs to be passed as a static/const reference that has the same signature as the TransitionsBuilder Function of the PageRouteBuilder class.
The included **TransitionsBuilders** Class contains a preset of common Transitions builders

```dart
@CustomRoute(transitionsBuilder: TransitionBuilders.slideBottom,durationInMilliseconds: 400)
LoginScreen loginScreenRoute;
```

Use **@CustomAutoRouter()** to define global custom route Transitions.

You can of course use your own transitionsBuilder function as long as it has the same function signature.
The function has to take in exactly a BuildContext, Animation[Double], Animation[Double] and a child Widget and it needs to return a Widget, typically you would wrap your child with one of flutter's transition Widgets as follows.

```dart
Widget zoomInTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
 // you get an animation object and a widget
 // make your own transition
    return ScaleTransition(scale: animation, child: child);
  }
```

Now pass the reference of your function to @CustomRoute() annotation.

```dart
@CustomRoute(transitionsBuilder: zoomInTransition)
ZoomInScreen zoomInScreenRoute {}
```
## Migration guide
---
I apologyize for the good 5 to 10 minutes you're gonna lose rewriting your router class but it's for the greater good ;).

#### Migrating from auto_route <= 0.5.0
Basically instead of declaring our routes as class fields we're going to use a more readable and scalable way (a static routes list).

old way `<= 0.5.0`
```dart
@MaterialAutoRouter()
class $Router{
    @initial
    HomeScreen homeScreen;
}
```
new way `>= 0.6.0`
```dart
@MaterialAutoRouter(
routes:[
  MaterialRoute(page: HomeScreen, initial: true),
]
)
class $Router{}
```

##### Route Customization

old way `<= 0.5.0`
```dart
@MaterialAutoRouter()
class $Router{
    @CupertinoRoute(fullscreenDialog: true, returnType: bool)
    LoginScreen loginScreen;

    @CustomRoute(transationsBuilder: TranstionsBuilders.fadeIn)
    ProfileScreen profileScreen;
}
```
new way `>= 0.6.0`
```dart
@MaterialAutoRouter(
routes:[
  CupertinoRoute<bool>(page: LoginScreen, fullscreenDialog: true),
  CustomRoute(page: ProfileScreen, transationsBuilder: TranstionsBuilders.fadeIn)
 ],
)
class $Router{}
```

##### Route Guards

old way `<= 0.5.0`
```dart
@MaterialAutoRouter()
class $Router{
    @GuardedBy[AuthGuard]
    ProfileScreen profileScreen;
}
```
new way `>= 0.6.0`
```dart
@MaterialAutoRouter(
routes:[
  MaterialRoute(page: ProfileScreen, guards:[AuthGuard]),
 ],
)
class $Router{}
```

##### Custom UnknownRoute screen

old way `<= 0.5.0`
```dart
@MaterialAutoRouter()
class $Router{
    @unknownRoute
    UnknownRouteScreen unkownRoute;
}
```
new way `>= 0.6.0`
```dart
@MaterialAutoRouter(
routes:[
  ...
  // order is important here, this must be at the end of your routes list
  MaterialRoute(path: '*', page: UnknownRouteScreen),
 ],
)
class $Router{}
```

### Problems with the generation?

---

Make sure you always **Save** your files before running the generator, if that doesn't work you can always try to clean and rebuild.

```terminal
flutter packages pub run build_runner clean
```
### Support auto_route
You can support auto_route by liking it on Pub and staring it on Github, sharing ideas on how we can enhance a certain functinality or by reporting any problems you encounter
