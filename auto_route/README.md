  
<p align="center">  
<img  src="https://raw.githubusercontent.com/Milad-Akarie/auto_route_library/master/art/auto_route_logo.svg" height="170">  
</p>  
  
<p align="center">  
<a href="https://img.shields.io/badge/License-MIT-green"><img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License"></a>  
<a href="https://github.com/Milad-Akarie/auto_route_library/stargazers"><img src="https://img.shields.io/github/stars/Milad-Akarie/auto_route_library?style=flat&logo=github&colorB=green&label=stars" alt="stars"></a>  
<a href="https://pub.dev/packages/auto_route/versions/2.0.0"><img src="https://img.shields.io/badge/pub-2.0.0-orange" alt="pub version"></a>  
<a href="https://discord.gg/x3SBU4WRRd">  
 <img src="https://img.shields.io/discord/821043906703523850.svg?color=7289da&label=Discord&logo=discord&style=flat-square" alt="Discord Badge"></a>  
</p>  
  
<p align="center">
<a href="https://www.buymeacoffee.com/miladakarie" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="30px" width= "108px"></a>
</p>

---
**Check out the new docs!** https://autoroute.vercel.app  

- [Introduction](#introduction)  
- [Installation](#installation)  
- [Setup and Usage](#setup-and-usage)  
- [Generated routes](#generated-routes)  
- [Navigation](#navigation)  
- [Passing Arguments](#passing-arguments)  
- [Working with Paths](#working-with-paths)  
- [Nested Routes](#nested-routes)  
- [Finding The Right Router](#finding-the-right-router)  
  
### Introduction  
##### What is AutoRoute?  
It’s a Flutter navigation package, it allows for strongly-typed arguments passing, effortless deep-linking and it uses code generation to simplify routes setup, with that being said it requires a minimal amount of code to generate everything needed for navigation inside of your App.  
##### Why AutoRoute?  
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
**Note**: The name of the router must be prefixed with **\$** so we will have a  generated class with the same name minus the **$**.  
  
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
  
   final _appRouter = AppRouter()  
   ...  
  Widget build(BuildContext context){  
      return MaterialApp.router(  
             routerDelegate: _appRouter.delegate(...initialConfig),  
             routeInformationParser: _appRouter.defaultRouteParser(),  
         ),  
  }  
```  
## Generated Routes  
---  
  A `PageRouteInfo` object will be generated for every declared AutoRoute, These objects hold path information plus strongly-typed page arguments which are extracted from the page's default constructor.  
```dart  
class BookListRoute extends PageRouteInfo {  
  const BookListRoute() : super(name, path: '/books');  
  
  static const String name = 'BookListRoute';  
}  
```  
if the declared route has children AutoRoute will add a children parameter to its constructor to be used in deep-linking. more on that here  
  
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
  
## Navigation  
`AutoRouter` offers the same known push, pop and friends methods to manipulate the pages stack using the generated `PageRouteInfo` objects.  
```dart  
// get the scoped router by calling  
AutoRouter.of(context)  
// or using the extension  
context.router  
  
// adds a new entry to pages stack  
router.push(BooksListRoute())  
  
// pops the last page unless stack has 1 entry  
context.router.pop()  
  
  
// pops until provided route, if it already exists in stack  
// else adds it to the stack (good for web Apps).  
router.navigate(BooksListRoute())  
  
// replaces last entry in stack, throws an error if stack is empty  
router.replace(BooksListRoute())  
  
```  
## Passing Arguments  
---  
That's the fun part! **AutoRoute** automatically detects and handles your page arguments for your, the generated Route object will deliver all the arguments your page needs including callback functions (to return results).  
  
e.g. The following page widget will take an argument of type `Book` and a callback function that returns a rating value on pop.  
  
```dart  
class BookDetailsPage extends StatelessWidget {  
 const BookDetailsRoute({this.book, this.onRateBook});  
  
  final Book book;  
  final void Function(int) onRateBook;  
  ...  
 ```  
 **Note:** Default values are respected. Required fields are also respected and handled properly.  
  
The generated `BookDetailsRoute` will deliver the same arguments to it's corresponding page.  
```drt  
context.router.push(  
      BookDetailsRoute(  
          book: book,  
          onRateBook: (rating) {  
           // handle result  
          }),  
    );  
```  
make sure you call the callback function as you pop the page  
```dart  
onRateBook?.call(RESULT);  
context.router.pop();  
```  
## Working with Paths  
Working with paths in **AutoRoute** is optional because `PageRouteInfo` objects are matched by name unless pushed as a string using the `initialDeepLink` property in root delegate or `pushPath` method in StackRouter.  
  
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
if you define a path with a dynamic segment the corresponding page's constructor must have a parameter that is annotated with `@PathParam('optional-alias')` with the same alias/name of the segment.  
  
```dart  
class BookDetailsPage extends StatelessWidget {  
  BookDetailsPage({@PathParam('id') this.bookId});  
  
  final int bookId;  
  ...  
```  
Now writing `/books/1` in the browser will navigate you to `BookDetailsPage` and automatically extract the `bookId` argument from the path.  
#### Query Parameters  
Query parameters are accessed the same way, simply annotate the constructor parameter to hold the value of the query param with `@QueryParam('optional-alias')` and let AutoRoute do the rest.  
  
you could also access path/query parameters using the scoped `RouteData` object.  
```dart  
 RouteData.of(context).pathParams;  
 // or using the extension  
 context.route.queryParams  
```  
#### Redirecting Paths  
Paths can be redirected using `RedirectRoute`. The following setup will navigate us to `/books` when `/` is matched.  
  
```dart  
<AutoRoute> [  
     RedirectRoute(path: '/', redirectTo: '/books'),  
     AutoRoute(path: '/books', page: BookListPage),  
 ]  
```  
Note:  `RedirectRoutes` are fully matched.  
#### Wildcards  
AutoRoute supports wildcard matching to handle invalid or undefined paths.  
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
  
## More docs are coming soon  
  
### Support auto_route  
You can support auto_route by liking it on Pub and staring it on Github, sharing ideas on how we can enhance a certain functionality or by reporting any problems you encounter and of course buying a couple coffees will help speed up the development process.