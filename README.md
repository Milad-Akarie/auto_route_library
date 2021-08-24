    
<p align="center">    
<img  src="https://raw.githubusercontent.com/Milad-Akarie/auto_route_library/master/art/auto_route_logo.svg" height="170">    
</p>    
    
<p align="center">    
<a href="https://img.shields.io/badge/License-MIT-green"><img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License"></a>    
<a href="https://github.com/Milad-Akarie/auto_route_library/stargazers"><img src="https://img.shields.io/github/stars/Milad-Akarie/auto_route_library?style=flat&logo=github&colorB=green&label=stars" alt="stars"></a>    
<a href="https://pub.dev/packages/auto_route/versions/2.0.0"><img src="https://img.shields.io/badge/pub-2.2.0-orange" alt="pub version"></a>    
<a href="https://discord.gg/x3SBU4WRRd">    
 <img src="https://img.shields.io/discord/821043906703523850.svg?color=7289da&label=Discord&logo=discord&style=flat-square" alt="Discord Badge"></a>    
</p>    
    
<p align="center">  
<a href="https://www.buymeacoffee.com/miladakarie" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="30px" width= "108px"></a>  
</p>  
  
---  
**for more docs with examples** https://autoroute.vercel.app    
  
- [Introduction](#introduction)    
- [Installation](#installation)    
- [Setup and Usage](#setup-and-usage)    
- [Generated routes](#generated-routes)    
- [Navigation](#navigating-between-screens)
  - [Navigating Between Screens](#navigating-between-screens)
  - [Passing Arguments](#passing-arguments) 
  - [Returning Results](#returning-results)
  - [Nested navigation](#nested-navigation)     
- [Working with Paths](#working-with-paths)    
- [Finding The Right Router](#finding-the-right-router) 
- [Route guards](#route-guards)
- [Wrapping routes](#wrapping-routes)
- [Customization](#customization)
  - [Custom Route Transitions](#custom-route-transitions)   
  - [Custom Route Builder](#custom-route-builder)
  
    
## Introduction 
#### What is AutoRoute? 
It’s a Flutter navigation package, it allows for strongly-typed arguments passing, effortless deep-linking and it uses code generation to simplify routes setup, with that being said it requires a minimal amount of code to generate everything needed for navigation inside of your App.    
#### Why AutoRoute?
 If your App requires deep-linking or guarded routes or just a clean routing setup you'll need to use named/generated routes and you’ll end up writing a lot of boilerplate code for mediator argument classes, checking for required arguments, extracting arguments and a bunch of other stuff. AutoRoute does all that for you and much more.    
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
 Create a placeholder class and annotate it with `@MaterialAutoRouter` which takes a list of routes as a required argument.    
**Note**: The name of the router must be prefixed with **\$** so we have a  generated class with the same name minus the **$**.    
    
```dart    
    
// @CupertinoAutoRouter    
// @AdaptiveAutoRouter    
// @CustomAutoRouter    
@MaterialAutoRouter(    
  replaceInRouteName: 'Page,Route',    
  routes: <AutoRoute>[    
    AutoRoute(page: BookListPage, initial: true),    
    AutoRoute(page: BookDetailsPage),    
  ],    
)    
class $AppRouter {}    
```    
*Tip: You can Shorten auto-generated route names from e.g. **BookListPageRoute** to **BookListRoute** using the replaceInRouteName argument.*    
 #### Now simply run the generator    
 Use the [watch] flag to watch the files' system for edits and rebuild as necessary.    
    
```terminal    
flutter packages pub run build_runner watch    
```    
    
if you want the generator to run one time and exits use    
    
```terminal    
flutter packages pub run build_runner build    
```    
    
#### Finalize the setup    
 after you run the generator your router class will be generated, hook it up with MaterialApp.    
```dart    
class App extends StatelessWidget {
  // make sure you don't initiate your router
  // inside of the build function.
  final _appRouter = AppRouter();

  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: AutoRouterDelegate(_appRouter),
      // or
      // routerDelegate:_appRouter.delegate(),    
      routeInformationParser: _appRouter.defaultRouteParser(),
    );
  }
} 
```    
## Generated Routes  
 A `PageRouteInfo` object will be generated for every declared AutoRoute, These objects hold path information plus strongly-typed page arguments which are extracted from the page's default constructor. Think of them as string path segments on steroid.
```dart    
class BookListRoute extends PageRouteInfo {    
  const BookListRoute() : super(name, path: '/books');    
    
  static const String name = 'BookListRoute';    
}    
```    
if the declared route has children AutoRoute will add a children parameter to its constructor to be used in nested navigation. more on that here.    
    
```dart    
class UserRoute extends PageRouteInfo {    
   UserRoute({List<PagerouteInfo> children}) :    
    super(    
         name,     
         path: '/user/:id',    
         initialChildren: children);    
  static const String name = 'UserRoute';    
}    
```    
    
## Navigating Between Screens
`AutoRouter` offers the same known push, pop and friends methods to manipulate the pages stack using both the generated `PageRouteInfo` objects and paths.    
```dart    
// get the scoped router by calling    
AutoRouter.of(context)    
// or using the extension    
context.router    
    
// adds a new entry to the pages stack    
router.push(const BooksListRoute())  
// or by using using paths  
router.pushNamed('/books')   

// removes last entry in stack and pushs provided route 
// if last entry == provided route page will just be updated
router.replace(const BooksListRoute())    
// or by using using paths  
router.replaceNamed('/books')  

// pops until provided route, if it already exists in stack    
// else adds it to the stack (good for web Apps).    
router.navigate(const BooksListRoute())  
// or by using using paths  
router.navigateNamed('/books')  

// adds a list of routes to the pages stack at once
router.pushAll([
   BooksListRoute(),
   BookDetailsRoute(id:1),
]);

// This's like providing a completely new stack as it rebuilds the stack
// with the list of passed routes
// entires might just update if alright exist
router.replaceAll([
   LoginRoute()
]);
// pops the last page unless stack has 1 entry    
context.router.pop();   
// keeps poping routes until predicate is satisfied
context.router.popUntil((route) => route.name == 'HomeRoute');
// a simplifed version of the above line
context.router.popUntilRouteWithName('HomeRoute');
// pops all routes down to the root
context.router.popUntilRoot();
     
// removes the top most page in stack even if it's the last
// remove != pop, it doesn't respect WillPopScopes it just 
// removes the entry.
context.router.removeLast(); 

// removes any route in stack that satisfis the predicate
// this works exactly like removing items from a regualar List
// <PageRouteInfo>[...].removeWhere((r)=>)
context.router.removeWhere((route) => );
    
// you can also use the common helper methods from context extension to navigate
context.pushRoute(const BooksListRoute());
context.replaceRoute(const BooksListRoute());
context.navigateTo(const BooksListRoute());
context.navigateNamedTo('/books');
context.popRoute();
```    
## Passing Arguments 
That's the fun part! **AutoRoute** automatically detects and handles your page arguments for you, the generated route object will deliver all the arguments your page needs including path/query params. 
    
e.g. The following page widget will take an argument of type `Book`.  
    
```dart    
class BookDetailsPage extends StatelessWidget {    
 const BookDetailsRoute({required this.book});    
    
  final Book book; 
  ...    
 ```    
 **Note:** Default values are respected. Required fields are also respected and handled properly.    
    
The generated `BookDetailsRoute` will deliver the same arguments to it's corresponding page.    
```drt    
router.push(BookDetailsRoute(book: book));    
```    

**Note:** all args are generated as named parameters regardless of their original type.

## Returning Results
You can return results by either using the pop completer or by passing a callback function as an argument the same way you'd pass an object.

1 - Using the pop completer
```dart    
var result = await router.push(LoginRoute());    
```  
then inside of your `LoginPage` pop with results
```dart  
router.pop(true);   
```  
as you'd notice we didn't specify the result type,  we're playing with dynamic values here, which can be risky and I personally don't recommend it.  

To avoid working with dynamic values we specify what type of results we expect our page to return, which is a `bool` value.
```dart   
AutoRoute<bool>(page: LoginPage), 
``` 
we push and specify the type of results we're expecting
```dart    
var result = await router.push<bool>(LoginRoute());    
``` 
and of course we pop with the same type
```dart  
router.pop<bool>(true);   
```  
2- Passing a callback function as an argument.
We only have to add a callback function as a parameter to our page constructor like follows:
```dart    
class BookDetailsPage extends StatelessWidget {    
 const BookDetailsRoute({this.book, required this.onRateBook});    
    
  final Book book;    
  final void Function(int) onRateBook;    
  ...    
 ```    
 
The generated `BookDetailsRoute` will deliver the same arguments to it's corresponding page.    
```dart    
context.router.push(    
      BookDetailsRoute(    
          book: book,    
          onRateBook: (rating) {    
           // handle result    
          }),    
    );    
```    
if you're finishing with the results make sure you call the callback function as you pop the page    
```dart    
onRateBook(RESULT);    
context.router.pop();    
```
 **Note:** Default values are respected. Required fields are also respected and handled properly.       

## Working with Paths
 Working with paths in **AutoRoute** is optional because `PageRouteInfo` objects are matched by name unless pushed as a string using the `initialDeepLink` property in root delegate or `pushNamed`, `replaceNamed` `navigateNamed` methods.    
    
if you don’t specify a path it’s going to be generated from the page name e.g. `BookListPage` will have ‘book-list-page’ as a path, if initial arg is set to true the path will be `/` unless it's relative then it will be an empty string `''`.    
    
When developing a web Application or a native App that requires deep-linking you'd probably need to define paths with clear memorable names, and that's done using the `path` argument in `AutoRoute`.    
    
```dart    
 AutoRoute(path: '/books', page: BookListPage),    
```    
#### Path Parameters (dynamic segments)
 You can define a dynamic segment by prefixing it with a colon    
```dart    
 AutoRoute(path: '/books/:id', page: BookDetailsPage),    
```    
The simplest way to extract path parameters from path and gain access to them is by annotating constructor param with `@PathParam('optional-alias')` with the same alias/name of the segment.    
    
```dart    
class BookDetailsPage extends StatelessWidget {    
  const BookDetailsPage({@PathParam('id') this.bookId});
  
  final int bookId;    
  ...    
```    
Now writing `/books/1` in the browser will navigate you to `BookDetailsPage` and automatically extract the `bookId` argument from path and inject it to your widget.
    
#### Query Parameters 
Query parameters are accessed the same way, simply annotate the constructor parameter to hold the value of the query param with `@QueryParam('optional-alias')` and let AutoRoute do the rest.    
    
you could also access path/query parameters using the scoped `RouteData` object.    
```dart    
 RouteData.of(context).pathParams;    
 // or using the extension    
 context.route.queryParams    
```    
`Tip`: if your parameter name is the same as the path/query parameter, you could use the const @pathParam or @queryParam and not pass a slug/alias.

```dart  
class BookDetailsPage extends StatelessWidget {    
  const BookDetailsPage({@pathParam this.id});
  
  final int id;    
  ...    
```  

#### Redirecting Paths 
Paths can be redirected using `RedirectRoute`. The following setup will navigate us to `/books` when `/` is matched.    
    
```dart    
<AutoRoute> [    
     RedirectRoute(path: '/', redirectTo: '/books'),    
     AutoRoute(path: '/books', page: BookListPage),    
 ]    
```    
When redirecting initial routes the above setup can be simplified by setting the `/books` path as initial and auto_route will automatically generate the required redirect code for you.
```dart    
<AutoRoute> [      
     AutoRoute(path: '/books', page: BookListPage, initial: true),    
 ]    
```  
Note:  `RedirectRoutes` are fully matched.    

#### Wildcards 
auto_route supports wildcard matching to handle invalid or undefined paths.    
```dart    
AutoRoute(path: '*', page: UnknownRoutePage)    
// it could be used with defined prefixes    
AutoRoute(path: '/profile/*', page: ProfilePage)    
// or it could be used with RedirectRoute    
RedirectRoute(path: '*', redirectTo: '/')    
```    
**Note:** be sure to always add your wildcards at the end of your route list because routes are matched in order.    
    
    
## Nested Routes
 Nesting routes with AutoRoute is as easy as populating the children field of the parent route. In the following example both `UserProfilePage` and `UserPostsPage` are nested children of `UserPage`.    
```dart    
@MaterialAutoRouter(    
  replaceInRouteName: 'Page,Route',    
  routes: <AutoRoute>[    
    AutoRoute(    
      path: '/user/:id',    
      page: UserPage,    
      children: [    
        AutoRoute(path: 'profile', page: UserProfilePage),    
        AutoRoute(path: 'posts', page: UserPostsPage),    
      ],    
    ),    
  ],    
)    
class $AppRouter {}    
```    
The parent page `UserPage` will be rendered inside of root router widget provided by `MaterialApp.router` but not its children, that's why we need to place an AutoRouter widget inside of `UserPage` where we need the nested routes to be rendered.     
    
```dart    
class UserPage extends StatelessWidget {    
  const UserPage({Key key, @pathParam this.id}) : super(key: key);    
  final int id;    
  @override    
  Widget build(BuildContext context) {    
    return Scaffold(    
      appBar: AppBar(title: Text('User $id')),     
      body: AutoRouter() // nested routes will be rendered here    
    );    
  }    
}    
```    
    
Now if we navigate to `/user/1` we will be presented with a page that has an appBar title that says `User 1` and an empty  body, why? because we haven't pushed any routes to our nested AutoRouter, but if we navigate to `user/1/profile` the `UserProfilePage` will be pushed to the nested router and that's what we will see.    
    
What if want to show one of the child pages at `/users/1`? we can simply do that by giving the child page an empty path `''`.    
    
```dart    
   AutoRoute(    
      path: '/user/:id',    
      page: UserPage,    
      children: [    
        AutoRoute(path: '', page: UserProfilePage),    
        AutoRoute(path: 'posts', page: UserPostsPage),    
      ],    
    ),    
```    
or by using `RedirectRoute` 
```dart    
   AutoRoute(    
      path: '/user/:id',    
      page: UserPage,    
      children: [    
        RedirectRoute(path: '', redirectTo: 'profile'),    
        AutoRoute(path: 'profile', page: UserProfilePage),    
        AutoRoute(path: 'posts', page: UserPostsPage),    
      ],    
    ),    
```    
in both cases whenever we navigate to `/user/1` we will be presented with the `UserProfilePage`.    
    
## Finding The Right Router 
Every nested AutoRouter has its own routing controller to manage the stack inside of it and the easiest way to obtain a scoped controller is by using context.     
    
In the previous example `UserPage` is a root level stack entry so calling `AutoRouter.of(context)` anywhere inside of it will get us the root routing controller.    
    
`AutoRouter` widgets that are used to render nested routes insert a new router scope into the widgets tree, so when a nested route calls for the scoped controller they will get the closest parent controller in the widgets tree not the root controller.     
    
```dart    
class UserPage extends StatelessWidget {    
  const UserPage({Key key, @pathParam this.id}) : super(key: key);    
  final int id;    
  @override    
  Widget build(BuildContext context) {    
  // this will get us the root routing controller    
    AutoRouter.of(context);    
    return Scaffold(    
      appBar: AppBar(title: Text('User $id')),     
      // this inserts a new router scope into the widgets tree    
      body: AutoRouter()     
    );    
  }    
}    
```    
Here's a simple diagram to help visualize this    
    
<p align="center">    
<img  src="https://raw.githubusercontent.com/Milad-Akarie/auto_route_library/master/art/scoped_routers_demo.png" height="570">    
</p>    
    
As you can tell from the above diagram it's possible to access parent routing controllers by calling `router.parent<T>()`, we're using a generic function because we too different routing controllers  `StackRouter` and `TabsRouter`, one of them could be the parent controller of the current router and that's why we need to specify a type.     
```dart    
router.parent<StackRouter>() // this returns a the parent router as a Stack Routing controller    
router.parent<TabsRouter>() // this returns a the parent router as a Tabs Routing controller    
```    
on the other hand obtaining the root controller does not require type casting because it's always a `StackRouter`.    
```dart    
router.root // this returns the root router as a Stack Routing controller    
```    
    
You could also obtain inner-routers from outside their scope as long as you have access to the parent router.    
```dart    
// assuming this's the root router    
AutoRouter.of(context).innerRouterOf<StackRouter>(UserRoute.name)    
// or use the short version     
AutoRouter.innerRouterOf(context, UserRoute.name);    
```    
Accessing the `UserPage` inner router from the previous example.    
    
```dart    
class UserPage extends StatelessWidget {    
  final int id;    
    
  const UserPage({Key key, @pathParam this.id}) : super(key: key);    
    
  @override    
  Widget build(BuildContext context) {    
    return Scaffold(    
      appBar: AppBar(    
        title: Text('User $id'),    
        actions: [    
          IconButton(    
            icon: Icon(Icons.account_box),    
            onPressed: () {    
              // accessing the inner router from    
              // outside the scope    
              AutoRouter.innerRouterOf(context, UserRoute.name).push(UserPostsRoute());    
            },    
          ),    
        ],    
      ),    
      body: AutoRouter(), // we're trying to get access to this    
    );    
  }    
}    
```    
**Note**: nested routing controllers are created along with the parent route so accessing them without context is safe as long as it's somewhere beneath the parent route ( The host page ).    
    
## Route Guards
Think of route guards as middleware or interceptors, routes can not be added to the stack without going through their assigned guards, Guards are useful for restricting access to certain routes.

We create a route guard by extending `AutoRouteGuard` from the auto_route package
and implementing our logic inside of the onNavigation method.
```dart
class AuthGuard extends AutoRouteGuard {
 @override
 void onNavigation(NavigationResolver resolver, StackRouter router) {
 // the navigation is paused until resolver.next() is called with either 
 // true to resume/continue navigation or false to abort navigation
     if(authenitcated){
       // if user is autenticated we continue
        resolver.next(true);
      }else{
         // we redirect the user to our login page
         router.push(LoginRoute(onResult: (success){
                // if success == true the navigation will be resumed
                // else it will be aborted
               resolver.next(success);
          });
         }    
     }
}

```
**Important**:  `resolver.next()` should only be called once. 

The `NavigationResolver` object contains the guarded route which you can access by calling the property `resolver.route`  and a list of pending routes (if there are any) accessed by calling `resolver.pendingRoutes`.

Now we assign our guard to the routes we want to protect.

```dart
 AutoRoute(page: ProfileScreen, guards: [AuthGuard]);
```
After we run code generation, our router will have a required named argument called authGuard or whatever your guard name is
```dart
// we pass our AuthGaurd to the generated router.
final _appRouter = AppRouter(authGuard: AuthGuard());
```


## Customizations

##### MaterialAutoRouter | CupertinoAutoRouter | AdaptiveAutoRouter

| Property                                 | Default value | Definition                                                                               |
| ---------------------------------------- | ------------- | ---------------------------------------------------------------------------------------- |
| preferRelativeImports [bool] | true         | if true relative imports will be used when possible |
| replaceInRouteName [String] |    ''     | used to replace conventional words in generated route name (whatToReplacePattern,replacment) |

#### CustomAutoRouter

| Property                        | Default value | Definition                                                                       |
| ------------------------------- | :-----------: | -------------------------------------------------------------------------------- |
| customRouteBuilder    |     null      | used to provide a custom route, it takes in BuildContext and a CustomPage  and returns a PageRoute             |
| transitionsBuilder    |     null      | extension for the transitionsBuilder property in PageRouteBuilder                |
| opaque                   |     true      | extension for the opaque property in PageRouteBuilder                            |
| barrierDismissible       |     false     | extension for the barrierDismissible property in PageRouteBuilder                |
| durationInMilliseconds  |     null      | extension for the transitionDuration(millieSeconds) property in PageRouteBuilder |
| reverseDurationInMilliseconds  |     null      | extension for the reverseDurationInMilliseconds(millieSeconds) property in PageRouteBuilder |


#### MaterialRoute | CupertinoRoute | AdaptiveRoute | CustomRoute

| Property                | Default value | Definition                                                                                 |
| ----------------------- | :-----------: | ------------------------------------------------------------------------------------------ |
| initial          |     false     | sets path to '/' or '' unless path is provided then it generates auto redirect to it.                                                          |
| path           |     null      | an auto generated path will be used if not provided|
| name           |     null      | this will be the name of the generated route, if not provided a generated name will be used|
| usePathAsKey           |     false      | if true path is used as page key instead of name|
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
| customRouteBuilder    |     null      | used to provide a custom route, it takes in BuildContext and a CustomPage  and returns a PageRoute 
| opaque                  |     true      | extension for the opaque property in PageRouteBuilder                            |
| barrierDismissible       |     false     | extension for the barrierDismissible property in PageRouteBuilder                |
| durationInMilliseconds  |     null      | extension for the transitionDuration(millieSeconds) property in PageRouteBuilder |
| reverseDurationInMilliseconds  |     null      | extension for the reverseDurationInMilliseconds(millieSeconds) property in PageRouteBuilder |

## Custom Route Transitions

To use custom route transitions use a `CustomRoute` and pass in your preferences.
The `TransitionsBuilder` function needs to be passed as a static/const reference that has the same signature as the `TransitionsBuilder` function of the `PageRouteBuilder` class.

```dart
CustomRoute(
page: LoginScreen,
//TransitionsBuilders class contains a preset of common transitions builders. 
transitionsBuilder: TransitionBuilders.slideBottom,
durationInMilliseconds: 400)
```



*Tip* Use **@CustomAutoRouter()** to define global custom route transitions.

You can of course use your own transitionsBuilder function as long as it has the same function signature.
The function has to take in exactly a `BuildContext`, `Animation<Double>`, `Animation<Double>` and a child `Widget` and it needs to return a `Widget`, typically you would wrap your child with one of flutter's transition widgets as follows.

```dart
Widget zoomInTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
 // you get an animation object and a widget
 // make your own transition
    return ScaleTransition(scale: animation, child: child);
  }
```

Now pass the reference of your function to `CustomRoute` .

```dart
CustomRoute(page: ZoomInScreen, transitionsBuilder: zoomInTransition)
```
## Custom Route Builder
You can use your own custom route by passing a `CustomRouteBuilder` function to `CustomRoute`,  there isn't a simple way to strongly-type a static function in code generation, so make sure your custom builder  signature matches the following.
```dart
typedef CustomRouteBuilder = Route<T> Function<T>(  
  BuildContext context, Widget child, CustomPage page);
```
Now we implement our builder function the same way we did with the TransitionsBuilder function,
the most important part here is passing the page argument to our custom route.
```dart
Route<T> myCustomRouteBuilder<T>(BuildContext context, Widget child, CustomPage<T> page){  
  return PageRouteBuilder(  
  fullscreenDialog: page.fullscreenDialog,  
  // this is important  
  settings: page,  
  pageBuilder: (,__,___)=> child);  
}
```
We finish by passing a reference of our custom function to our CustomRoute.
```dart
CustomRoute(page: CustomPage, customRouteBuilder: myCustomRouteBuilder)
```

## More docs are coming soon    
### Support auto_route
  You can support auto_route by liking it on Pub and staring it on Github, sharing ideas on how we can enhance a certain functionality or by reporting any problems you encounter and of course buying a couple coffees will help speed up the development process.