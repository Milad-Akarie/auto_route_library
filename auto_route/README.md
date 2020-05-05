# auto_route:

AutoRoute is a route generation library, where everything needed for navigation is automatically generated for you.


---

- [Installation](#installation)
- [Setup and Usage](#setup-and-usage)
- [Navigation](#navigation)
- [Customization](#customization)
- [Passing Arguments to Routes](#passing-arguments-to-routes)
- [Nested Navigators](#nested-navigators)
- [Route guards](#route-guards)
- [Handling Wrapped Routes](#handling-wrapped-routes)
- [Custom Route Transitions](#custom-route-transitions)

### Installation

```yaml
dependencies:
  # add auto_route to your dependencies
  auto_route: [latest-version]

dev_dependencies:
  # add the generator to your dev_dependencies
  auto_route_generator: [latest-version]
  # of course build_runner is needed to run the generator
  build_runner:
```

### Setup and Usage

---

First create a router config class then annotate it with @MaterialAutoRouter, @CupertinoAutoRoute or @CustomAutoRoute. It's name must be prefixed with **\$** to get a generated class with the same name minus the $.  
$Router => Router

##### Note: using \$ prefix is mandatory.

```dart
@MaterialAutoRouter(...config)  //CustomAutoRoute(..config)
class $Router {

}
```

#### Now start adding your routes as class fields with the desired route names:

**Only use the @MaterialRoute() or @CupertinoRoute() annotations to customize your route**

```dart
@MaterialAutoRouter()
class $Router {
 // use @initial or @CupertinoRoute(initial: true) to annotate your initial route.
  @initial
  HomeScreen homeScreenRoute; // your desired route name

  SecondScreen secondScreenRoute;

  //optional route Customization
  @CupertinoRoute(fullscreenDialog: true)
  LoginScreen loginScreenRoute;
}
```

#### Next simply Run the generator

Use the [watch] flag to watch the files system for edits and rebuild as necessary.

```terminal
flutter packages pub run build_runner watch
```

if you want the generator to run one time and exits use

```terminal
flutter packages pub run build_runner build
```

#### Finalize the Setup

after you run the generator your router class will be generated containing all of your route names and the onGenerateRoute function implementation.

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    // Tell MaterialApp to use our ExtendedNavigator instead of
    // the native one by assigning it to it's builder
    // instead of return the nativeNavigator we're returning our ExtendedNavigator
     builder: ExtendedNavigator<Router>(router: Router()),
     // ExtendedNavigator is just a widget so you can still wrap it with other widgets
     builder: (ctx, nativeNavigator) => Theme(data:...,
     child: ExtendedNavigator<Router>(router: Router())
     ,)
    );
  }
}
```

#### Inside of the Generated file

```dart
// a Routes class that holds all of your static route names
abstract class Routes {
  static const homeScreen = '/';
  static const secondScreen = '/second-screen';
}
// the onGenerateRoute function implementation
class Router extends RouterBase{
      @override
      Route<dynamic> onGenerateRoute(RouteSettings settings) {
        switch (settings.name) {
        // The generated code for LoginScreen is
          case Routes.loginScreenRoute:
            return CupertinoPageRoute<dynamic>(
              builder: (_) => LoginScreen(),
              settings: settings,
              fullscreenDialog: true
            );

          default:
          // autoRoute handles unknown routes for you
            return unknownRoutePage(settings.name);
        }
 } }

 // Argument holder classes if exist ...
```

## Navigation

You can either use context to look up your Navigator in your widgets tree or without context,
using ExtendedNavigator.ofRouter<yourRouter>()

```dart
// with context
ExtendedNavigator.of(context).pushNamed(Routes.secondScreen)
// without context
ExtendedNavigator.ofRouter<Router>().pushNamed(Routes.secondScreen)
// or if you're working with only one navigator
ExtenedNavigator.rootNavigator.pushNamed(..)
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

### Customization

---

##### MaterialAutoRouter | CupertinoAutoRouter | AdaptiveAutoRouter

| Property                                 | Default value | Definition                                                                               |
| ---------------------------------------- | ------------- | ---------------------------------------------------------------------------------------- |
| generateRouteList [bool]                 | false         | if true a list of all routes will be generated                                           |
| generateNavigationHelperExtension [bool] | false         | if true a Navigator extenstion will be generated with helper push methods of all routes |
| generateArgsHolderForSingleParameterRoutes [bool] | true         | if true argument holder classes will always be generated for routes with parameters |
| routePrefix [String] |    ''     | all route paths will be prefixed with this routePrefix String |
| routesClassName [string] | 'Routes'         | the name of the generated Routes class |
#### CustomAutoRouter

| Property                        | Default value | Definition                                                                       |
| ------------------------------- | :-----------: | -------------------------------------------------------------------------------- |
| transitionsBuilder [Function]   |     null      | extension for the transitionsBuilder property in PageRouteBuilder                |
| opaque [bool]                   |     true      | extension for the opaque property in PageRouteBuilder                            |
| barrierDismissible [bool]       |     false     | extension for the barrierDismissible property in PageRouteBuilder                |
| durationInMilliseconds [double] |     null      | extension for the transitionDuration(millieSeconds) property in PageRouteBuilder |

#### MaterialRoute | CupertinoRoute | AdaptiveRoute | CustomRoute

| Property                | Default value | Definition                                                                                 |
| ----------------------- | :-----------: | ------------------------------------------------------------------------------------------ |
| initial [bool]          |     false     | mark the route as initial '\\'                                                             |
| name [String]           |     null      | this will be assigned to the route variable name if provided (String homeScreen = [name]); |
| fullscreenDialog [bool] |     false     | extension for the fullscreenDialog property in PageRoute                                   |
| maintainState [bool]    |     true      | extension for the maintainState property in PageRoute                                      |

#### CupertinoRoute Specific => CupertinoPageRoute

| Property       | Default value | Definition                                             |
| -------------- | :-----------: | ------------------------------------------------------ |
| title [String] |     null      | extension for the title property in CupertinoPageRoute |

#### CustomRoute Specific => PageRouteBuilder

| Property                        | Default value | Definition                                                                       |
| ------------------------------- | :-----------: | -------------------------------------------------------------------------------- |
| transitionsBuilder [Function]   |     null      | extension for the transitionsBuilder property in PageRouteBuilder                |
| opaque [bool]                   |     true      | extension for the opaque property in PageRouteBuilder                            |
| barrierDismissible [bool]       |     false     | extension for the barrierDismissible property in PageRouteBuilder                |
| durationInMilliseconds [double] |     null      | extension for the transitionDuration(millieSeconds) property in PageRouteBuilder |

#### unkownRoute

Marks route as a custome route-not-found page. There can be only one unknown route per Router.

### Passing Arguments to Routes

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

#### Generated code for the above example

- Default values are respected.
- Required fields are also respected and handled properly.

```dart
//WelcomeScreen arguments holder class is generated
class WelcomeScreenArguments {
  final String title;
  final String message;
  // you're not going to lose your default values;
  WelcomeScreenArguments({this.title = "Default Title",@required this.message});
}

 case Routes.welcomeScreenRoute:
      // if your class holder contains at least one required field the whole argument class is considered required and can not be null
        if (hasInvalidArgs<WelcomeScreenArguments>(args,isRequired: true))
          return misTypedArgsRoute<WelcomeScreenArguments>(args);
        final typedArgs =
            args as WelcomeScreenArguments ?? WelcomeScreenArguments();
        return MaterialPageRoute<dynamic>(
          builder: (_) =>
              WelcomeScreen(title: typedArgs.title, message: typedArgs.message),
          settings: settings,
        );
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

Note: if you don't want auto_route to generate arguments holder class for single parameter routes set
generateArgsHolderForSingleParameterRoutes to false in AutoRouter()

### Nested Navigators

Create your nested router class and define your routes as before.

```dart
@MaterialAutoRouter()
class $MyNestedRouter {
  @initial
  NestedHomePage nestedHomePage;
  NestedSecondPage nestedSecondPage;
}
```

##### Hook up your nested router with an ExtendedNavigator widget

```dart
 ExtendedNavigator<MyNestedRouter>(router: MyNestedRouter()),
```

And That's that! Now use your nested router's navigator to navigate within your nested navigator as follows

```dart
// inside of widgets below your nested ExtendedNavigator()
ExtendedNavigator.of(context).pushNamed(...)
// or without context
ExtendedNavigator.ofRouter<MyNestedRouter>.pushNamed(...)
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

2.  Register your guards
    pass your guards to the guards property inside of ExtendedNavigator

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

3.  Annotated the routes you want to guard with @GuardedBy([..guards]) and pass in your guards as types.

```dart
 @GuardedBy([AuthGuard])
 ProfileScreen profileScreen;
```

### Handling Wrapped Routes

---

To wrap your route with a parent widget like a Provider or such, simply implement AutoRouteWrapper, and let wrappedRoute(context) method return (this) as the child of your wrapper widget.

```dart
class ProductsScreen extends StatelessWidget implements AutoRouteWrapper {
  @override
  Widget wrappedRoute(BuildContext context) => Provider(create: (ctx) => ProductsBloc(), child: this);
  ...
  }
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

### Resources

---

- [Lean how to setup and use auto_route with this well made tutorial by Reso Coder](https://www.youtube.com/watch?v=iVpVBmDhpJY&t=505s)

### Acknowledgements

---

Thanks to **Peter Leibiger** for his valuable advice.

### Problems with the generation?

---

Make sure you always **Save** your files before running the generator, if that doesn't work you can always try to clean and rebuild.

```terminal
flutter packages pub run build_runner clean
```
