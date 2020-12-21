

[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/tterb/atomic-design-ui/blob/master/LICENSEs)

- [Installation](#installation)
- [Setup and Usage](#setup-and-usage)
- [Navigation](#navigation)

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

First create a router config class and annotate it with @MaterialAutoRouter, @CupertinoAutoRouter, @AdaptiveAutoRouter or @CustomAutoRouter. It's name must be prefixed with **\$** to get a generated class with the same name minus the $.
$RouterConfig => RouterConfig

##### Note: using \$ prefix is mandatory.

```dart
@MaterialAutoRouter(...config)  //CustomAutoRoute(..config)
class $MyRouterConfig {}
```

#### Declare your AutoRoutes in MaterialAutoRouter() annotation
* paths are optional, if not provided auto-generated paths will be used.
```dart
@MaterialAutoRouter(
  routes: <AutoRoute>[
    AutoRoute(path: '/': page: HomePage),
    AutoRoute(path: '/books', page: BookListPage),
    AutoRoute(path: '/books/:id', page: BookDetailsPage),
  ],
)
class $AppRouter {}
```

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

after you run the generator your router config class will be generated, use it as follows:
```dart

   final appRouter = AppRouter()
   ...
  Widget build(BuildContext context){
      return MaterialApp.router(
             routerDelegate: appRouter.delegate(...initialConfig),
             routeInformationParser: appRouter.defaultRouteParser(),
         ),
  }
```



## Navigation
---
Use AutoRouter to push PageRouteInfo objects that's generated for you
```dart
AutoRouter.of(context).push(BooksListPageRoute())
// or you can use the extension
context.router.push(BooksListPageRoute())
```
### Support auto_route
You can support auto_route by liking it on Pub and staring it on Github, sharing ideas on how we can enhance a certain functionality or by reporting any problems you encounter
