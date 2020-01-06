
# auto_route:  
AutoRoute is a route generation library, where everything needed for navigation is automatically generated for you.  
  
---  
  
* [Installation](#installation)  
* [Setup and Usage](#setup-and-usage)  
* [Passing Arugments to Routes](#passing-arugments-to-routes)  
* [Navigating Using a Global Navigator Key aka Navigating Without Context](#navigating-using-a-global-navigator-key-aka-navigating-without-context)  
*  [Handling Wrapped Routes](#handling-wrapped-routes)  
* [Nested Navigators](#nested-navigators)  
* [Custom Route Transitions](#custom-route-transitions)  
  
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
  
### Setup and Usage  
  ---
First create a router config class then annotate it with @autoRouter and prefix it's name with **\$** to get a generated class with the desired name minus the $.  
$Router => Router  
##### Note: using \$ prefix is mandatory.  
  
```dart  
@autoRouter  
class $Router {  
  
}  
```  
  
Now start adding your routes as class fields with the desired route names:  
##### You don't have to annotate very single route with @MaterialRoute() or @CupertinoRoute()
  
```dart  
@autoRouter  
class $Router {  
 // use @initial or @CupertinoRoute(initial: true) to annotate your initial route.  
  @initial  
  HomeScreen homeScreenRoute; // your desired route name  
  
  SecondScreen secondScreenRoute;  
  
  //only use the @MaterialRoute() or @CupertinoRoute() annotations to customize your route  
  @CupertinoRoute(fullscreenDialog: true)  
  LoginScreen loginScreenRoute;  
}  
```  
  
#### Now simply Run the generator  
  
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
    // hook up the onGenerateRoute function in the generated Router class  
    // with your Material app  
      onGenerateRoute: MyRouter.onGenerateRoute,  
      // optional  
      initialRoute: MyRouter.homeScreenRoute,  
    );  
  }  
}  
```  
  
#### Inside of the Generated class  
  
```dart  
class Router{  
   // your route names will be generated as static const Strings  
  static const loginScreenRoute = '/loginScreenRoute';  
  
      static Route<dynamic> onGenerateRoute(RouteSettings settings) {  
        switch (settings.name) {  
        // The generated code for LoginScreen is  
          case Router.loginScreenRoute:  
            return CupertinoPageRoute(  
              builder: (_) => LoginScreen(),  
              settings: settings,  
              fullscreenDialog: true  
            );  
  
          default:  
          // autoRoute handles unknown routes for you  
            return unknownRoutePage(settings.name);  
        }  
 } }
 ```   
### Passing Arugments to Routes  
----
  
##### That's the fun part!  
  
You don't actually need to do anything extra. AutoRoute automatically detects your route parameters and handles them for you, and because **Types** are important it will make sure you pass the right argument Type  
  
```dart  
class ProductDetails extends StatelessWidget {  
  final int productId;  
// your route parameters are handled based on  
// your widget route constructor  
  const ProductDetails(this.productId);  
  @override  
  Widget build(BuildContext context)...  
}  
```  
  
#### Generated code for the above example  
  
```dart  
 final args = settings.arguments;  
  case Router.productDetailsRoute:  
   // ProductDetails screen is expecting a productId of type <int>  
   // so we check the passed arguments against it  
    if (hasInvalidArgs<int>(args))  
    // if the passed in args are mistyped, an error route page will be displayed instead  
    return misTypedArgsRoute<int>(args);  
    // otherwise we navigate to the desired screen  
    final typedArgs = args as int;  
    return MaterialPageRoute(  
      builder: (_) => ProductDetails(typedArgs),  
      settings: settings,  
    );  
```  
  
#### Passing multiple arguments (Don't worry, We're not using a dynamic Map!)  
  
Since you can only pass one argument to the Navigator, if you define more then one parameter in your screen constructor autoRoute will automatically generate a class that holds your screen arguments and keep them typed.  
  
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
  
 case Router.welcomeScreenRoute:  
      // if your class holder contains at least one required field the whole argument class is considered required and can not be null  
        if (hasInvalidArgs<WelcomeScreenArguments>(args,isRequired: true))  
          return misTypedArgsRoute<WelcomeScreenArguments>(args);  
        final typedArgs =  
            args as WelcomeScreenArguments ?? WelcomeScreenArguments();  
        return MaterialPageRoute(  
          builder: (_) =>  
              WelcomeScreen(title: typedArgs.title, message: typedArgs.message),  
          settings: settings,  
        );  
```  
  
#####  Pass your typed args using the generated arguments holder class  
  
```dart  
Navigator.of(ctx).pushNamed(Router.welcomeScreenRoute,  
    arguments: WelcomeScreenArguments(  
        title: "Hello World!"  
        message: "Let's AutoRoute!"  
        )  
    );  
```  
  
### Navigating Using a Global Navigator Key aka Navigating Without Context  
  
Simply assign MyRouter.navigatorKey to the MaterialApp property "navigatorKey" as follows  
  
```dart  
  MaterialApp(  
      onGenerateRoute: MyRouter.onGenerateRoute,  
      // hook up the navigatorKey  
      navigatorKey: MyRouter.navigatorKey,  
    );  
}  
```  
  
#### Now use the navigator inside of MyRouter any where in your app.  
  ---
```dart  
MyRouter.navigator.pushNamed(MyRouter.secondScreen);  
```  


### Nested Navigators  
  
Create your nested router class and define your routes as before.  
  
```dart  
@autoRouter  
class $MyNestedRouter {  
  @initial  
  NestedHomePage nestedHomePage;  
  NestedSecondPage nestedSecondPage;  
}  
```  
  
##### Hook up your nested navigator with the Generated Router class  
  
```dart  
 Navigator(  
          key: MyNestedRouter.navigatorKey,  
          onGenerateRoute: MyNestedRouter.onGenerateRoute),  
```  
  
And That's that! Now use your nested router's navigator to navigate within your nested navigator as follows  
  
```dart  
MyNestedRouter.navigator.pushNamed("your Nested route")  
```  
### Handling Wrapped Routes  
---
To wrap your route with a parent widget  like a Provider or such, simply implement  AutoRouteWrapper, and let  wrappeRoute accessor return (this) as the child of your wrapper widget. 
```dart  
class ProductsScreen extends StatelessWidget implements AutoRouteWrapper {  
  @override  
  Widget get wrappedRoute => Provider(create: (ctx) => ProductsBloc(), child: this);
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
  
You can of course use your own transitionsBuilder function as long as it has the same function signature.  
The function has to take in exactly a BuildContext, Animation<Double>, Animation<Double> and a child Widget and it needs to return a Widget, typically you would wrap your child with one of flutter's transtion Widgets as follows.  
  
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
  
### Problems with the generation?  
  ---
Make sure you always **Save** your files before running the generator, if that doesn't work you can always try to clean and rebuild.  
  
```terminal  
flutter packages pub run build_runner clean  
```