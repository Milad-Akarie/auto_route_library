<p align="center">
  <img src="https://raw.githubusercontent.com/Milad-Akarie/auto_route_library/master/art/auto_route_logo.svg" height="170" alt="auto_route_logo">
</p>

<p align="center">
  <a href="https://img.shields.io/badge/License-MIT-green">
    <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
  </a>
  <a href="https://github.com/Milad-Akarie/auto_route_library/stargazers">
    <img src="https://img.shields.io/github/stars/Milad-Akarie/auto_route_library?style=flat&logo=github&colorB=green&label=stars" alt="stars">
  </a>
  <a href="https://pub.dev/packages/auto_route">
    <img src="https://img.shields.io/pub/v/auto_route.svg?label=pub&color=orange" alt="pub version">
  </a>
  <a href="https://discord.gg/x3SBU4WRRd">
    <img src="https://img.shields.io/discord/821043906703523850.svg?color=7289da&label=Discord&logo=discord&style=flat-square" alt="Discord Badge">
  </a>
</p>

<p align="center">
  <a href="https://www.buymeacoffee.com/miladakarie" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="30px" width= "108px">
  </a>
</p>

---

- [Introduction](#introduction)
    - [Installation](#installation)
    - [Setup and Usage](#setup-and-usage)
- [Generated routes](#generated-routes)
- [Navigation](#navigating-between-screens)
    - [Navigating Between Screens](#navigating-between-screens)
    - [Passing Arguments](#passing-arguments)
    - [Returning Results](#returning-results)
    - [Nested navigation](#nested-navigation)
    - [Tab Navigation](#tab-navigation)
        - [Using PageView](#using-pageview)
        - [Using TabBar](#using-tabbar)
    - [Finding The Right Router](#finding-the-right-router)
    - [Navigating Without Context](#navigating-without-context)
- [Deep Linking](#deep-linking)
- [Declarative Navigation](#declarative-navigation)
- [Working with Paths](#working-with-paths)
- [Route guards](#route-guards)
- [Wrapping routes](#wrapping-routes)
- [Navigation Observers](#navigation-observers)
- [Customization](#customizations)
    - [Custom Route Transitions](#custom-route-transitions)
    - [Custom Route Builder](#custom-route-builder)
- [Others](#others)
    - [Including Micro/External Packages](#including-microexternal-packages)
    - [Configuring builders](#configuring-builders)
        - [Optimizing Generation Time](#optimizing-generation-time)
        - [Enabling Cached Builds (Experimental)](#enabling-cached-builds)
    - [AutoLeadingButton-BackButton](#autoleadingbutton-backbutton)
    - [ActiveGuardObserver](#activeguardobserver)
- [Examples](#examples)

**Note:** [AutoRoute-Helper] is no longer supported.

## Migration guides

- [Migrating to v6](#migrating-to-v6)

## Pre v6 documentation

- [Pre v6 documentation](https://github.com/Milad-Akarie/auto_route_library/blob/master/old/pre_v6_README.md)

## Introduction

#### What is AutoRoute?

It’s a Flutter navigation package, it allows for strongly-typed arguments passing, effortless deep-linking and it uses code generation to simplify routes setup. With that being said, it requires a minimal amount of code to generate everything needed for navigation inside of your App.

#### Why AutoRoute?

If your App requires deep-linking or guarded routes or just a clean routing setup, you'll need to use named/generated routes and you’ll end up writing a lot of boilerplate code for mediator argument classes, checking for required arguments, extracting arguments and a bunch of other stuff. **AutoRoute** does all that for you and much more.

## Installation

 ```yaml
dependencies:
  auto_route: [latest-version]

dev_dependencies:
  auto_route_generator: [latest-version]
  build_runner:
```

## Setup And Usage

1. Create a router class and annotate it with `@AutoRouterConfig` then extend "$YourClassName"
2. Override the routes getter and start adding your routes.

 ```dart
@AutoRouterConfig()
class AppRouter extends $AppRouter {

  @override
  List<AutoRoute> get routes => [
    /// routes go here
  ];
}
```

### Using part builder

To generate a part-of file simply add a `part` directive to your `AppRouter` and extend the generated private router. **Note:** The `deferredLoading` functionality does not work with part-file setup.

```dart
part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {

  @override
  List<AutoRoute> get routes => [
    /// routes go here
  ];
}
```

### Generating Routable pages

Routable pages are just simple everyday widgets annotated with `@RoutePage()` which allows them to be constructed by the router.

```dart
@RoutePage()
class HomeScreen extends StatefulWidget {}
```

#### Now simply run the generator

Use the [watch] flag to watch the files' system for edits and rebuild as necessary.

```terminal
dart run build_runner watch
```

If you want the generator to run one time and exit, use

```terminal
dart run build_runner build
```

#### Add the generated route to your routes list

```dart
@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends $AppRouter {

  @override
  List<AutoRoute> get routes => [
    // HomeScreen is generated as HomeRoute because
    // of the replaceInRouteName property
    AutoRoute(page: HomeRoute.page),
  ];
}
```

#### Finalize the setup

After you run the generator, your router class will be generated. Then simply hook it up with your MaterialApp.

```dart
// assuming this is the root widget of your App
class App extends StatelessWidget {
  // make sure you don't initiate your router
  // inside of the build function.
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context){
    return MaterialApp.router(
      routerConfig: _appRouter.config(),
    );
  }
}
```

## Generated Routes

A `PageRouteInfo` object will be generated for every declared **AutoRoute**. These objects hold strongly-typed page arguments which are extracted from the page's default constructor. Think of them as string path segments on steroids.

```dart
class BookListRoute extends PageRouteInfo {
  const BookListRoute({
    List<PagerouteInfo>? children,
  }) : super(name, path: '/books', initialChildren: children);

  static const String name = 'BookListRoute';
  static const PageInfo<void> page = PageInfo<void>(name);
}
```

## Navigating Between Screens

`AutoRouter` offers the same known push, pop and friends methods to manipulate the pages stack using both the generated `PageRouteInfo` objects and paths.

```dart
// get the scoped router by calling
AutoRouter.of(context);
// or using the extension
context.router;
// adds a new entry to the pages stack
router.push(const BooksListRoute());
// or by using paths
router.pushNamed('/books');
// removes last entry in stack and pushes provided route
// if last entry == provided route page will just be updated
router.replace(const BooksListRoute());
// or by using paths
router.replaceNamed('/books');
// pops until provided route, if it already exists in stack
// else adds it to the stack (good for web Apps).
router.navigate(const BooksListRoute());
// or by using paths
router.navigateNamed('/books');
// on Web it calls window.history.back();
// on Native it navigates you back
// to the previous location
router.back();
// adds a list of routes to the pages stack at once
router.pushAll([
  BooksListRoute(),
  BookDetailsRoute(id: 1),
]);
// This is like providing a completely new stack as it rebuilds the stack
// with the list of passed routes
// entries might just update if already exist
router.replaceAll([
  LoginRoute(),
]);
// pops the last page unless blocked or stack has only 1 entry
context.router.maybePop();
// pops the most top page of the most top router unless blocked
// or stack has only 1 entry
context.router.maybePopTop();
// keeps popping routes until predicate is satisfied
context.router.popUntil((route) => route.settings.name == 'HomeRoute');
// a simplified version of the above line
context.router.popUntilRouteWithName('HomeRoute');
// keeps popping routes until route with provided path is found
context.router.popUntilRouteWithPath('/some-path');
// pops all routes down to the root
context.router.popUntilRoot();
// removes the top most page in stack even if it's the last
// remove != pop, it doesn't respect WillPopScopes it just
// removes the entry.
context.router.removeLast();
// removes any route in stack that satisfies the predicate
// this works exactly like removing items from a regular List
// <PageRouteInfo>[...].removeWhere((r)=>)
context.router.removeWhere((route) => );
// you can also use the common helper methods from context extension to navigate
context.pushRoute(const BooksListRoute());
context.replaceRoute(const BooksListRoute());
context.navigateTo(const BooksListRoute());
context.navigateNamedTo('/books');
context.back();
context.maybePop();
```

## Passing Arguments

That's the fun part! **AutoRoute** automatically detects and handles your page arguments for you, the generated route object will deliver all the arguments your page needs including path/query params.

e.g. The following page widget will take an argument of type `Book`.

```dart
@RoutePage()
class BookDetailsPage extends StatelessWidget {
  const BookDetailsPage({required this.book});

  final Book book;
  ...
```

**Note:** Default values are respected. Required fields are also respected and handled properly.

The generated `BookDetailsRoute` will deliver the same arguments to its corresponding page.

```dart
router.push(BookDetailsRoute(book: book));
```

**Note:** All arguments are generated as named parameters regardless of their original type.

## Returning Results

You can return results by either using the pop completer or by passing a callback function as an argument the same way you'd pass an object.

#### 1. Using the `pop` completer

```dart
var result = await router.push(LoginRoute());
```

then inside of your `LoginPage`, pop with results

```dart
router.maybePop(true);
```

as you'd notice we did not specify the result type, we're playing with dynamic values here, which can be risky and I personally don't recommend it.

To avoid working with dynamic values, we specify what type of results we expect our page to return, which is a `bool` value.

```dart
@RoutePage<bool>()
class LoginPage extends StatelessWidget {}
```

we push and specify the type of results we're expecting

```dart
var result = await router.push<bool>(LoginRoute());
```

and of course we pop with the same type

```dart
router.maybePop<bool>(true);
```

#### 2. Passing a callback function as an argument.
We only have to add a callback function as a parameter to our page constructor like follows:

```dart
@RoutePage()
class BookDetailsPage extends StatelessWidget {
  const BookDetailsRoute({this.book, required this.onRateBook});

  final Book book;
  final void Function(int) onRateBook;
  ...
```

The generated `BookDetailsRoute` will deliver the same arguments to its corresponding page.

```dart
context.pushRoute(
  BookDetailsRoute(
    book: book,
    onRateBook: (rating) {
      // handle result
    },
  ),
);
```

If you're finishing with results, make sure you call the callback function as you pop the page

```dart
onRateBook(RESULT);
context.maybePop();
```

**Note:** Default values are respected. Required fields are also respected and handled properly.

## Nested Navigation

Nested navigation means building an inner router inside of a page of another router, for example in the below diagram users page is built inside of dashboard page.

<p align="center">
  <img alt="nested-router-demo"  src="https://raw.githubusercontent.com/Milad-Akarie/auto_route_library/master/art/nested_router_demo.png?raw=true" height="370">
</p>

Defining nested routes is as easy as populating the children field of the parent route. In the following example  `UsersPage`, `PostsPage` and `SettingsPage` are nested children of `DashboardPage`.

```dart
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends $AppRouter {

@override
List<AutoRoute> get routes => [
    AutoRoute(
      path: '/dashboard',
      page: DashboardRoute.page,
      children: [
        AutoRoute(path: 'users', page: UsersRoute.page),
        AutoRoute(path: 'posts', page: PostsRoute.page),
        AutoRoute(path: 'settings', page: SettingsRoute.page),
      ],
    ),
    AutoRoute(path: '/login', page: LoginRoute.page),
  ];
}
```

To render/build nested routes we need an `AutoRouter` widget that works as an outlet or a nested router-view inside of our dashboard page.

```dart
class DashboardPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            NavLink(label: 'Users', destination: const UsersRoute()),
            NavLink(label: 'Posts', destination: const PostsRoute()),
            NavLink(label: 'Settings', destination: const SettingsRoute()),
          ],
        ),
        Expanded(
          // nested routes will be rendered here
          child: AutoRouter(),
        ),
      ],
    );
  }
}
```

**Note** NavLink is just a button that calls router.push(destination). Now if we navigate to `/dashboard/users`, we will be taken to the `DashboardPage` and the `UsersPage` will be shown inside of it.

What if want to show one of the child pages at `/dashboard`? We can simply do that by giving the child routes an empty path `''` to make initial or by setting initial to true.

```dart
AutoRoute(
  path: '/dashboard',
  page: DashboardRoute.page,
  children: [
    AutoRoute(path: '', page: UsersRoute.page),
    AutoRoute(path: 'posts', page: PostsRoute.page),
  ],
)
```

or by using a `RedirectRoute`

```dart
AutoRoute(
  path: '/dashboard',
  page: DashboardRoute.page,
  children: [
    RedirectRoute(path: '', redirectTo: 'users'),
    AutoRoute(path: 'users', page: UsersRoute.page),
    AutoRoute(path: 'posts', page: PostsRoute.page),
  ],
)
```

### Things to keep in mind when implementing nested navigation

1. Each router manages its own pages stack.
2. Navigation actions like push, pop and friends are handled by the topmost router and bubble up if it couldn't be handled.

## Tab Navigation

If you're working with flutter mobile, you're most likely to implement tabs navigation, that's why `auto_route` makes tabs navigation as easy and straightforward as possible.

In the previous example we used an `AutoRouter` widget to render nested child routes, `AutoRouter` is just a shortcut for `AutoStackRouter`. `StackRouters` manage a stack of pages inside of them, where the active/visible page is always the one on top and you'd need to pop it to see the page beneath it.

Now we can try to implement our tabs using an `AutoRouter` (StackRouter) by pushing or replacing a nested route every time the tab changes and that might work, but our tabs state will be lost, not to mention the transition between tabs issue, luckily auto_route comes equipped with an `AutoTabsRouter`, which is especially made to handle tab navigation.

`AutoTabsRouter` lets you switch between different routes while preserving offstage-routes state, tab routes are lazily loaded by default (can be disabled) and it finally allows to create whatever transition animation you want.

Let's change the previous example to use tab navigation.

Notice that we're not going to change anything in our routes declaration map, we still have a dashboard page that has three nested children: users, posts and settings.

```dart
class DashboardPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      // list of your tab routes
      // routes used here must be declared as children
      // routes of /dashboard
      routes: const [
        UsersRoute(),
        PostsRoute(),
        SettingsRoute(),
      ],
      transitionBuilder: (context,child,animation) => FadeTransition(
            opacity: animation,
            // the passed child is technically our animated selected-tab page
            child: child,
          ),
      builder: (context, child) {
        // obtain the scoped TabsRouter controller using context
        final tabsRouter = AutoTabsRouter.of(context);
        // Here we're building our Scaffold inside of AutoTabsRouter
        // to access the tabsRouter controller provided in this context
        //
        // alternatively, you could use a global key
        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: tabsRouter.activeIndex,
            onTap: (index) {
              // here we switch between tabs
              tabsRouter.setActiveIndex(index);
            },
            items: [
              BottomNavigationBarItem(label: 'Users', ...),
              BottomNavigationBarItem(label: 'Posts', ...),
              BottomNavigationBarItem(label: 'Settings', ...),
            ],
          ),
        );
      },
    );
  }
}
```

If you think the above setup is a bit messy you could use the shipped-in `AutoTabsScaffold` that makes things much cleaner.

```dart
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: const [
        UsersRoute(),
        PostsRoute(),
        SettingsRoute(),
      ],
      bottomNavigationBuilder: (_, tabsRouter) {
        return BottomNavigationBar(
          currentIndex: tabsRouter.activeIndex,
          onTap: tabsRouter.setActiveIndex,
          items: const [
            BottomNavigationBarItem(label: 'Users', ...),
            BottomNavigationBarItem(label: 'Posts', ...),
            BottomNavigationBarItem(label: 'Settings', ...),
          ],
        );
      },
    );
  }
}
```

### Using PageView

Use the `AutoTabsRouter.pageView` constructor to implement tabs using PageView

```dart
AutoTabsRouter.pageView(
  routes: [
    BooksTab(),
    ProfileTab(),
    SettingsTab(),
  ],
  builder: (context, child, _) {
    final tabsRouter = AutoTabsRouter.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.topRoute.name),
        leading: AutoLeadingButton(),
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabsRouter.activeIndex,
        onTap: tabsRouter.setActiveIndex,
        items: [
          BottomNavigationBarItem(label: 'Books', ...),
          BottomNavigationBarItem(label: 'Profile', ...),
          BottomNavigationBarItem(label: 'Settings', ...),
        ],
      ),
    );
  },
);
```

### Using TabBar

Use the `AutoTabsRouter.tabBar` constructor to implement tabs using TabBar

```dart
AutoTabsRouter.tabBar(
  routes: [
    BooksTab(),
    ProfileTab(),
    SettingsTab(),
  ],
  builder: (context, child, controller) {
    final tabsRouter = AutoTabsRouter.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.topRoute.name),
        leading: AutoLeadingButton(),
        bottom: TabBar(
          controller: controller,
          tabs: const [
            Tab(text: '1', icon: Icon(Icons.abc)),
            Tab(text: '2', icon: Icon(Icons.abc)),
            Tab(text: '3', icon: Icon(Icons.abc)),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabsRouter.activeIndex,
        onTap: tabsRouter.setActiveIndex,
        items: [
          BottomNavigationBarItem(label: 'Books',...),
          BottomNavigationBarItem(label: 'Profile',...),
          BottomNavigationBarItem(label: 'Settings',...),
        ],
      ),
    );
  },
);
```

## Finding The Right Router

Every nested `AutoRouter` has its own routing controller to manage the stack inside of it and the easiest way to obtain a scoped controller is by using the `BuildContext`.

In the previous example, `DashboardPage` is a root level stack entry so calling `AutoRouter.of(context)` anywhere inside of it will get us the root routing controller.

`AutoRouter` widgets that are used to render nested routes, insert a new router scope into the widgets tree, so when a nested route calls for the scoped controller, they will get the closest parent controller in the widgets tree; not the root controller.

```dart
class Dashboard extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    // this will get us the root routing controller
    AutoRouter.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard page')),
      // this inserts a new router scope into the widgets tree
      body: AutoRouter()
    );
  }
}
```

Here's a simple diagram to help visualize this

<p align="center">
  <img  alt="scoped-router-demo" src="https://raw.githubusercontent.com/Milad-Akarie/auto_route_library/master/art/scoped_routers_demo.png" height="570">
</p>

As you can tell from the above diagram it's possible to access parent routing controllers by calling `router.parent<T>()`, we're using a generic function because we have two different routing controllers: `StackRouter` and `TabsRouter`, one of them could be the parent controller of the current router and that's why we need to specify a type.

```dart
router.parent<StackRouter>() // this returns  the parent router as a Stack Routing controller
router.parent<TabsRouter>() // this returns the parent router as a Tabs Routing controller
```

On the other hand, obtaining the root controller does not require type casting because it's always a `StackRouter`.

```dart
router.root // this returns the root router as a Stack Routing controller
```

You can obtain access to inner-routers from outside their scope using a global key

```dart
class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _innerRouterKey = GlobalKey<AutoRouterState>();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            NavLink(
              label: 'Users',
              onTap: () {
                final router = _innerRouterKey.currentState?.controller;
                router?.push(const UsersRoute());
              },
            ),
            ...
          ],
        ),
        Expanded(
          child: AutoRouter(key: _innerRouterKey),
        ),
      ],
    );
  }
}
```

You could also obtain access to inner-routers from outside their scope without a global key, as long as they're initiated.

```dart
// assuming this is the root router
context.innerRouterOf<StackRouter>(UserRoute.name);
// or if we're using an AutoTabsRouter inside of DashboardPage
context.innerRouterOf<TabsRouter>(UserRoute.name);
```

Accessing the `DashboardPage` inner router from the previous example.

```dart
class Dashboard extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              // accessing the inner router from
              // outside the scope
              final router = context.innerRouterOf<StackRouter>(DashboardRoute.name)
              router?.push(const UsersRoute());
            },
          ),
        ],
      ),
      body: AutoRouter(), // we're trying to get access to this
    );
  }
}
```

## Navigating Without Context

To navigate without context you can simply assign your generated router to a global variable

```dart
// declare your route as a global variable
final appRouter = AppRouter();

class MyApp extends StatefulWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter.config(),
    );
  }
}
```

**Note:** Using global variable is not recommended and is considered bad practice and most of the times you should use dependency injection instead.

Here's an example using `get_it` (which is just a personal favorite). You can use any dependency injection package you like.

```dart
void main(){
  // make sure you register it as a Singleton or a lazySingleton
  getIt.registerSingleton<AppRouter>(AppRouter());
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();

    return MaterialApp.router(
      routerConfig: appRouter.config(),
    );
  }
}
```

Now you can access your router anywhere inside of your app without using context.

```dart
getIt<AppRouter>().push(...);
```

**Note:** Navigating without context is not recommended in nested navigation unless you use `navigate` instead of `push` and you provide a full hierarchy, e.g `router.navigate(SecondRoute(children: [SubChild2Route()]))`

## Deep Linking

**AutoRoute** will automatically handle deep-links coming from the platform, but native platforms require some setup, see [Deep linking topic](https://docs.flutter.dev/ui/navigation/deep-linking) in flutter documentation.

### Using Deep-link Transformer

Deep link transformer intercepts deep-links before they're processed by the matcher, it's useful for stripping or modifying deep-links before they're matched.

In the following example we will strip a prefix from the deep-link before it's matched.

```dart
MaterialApp.router(
  routerConfig: _appRouter.config(
    deepLinkTransformer: (uri) {
      if (uri.path.startsWith('/prefix')) {
        return SynchronousFuture(
        uri.replace(path: uri.path.replaceFirst('/prefix', '')),
          );
      }  
      return SynchronousFuture(uri);
    }
  ),
);
```
**Note** for prefix stripping use the shipped-in `DeepLink.prefixStripper('prefix')`

```dart
MaterialApp.router(
  routerConfig: _appRouter.config(
    deepLinkTransformer: DeepLink.prefixStripper('prefix'),
  ),
);
```

```dart
### Using Deep-link Builder

Deep link builder is an interceptor for deep-links where you can validate or override deep-links coming from the platform.

In the following example we will only allow deep-links starting with `/products`

```dart
MaterialApp.router(
  routerConfig: _appRouter.config(
    deepLinkBuilder: (deepLink) {
      if (deepLink.path.startsWith('/products')) {
        // continue with the platform link
        return deepLink;
      } else {
        return DeepLink.defaultPath;
        // or DeepLink.path('/')
        // or DeepLink([HomeRoute()])
      }
    }
  ),
);
```

### Deep Linking to non-nested Routes

**AutoRoute** can build a stack from a linear route list as long as they're ordered properly and can be matched as prefix, e.g `/` is a prefix match of `/products`, and `/products` is prefix match of `/products/:id`. Then we have a setup that looks something like this:
- `/`
- `/products`
- `/products/:id`

Now, receiving this deep-link `/products/123` will add all above routes to the stack. This of course requires `includePrefixMatches` to be true in the root config (default is `!kWeb`) or when using `pushNamed`, `navigateNamed` and `replaceNamed`.

**Things to keep in mind**:

- If a full match can not finally be found, no prefix matches will be included.
- Paths that require a full path match => `AutoRoute(path:'path', fullMatch: true)` will not be
  included as prefix matches.
- In the above example, if `/products/:id` comes before `/products`, `/products` will not be
  included.

## Declarative Navigation

To use declarative navigation with auto_route, you simply use the `AutoRouter.declarative` constructor and return a list of routes based on state.

```dart
AutoRouter.declarative(
  routes: (handler) => [
    BookListRoute(),
    if(_selectedBook != null) {
      BookDetailsRoute(id: _selectedBook.id),
    }
  ],
);
```

**Note:** The handler contains a temp-list of pending initial routes which can be read only once.

## Working with Paths

Working with paths in **AutoRoute** is optional because `PageRouteInfo` objects are matched by name unless pushed as a string using the `deepLinkBuilder` property in root delegate or `pushNamed`, `replaceNamed` `navigateNamed` methods.

If you don’t specify a path it’s going to be generated from the page name e.g. `BookListPage` will have ‘book-list-page’ as a path, if initial arg is set to true the path will be `/`, unless it's relative then it will be an empty string `''`.

When developing a web application or a native app that requires deep-linking, you'd probably need to define paths with clear memorable names, and that's done using the `path` argument in `AutoRoute`.

```dart
AutoRoute(path: '/books', page: BookListPage),
```

### Path Parameters (dynamic segments)

You can define a dynamic segment by prefixing it with a colon

```dart
AutoRoute(path: '/books/:id', page: BookDetailsPage),
```

The simplest way to extract path parameters from path and gain access to them is by annotating constructor params with `@PathParam('optional-alias')` with the same alias/name of the segment.

```dart
class BookDetailsPage extends StatelessWidget {
  const BookDetailsPage({@PathParam('id') this.bookId});

  final int bookId;
  ...
}
```

Now writing `/books/1` in the browser will navigate you to `BookDetailsPage` and automatically extract the `bookId` argument from path and inject it to your widget.

#### Inherited Path Parameters

To inherit a path-parameter from a parent route's path, we need to use `@PathParam.inherit` annotation in the child route's constructor. Let's say we have the following setup:

```dart
AutoRoute(
  path: '/product/:id',
  page: ProductRoute.page,
  children: [
    AutoRoute(path: 'review',page: ProductReviewRoute.page),
  ],
)
```

Now `ProductReviewScreen` expects a path-param named `id` but, from the above snippet we know that the path corresponding with it. `review` has no path parameters, but we can inherit 'id' from the parent `/product/:id` like follows:

```dart
@RoutePage()
class ProductReviewScreen extends StatelessWidget {
  // the path-param 'id' will be inherited and it can not be passed
  // as a route arg by user
  const ProductReviewScreen({super.key, @PathParam.inherit('id') required String id});
}
```

### Query Parameters

Query parameters are accessed the same way, simply annotate the constructor parameter to hold the value of the query param with `@QueryParam('optional-alias')` and let **AutoRoute** do the rest.

You could also access path/query parameters using the scoped `RouteData` object.

```dart
RouteData.of(context).pathParams;
// or using the extension
context.routeData.queryParams;
```

`Tip`: if your parameter name is the same as the path/query parameter, you could use the const `@pathParam` or `@queryParam` and not pass a slug/alias.

```dart
@RoutePage()
class BookDetailsPage extends StatelessWidget {
  const BookDetailsPage({@pathParam this.id});

  final int id;
  ...
}
```

### Redirecting Paths

Paths can be redirected using `RedirectRoute`. The following setup will navigate us to `/books` when `/` is matched.

```dart
<AutoRoute> [
  RedirectRoute(path: '/', redirectTo: '/books'),
  AutoRoute(path: '/books', page: BookListRoute.page),
]
```

When redirecting initial routes the above setup can be simplified by setting the `/books` path as initial and **AutoRoute** will automatically generate the required redirect code for you.

```dart
<AutoRoute> [
  AutoRoute(path: '/books', page: BookListRoute.page, initial: true),
]
```

You can also redirect paths with params like follows:

```dart
<AutoRoute> [
  RedirectRoute(path: 'books/:id', redirectTo: '/books/:id/details'),
  AutoRoute(path: '/books/:id/details', page: BookDetailsRoute.page),
]
```

**Note**: `RedirectRoutes` are fully matched.

### Wildcards

**AutoRoute** supports wildcard matching to handle invalid or undefined paths.

```dart
AutoRoute(
  path: '*',
  page: UnknownRoute.page,
)
// it could be used with defined prefixes
AutoRoute(
  path: '/profile/*',
  page: ProfileRoute.page,
)
// or it could be used with RedirectRoute
RedirectRoute(
  path: '*',
  redirectTo: '/',
)
```

**Note:** Be sure to always add your wildcards at the end of your route list because routes are matched in order.

## Route Guards

Think of route guards as middleware or interceptors, routes can not be added to the stack without going through their assigned guards. Guards are useful for restricting access to certain routes.

We create a route guard by extending `AutoRouteGuard` from the **AutoRoute** package and implementing our logic inside of the onNavigation method.

```dart
class AuthGuard extends AutoRouteGuard {

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    // the navigation is paused until resolver.next() is called with either
    // true to resume/continue navigation or false to abort navigation
    if(authenticated) {
      // if user is authenticated we continue
      resolver.next(true);
    } else {
        // we redirect the user to our login page
        // tip: use resolver.redirect to have the redirected route
        // automatically removed from the stack when the resolver is completed
        resolver.redirect(
          LoginRoute(onResult: (success) {
            // if success == true the navigation will be resumed
            // else it will be aborted
            resolver.next(success);
          },
        );
      );
    }
  }
}
```

**Important**:  `resolver.next()` should only be called once.

The `NavigationResolver` object contains the guarded route which you can access by calling the property `resolver.route` and a list of pending routes (if there are any) accessed by calling `resolver.pendingRoutes`.

Now we assign our guard to the routes we want to protect.

```dart
AutoRoute(
  page: ProfileRoute.page,
  guards: [AuthGuard()],
);
```

#### Guarding all stack-routes

You can have all your stack-routes (non-tab-routes) go through a global guard by having your router implement an AutoRouteGuard. Lets say you have an app with no publish screens, we'd have a global guard that only allows navigation if the user is authenticated or if we're navigating to the LoginRoute.

```dart
@AutoRouterConfig()
class AppRouter extends $AppRouter implements AutoRouteGuard {

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if(isAuthenticated || resolver.route.name == LoginRoute.name) {
      // we continue navigation
      resolver.next();
    } else {
        // else we navigate to the Login page so we get authenticated

        // tip: use resolver.redirect to have the redirected route
        // automatically removed from the stack when the resolver is completed
      resolver.redirect(LoginRoute(onResult: (didLogin) => resolver.next(didLogin)));
    }
  }
  // ..routes[]
}
```

 

### Using a Reevaluate Listenable

Route guards can prevent users from accessing private pages until they're logged in for example, but auth state may change when the user is already navigated to the private page, to make sure private pages are only accessed by logged-in users all the time, we need a listenable that tells the router that the auth state has changed and you need to re-evaluate your stack.

The following auth provider mock will act as our re-valuate listenable

```dart
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}
```

We simply pass an instance of our `AuthProvider` to `reevaluateListenable` inside of `router.config`

```dart
MaterialApp.router(
  routerConfig: _appRouter.config(
    reevaluateListenable: authProvider,
  ),
);
```

Now, every time `AutoProvider` notifies listeners, the stack will be re-evaluated and `AutoRouteGuard.onNavigation()`. Methods will be re-called on all guards

In the above example, we assigned our `AuthProvider` to `reevaluateListenable` directly, that's because `reevaluateListenable` takes a `Listenable` and AuthProvider extends `ChangeNotifier` which is a `Listenable`, if your auth provider is a stream you can use `reevaluateListenable: ReevaluateListenable.stream(YOUR-STREAM)`

**Note**: When the Stack is re-evaluated, the whole existing hierarchy will be re-pushed, so if you want to stop re-evaluating routes at some point, use `resolver.resolveNext(<options>)` which is like `resolver.next()` but with more options.

```dart
@override
void onNavigation(NavigationResolver resolver, StackRouter router) async {
  if (authProvider.isAuthenticated) {
    resolver.next();
  } else {
    resolver.redirect(
      WebLoginRoute(
        onResult: (didLogin) {
          // stop re-pushing any pending routes after current
          resolver.resolveNext(didLogin, reevaluateNext: false);
        },
      ),
    );
  }
}
```

## Wrapping Routes

In some cases we want to wrap our screen with a parent widget, usually to provide some values through context, e.g wrapping your route with a custom `Theme` or a `Provider`. To do that, simply implement `AutoRouteWrapper`, and have wrappedRoute(context) method return (this) as the child of your wrapper widget.

```dart
@RoutePage()
class ProductsScreen extends StatelessWidget implements AutoRouteWrapper {
  
  @override
  Widget wrappedRoute(BuildContext context) {
    return Provider(create: (ctx) => ProductsBloc(), child: this);
  }
  ...
}
```



## Navigation Observers

Navigation observers are used to observe when routes are pushed ,replaced or popped ..etc.

We implement an AutoRouter observer by extending an `AutoRouterObserver` which is just a `NavigatorObserver` with tab route support.

```dart
class MyObserver extends AutoRouterObserver {

  @override
  void didPush(Route route, Route? previousRoute) {
    print('New route pushed: ${route.settings.name}');
  }

 // only override to observer tab routes
  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) {
    print('Tab route visited: ${route.name}');
  }

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) {
    print('Tab route re-visited: ${route.name}');
  }
}
```

Then we pass our observer to the `<routerName>.config().` **Important:** Notice that `navigatorObservers` property is a builder function that returns a list of observers and the reason for that is a navigator observer instance can only be used by a single router, so unless you're using a single router or you don't want your nested routers to inherit observers, make sure navigatorObservers builder always returns fresh observer instances.

```dart
return MaterialApp.router(
  routerConfig: _appRouter.config(
    navigatorObservers: () => [MyObserver()],
  ),
);
```

The following approach **won't** work if you have nested routers unless they don't inherit the observers.

```dart
final _observer = MyObserver();
return MaterialApp.router(
  routerConfig: _appRouter.config(
    // this should always return new instances
    navigatorObservers: () => [_observer],
  ),
);
```

Every nested router can have it's own observers and inherit it's parent's.

```dart
AutoRouter(
  inheritNavigatorObservers: true, // true by default
  navigatorObservers:() => [list of observers],
);

AutoTabsRouter(
  inheritNavigatorObservers: true, // true by default
  navigatorObservers:() => [list of observers],
);
```

We can also make a certain screen **route** aware by subscribing to an `AutoRouteObserver` (route not router).

First we provide our `AutoRouteObserver` instance

```dart
return MaterialApp.router(
  routerConfig: _appRouter.config(
    navigatorObservers: () => [AutoRouteObserver()],
  ),
);
```

Next, we use an `AutoRouteAware` mixin which is a `RouteAware` mixin with tab support to provide the needed listeners, then subscribe to our `AutoRouteObserver`.

```dart
class BooksListPage extends State<BookListPage> with AutoRouteAware {
  AutoRouteObserver? _observer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RouterScope exposes the list of provided observers
    // including inherited observers
    _observer = RouterScope.of(context).firstObserverOfType<AutoRouteObserver>();
    if (_observer != null) {
      // we subscribe to the observer by passing our
      // AutoRouteAware state and the scoped routeData
      _observer.subscribe(this, context.routeData);
    }
  }

 @override
  void dispose() {
    super.dispose();
    // don't forget to unsubscribe from the
    // observer on dispose
    _observer.unsubscribe(this);
  }

  // only override if this is a tab page
  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {}

  // only override if this is a tab page
  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {}

  @override
  void didPopNext() {}

  @override
  void didPushNext() {}

  @override
  void didPush() {}

  @override
  void didPop() {}
}
```

#### AutoRouteAwareStateMixin

The above code can be simplified using `AutoRouteAwareStateMixin`

```dart
class BooksListPage extends State<BookListPage> with AutoRouteAwareStateMixin<BookListPage> {
  // only override if this is a tab page
  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {}

  // only override if this is a tab page
  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {}

  // only override if this is a stack page
  @override
  void didPopNext() {}
  
  // only override if this is a stack page
  @override
  void didPushNext() {}
}
```

## Customizations

##### MaterialAutoRouter | CupertinoAutoRouter | AdaptiveAutoRouter

| Property                    | Default value         | Definition                                                                        |
|-----------------------------|-----------------------|-----------------------------------------------------------------------------------|
| replaceInRouteName [String] | Page&#124Screen,Route | Used to replace conventional words in generated route name (pattern, replacement) |

## Custom Route Transitions

To use custom route transitions use a `CustomRoute` and pass in your preferences. The `TransitionsBuilder` function needs to be passed as a static/const reference that has the same signature as the `TransitionsBuilder` function of the `PageRouteBuilder` class.

```dart
CustomRoute(
  page: LoginRoute.page,
  // TransitionsBuilders class contains a preset of common transitions builders.
  transitionsBuilder: TransitionsBuilders.slideBottom,
  durationInMilliseconds: 400,
)
```

`Tip:` Override `defaultRouteType` in generated router to define global custom route transitions.

You can of course use your own transitionsBuilder function, as long as it has the same function signature. The function has to take in exactly one `BuildContext`, `Animation<Double>`, `Animation<Double>` and a child `Widget` and it needs to return a `Widget`. Typically, you would wrap your child with one of Flutter's transition widgets as follows:

```dart
CustomRoute(
  page: ZoomInScreen,
  transitionsBuilder:
    (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
      // you get an animation object and a widget
      // make your own transition
      return ScaleTransition(scale: animation, child: child);
  },
)
```

## Custom Route Builder

You can use your own custom route by passing a `CustomRouteBuilder` function to `CustomRoute' and implement the builder function the same way we did with the TransitionsBuilder function, the most important part here is passing the page argument to our custom route.

```dart
CustomRoute(
  page: CustomPage,
  customRouteBuilder: (BuildContext context, Widget child, CustomPage<T> page) {
    return PageRouteBuilder(
      fullscreenDialog: page.fullscreenDialog,
      // this is important
      settings: page,
      pageBuilder: (_,__,___) => child,
    );
  },
)
```

## Others

### Including Micro/External Packages

To include routes inside of a depended-on package, that package needs to generate an `AutoRouterModule` that will be later consumed by the root router.

To have a package output an `AutoRouterModule` instead of a `RootStackRouter`, we need to use the `AutoRouterConfig.module()` annotation like follows

```dart
@AutoRouterConfig.module()
class MyPackageModule extends $MyPackageModule {}
```

Then when setting up our root router we need to tell it to include the generated module.

```dart
@AutoRouterConfig(modules: [MyPackageModule])
class AppRouter extends $AppRouter {}
```

Now you can use `PageRouteInfos` generated inside `MyPackageModule`.

`Tip:` You can add export `MyPackageModule` to `app_router.dart`, so you only import `app_router.dart` inside of your code.

```dart
// ...imports
export 'package:my_package/my_package_module.dart'
@AutoRouterConfig(modules: [MyPackageModule])
class AppRouter extends $AppRouter {}
```

## Configuring builders
To pass builder configuration to `auto_route_generator` we need to add `build.yaml` file next to `pubspec.yaml` if not already added.

```yaml
targets:
  $default:
    builders:
      auto_route_generator:auto_route_generator:
      # configs for @RoutePage() generator ...
      auto_route_generator:auto_router_generator:
      # configs for @AutoRouterConfig() generator ...
```

### Passing custom ignore_for_file rules
You can pass custom ignore_for_file rules to the generated router by adding the following:

```yaml
targets:
  $default:
    builders:
      auto_route_generator:auto_router_generator:
       options:
         ignore_fore_file:
           - custom_rule_1
           - custom_rule_2
```

### Optimizing generation time
The first thing you want to do to reduce generation time, is specifying the files build_runner should process and we do that by using [globs](https://pub.dev/packages/glob). Globs are kind of regex patterns with little differences that's used to match file names. **Note:** for this to work on file level you need to follow a naming convention

```
let's say we have the following files tree
├── lib
│ ├── none_widget_file.dart
│ ├── none_widget_file2.dart
│ └── ui
│ ├── products_screen.dart
│ ├── products_details_screen.dart
```

By default, the builder will process all of these files to check for a page with `@RoutePage()`
annotation, we can help by letting it know what files we need processed, e.g only process the files
inside the ui folder:
**Note** (**) matches everything including '/';

```yaml
targets:
  $default:
    builders:
      auto_route_generator:auto_route_generator:
        generate_for:
          - lib/ui/**.dart
```

Let's say you have widget files inside of the ui folder, but we only need to process files ending with `_screen.dart`

```yaml
targets:
  $default:
    builders:
      auto_route_generator:auto_route_generator:
        generate_for:
          - lib/ui/**_screen.dart
```

Now only `products_screen.dart`, `products_details_screen.dart` will be processed

The same goes for `@AutoRouterConfig` builder

```yaml
targets:
  $default:
    builders:
      auto_route_generator:auto_route_generator: # this for @RoutePage
        generate_for:
          - lib/ui/**_screen.dart
      auto_route_generator:auto_router_generator: # this for @AutoRouterConfig
        generate_for:
          - lib/ui/router.dart
```

## Enabling cached builds

**This is still experimental**
When cached builds are enabled, **AutoRoute** will try to prevent redundant re-builds by analyzing whether the file changes has any effect on the extracted route info, e.g any changes inside of the build method should be ignored.

**Note** Enable cached builds on both generators

```yaml
targets:
  $default:
    builders:
      auto_route_generator:auto_route_generator: # this for @RoutePage
        options:
          enable_cached_builds: true
        generate_for:
          - lib/ui/**_screen.dart
      auto_route_generator:auto_router_generator: # this for @AutoRouterConfig
        options:
          enable_cached_builds: true
        generate_for:
          - lib/ui/router.dart
```

### AutoLeadingButton-BackButton

`AutoLeadingButton` is **AutoRoute**'s replacement to the default BackButton to handle nested or parent stack popping. To use it, simply assign it to the `leading` property inside of `AppBar`

```dart
AppBar(
  title: Text(context.topRoute.name),
  leading: AutoLeadingButton(),
)
```

### ActiveGuardObserver

`ActiveGuardObserver` can notify you when a guard is being checked and what guard it is. This can be used to implement a loading indicator for example.

```dart
var isLoading = false;
void initState(){
  final guardObserver = context.router.activeGuardObserver;

  guardObserver.addListener(() {
    setState((){
      isLoading = guardObserver.guardInProgress;
    });
  });
}
```


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

## Examples

coming soon

### Support auto_route

You can support auto_route by liking it on Pub and staring it on Github, sharing ideas on how we can enhance a certain functionality or by reporting any problems you encounter and of course buying a couple coffees will help speed up the development process