# auto_route:
AutoRoute is a route generation library, where everything needed for navigation is automatically generated for you.

---

### Installation
```yaml
dependencies:
# add auto_route to your dependencies
  auto_route:

dev_dependencies:
# add the generator to your dev_dependencies
  auto_route_generator:
# of course build_runner is needed to run the generator
  build_runner:
```


### Setup & Usage
First annotate your routes with @AutoRoute() or @initialRoute for the initial route.
**Note:** There can be only one initialRoute.
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

#####  Now simply Run the generator
Use the [watch] flag so the generator will run automatically every time you add or edit your annotated classes.
```terminal
flutter packages pub run build_runner watch
```

if you want the generator to run one time only use
```terminal
flutter packages pub run build_runner build
```
#####  Finalize the Setup
after you run the generator a Router class will be generated to lib/router.dart containing all of your route names and the onGenerateRoute function implementation.

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    // hook up the onGenerateRoute function in the generated Router class
    // with your Material app
      onGenerateRoute: Router.onGenerateRoute,
      // after you annotate your home page with @initialRoute
      // an initialRoute route name will be generated in the Router class
      // assign it to initialRoute in your MaterialApp
      initialRoute: Router.initialRoute,
    );
  }
}
```

### Inside of the Router class
```dart
class Router{
// A route name will be generated className+Route
// you can also provide a custom route name in the Annotation like so
// @AutoRoute(name:"customRouteName")
// it's a static String so you can use it later in your code like
// Navigator.of(ctx).pushNamed(Router.loginScreenRoute);

  static const loginScreenRoute = '/loginScreenRoute';

      static Route<dynamic> onGenerateRoute(RouteSettings settings) {
        switch (settings.name) {
        // The generated code for LoginScreen is
          case loginScreenRoute:
            return MaterialPageRoute(
              builder: (_) => LoginScreen(),
              settings: settings,
            );

          default:
          // autoRoute handles unknown routes for you
            return _unknownRoutePage(settings.name);
        }
      }
  }
```

### What about Route Parameters?
##### That's the fun part!
You don't actually need to do anything extra. AutoRoute automatically detects your route parameters and handles them for you, and because **Types** are important autoRoute will make sure you pass the right argument Type

```dart
@AutoRoute()
class ProductDetails extends StatelessWidget {
  final int productId;
// auto route will handle your route parameters based on
// your widget route constructor
  const ProductDetails(this.productId);
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

#### Generated code for the above example
```dart
 final args = settings.arguments;
  case productDetailsRoute:
   // ProductDetails screen is expecting a productId of type <int>
   // so we check the passed arguments against it
    if (_hasInvalidArgs<int>(args))
    // if the passed in args are mistyped, an error route page will be displayed instead
    return _misTypedArgsRoute<int>(args);
    // otherwise we navigate to the desired screen
    final typedArgs = args as int;
    return MaterialPageRoute(
      builder: (_) => ProductDetails(typedArgs),
      settings: settings,
    );
```

##### Passing multiple parameters (Don't worry, We're not using a dynamic Map!)
Since you can only pass one object argument in the Navigator, if you define more then one parameter in your screen constructor autoRoute will automatically generate a class that holds your screen arguments and keeps them strongly typed.
```dart
@AutoRoute()
class WelcomeScreen extends StatelessWidget {
  final String title;
  final String message;
  const WelcomeScreen({this.title = "Default Title", this.message});

  @override
  Widget build(BuildContext context)...
}
```
#### Generated code for the above example

```dart
//WelcomeScreen arguments holder class is generated
class WelcomeScreenArguments {
  final String title;
  final String message;
  // you're not going to lose your default values;
  WelcomeScreenArguments({this.title = "Default Title", this.message});
}

// then use the Arguments class holder as a type and check your passed args against it
 case welcomeScreenRoute:
        if (_hasInvalidArgs<WelcomeScreenArguments>(args))
          return _misTypedArgsRoute<WelcomeScreenArguments>(args);
        final typedArgs =
            args as WelcomeScreenArguments ?? WelcomeScreenArguments();
        return MaterialPageRoute(
          builder: (_) =>
              WelcomeScreen(title: typedArgs.title, message: typedArgs.message),
          settings: settings,
        );
```
#### Then Pass your strongly typed args like so
```dart
Navigator.of(ctx).pushNamed(Router.welcomeScreenRoute,
    arguments: WelcomeScreenArguments(
        title: "Hello World!"
        message: "Let's AutoRoute!"
        )
    );
```

### Custom route Transitions? Yes! please!
To use custom Transitions you need to pass a REFERENCE to a  TransitionBuilder function that has the same signature as the TransitionBuilder Function of the PageRoute class.
The included **TransitionBuilders** Class contains a preset of common Transitions builders
```dart
@AutoRoute(transitionBuilder: TransitionBuilders.slideBottom)
class LoginScreen extends StatelessWidget {}
 ```

You can of course use your own transitionBuilder function as long as it has the same function signture as in the function has to take in exactly a BuildContext, Animation<Double>, Animation<Double> and a child Widget and it needs to return a Widget,  typically you would wrap your child with one of flutter's transtion Widgets like so.
```dart
Widget zoomInTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
 // you get an animation object and a widget
 // make your own transition
    return ScaleTransition(scale: animation, child: child);
  }
````
Now pass the reference of your function to AutoRoute annotation "Just the name" like the below example.
Basically you're just telling the generator to use this function to build the route
```dart
@AutoRoute(transitionBuilder: zoomInTransition)
class ZoomInScreen extends StatelessWidget {}
```

###  Problems with the generation?
Make sure you always **Save** your files before running the generator
if that doesn't work you can always try to clean and rebuild.
```terminal
flutter packages pub run build_runner clean
```
