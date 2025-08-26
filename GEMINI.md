## Development Stack with Flutter

- Flutter app, with provider and go_router for frontend
- Always prefer type-safe alternative to `dynamic`, `late` and other risky behaviors
- Do not cast with `as` keyword, but always prefer pattern matching to safely cast and test types
- Never use the `dynamic` keyword but prefer `Object?` which is safer
- Always use flutter theme extension to allow UI customization, for every group of UI widgets you build, add a theme extension and refer to hit using context to customize the widgets.
- Always prefer `developer.log` to `print()` and `debugPrint()`
- Please don't unwrap `state.pathParameters['id']!;` nor cast unsafely `state.extra as TarotCard;`. Prefer usage of lib `package:castor/castor.dart` and convert to `state.extra.castOrNull<TarotCard>()` and works with nullable.
- Firebase as backend
- For provider, prefer usage of `context.read()`, `context.select()` and `context.watch()` instead of `Consumer<Xxx>`
- Prefer to arbitraty string based routing `context.go('/draw')`  using routes definitions declared in there target screen, like : `context.go(DrawScreen.route)`, dans when route does have parameters, please generate method to build them, do `context.go(ReadingScreen.routeDetails(id: newReadingId)` instead of `context.go('/reading/$newReadingId')`.
- All code and documentation in English