# debug_overlay

🐛 View debug infos and change settings via a central overlay for your app.

<img src="https://github.com/JonasWanke/debug_overlay/raw/main/doc/demo.webp?raw=true" width="400px" alt="debug_overlay demo" />

To add a debug overlay to your app, pass `DebugOverlay.builder()` to `MaterialApp`/`CupertinoApp`/`WidgetsApp.builder`:

```dart
MaterialApp(
  builder: DebugOverlay.builder(),
  // And other customization...
)
```

> The debug overlay only works in debug mode and is not included in your widget tree in profile or release mode unless you pass `enableOnlyInDebugMode: false`.

There are two ways to open the debug overlay:

* Shake your phone!
  (You can disable the shake detection by passing `showOnShake: false` to `DebugOverlay.builder`.)
* Call `DebugOverlay.show()`.

By default, this overlay includes `MediaQueryDebugHelper`, `PackageInfoDebugHelper`, and `DeviceInfoDebugHelper`.

## Debug Helpers

To add a debug helper, you have to register it by calling either of the following two (which accept any widget):

* `DebugOverlay.prependHelper(myDebugHelper)` to add it to the front of the list
* `DebugOverlay.appendHelper(myDebugHelper)` to add it to the end of the list

Or, if you want to override all currently registered overlays, set `DebugOverlay.helpers.value` to a list of widgets.

### `DeviceInfoDebugHelper`

<img src="https://github.com/JonasWanke/debug_overlay/raw/main/doc/helpers-deviceInfo.png?raw=true" width="400px" alt="DeviceInfoDebugHelper demo" />

Displays information obtained from [<kbd>device_info_plus</kbd>](https://pub.dev/packages/device_info_plus).

### `MediaQueryDebugHelper`

<img src="https://github.com/JonasWanke/debug_overlay/raw/main/doc/helpers-mediaQuery.png?raw=true" width="400px" alt="´MediaQueryDebugHelper demo" />

Displays information obtained from [`MediaQuery`](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html).

### `LogsDebugHelper`

<img src="https://github.com/JonasWanke/debug_overlay/raw/main/doc/helpers-logs.png?raw=true" width="400px" alt="´LogsDebugHelper demo" />

Displays logs generated by your app. To use it, follow these steps:

1. Store its mutable state, e.g., in a global variable:

    ```dart
    final logs = LogCollection();
    ```

2. Register the helper and supply its state, e.g., in `main()`:

    ```dart
    void main() {
      if (kDebugMode) {
        DebugOverlay.appendHelper(LogsDebugHelper(logs));
      }

      runApp(MyApp());
    }
    ```

3. When you generate logs, add them to the collection.
  Except for `message`, all parameters are optional:

    ```dart
    logs.add(Log(
      level: DiagnosticLevel.info,
      timestamp: DateTime.now(),
      message: 'My message',
      error: myException,
      stackTrace: myStackTrace,
    ));
    ```

> By default, this only stores the last 50 logs. You can customize this via the `maximumSize` parameter of `LogCollection`.
>
> Logs are only stored in debug builds.

### `MediaOverridesDebugHelper`

<img src="https://github.com/JonasWanke/debug_overlay/raw/main/doc/helpers-mediaOverrides.png?raw=true" width="400px" alt="´MediaOverridesDebugHelper demo" />

This allows you to override the theme mode and locale of your app. To use it, follow these steps:

1. Store its mutable state, e.g., in a global variable:

    ```dart
    final mediaOverrideState = ValueNotifier(MediaOverrideState());
    ```

2. Register the helper and supply its state, e.g., in `main()`:

    ```dart
    void main() {
      if (kDebugMode) {
        DebugOverlay.prependHelper(MediaOverrideDebugHelper(
          mediaOverrideState,
          // To support overriding locales, this value must be set and should
          // contain the same locales as passed to [MaterialApp.supportedLocales],
          // [CupertinoApp.supportedLocales] or [WidgetsApp.supportedLocales].
          supportedLocales: supportedLocales,
        ));
      }

      runApp(MyApp());
    }
    ```

3. When building your `MaterialApp`/`CupertinoApp`/`WidgetsApp`, wrap it in a `ValueListenableBuilder` that uses the state from step 1:

    ```dart
    ValueListenableBuilder<MediaOverrideState>(
      valueListenable: mediaOverrideState,
      builder: (context, overrideState, child) {
        return MaterialApp(
          // You can access overridden values via [overrideState]:
          themeMode: overrideState.themeMode,
          locale: overrideState.locale,

          builder: DebugOverlay.builder(showOnShake: false),
          supportedLocales: supportedLocales,

          // And your other customizations...
        );
      },
    );
    ```

### `PackageInfoDebugHelper`

<img src="https://github.com/JonasWanke/debug_overlay/raw/main/doc/helpers-packageInfo.png?raw=true" width="400px" alt="PackageInfoDebugHelper demo" />

Displays information obtained from [<kbd>package_info_plus</kbd>](https://pub.dev/packages/package_info_plus).

<!-- ![Button demo](https://github.com/JonasWanke/black_hole_flutter/raw/master/doc/widgets-buttons.gif?raw=true) -->

### Custom

To implement your own debug helper, you can use the provided `DebugHelper` class for the layout.

If your information can be represented with Flutter's [`DiagnosticsNode`](https://api.flutter.dev/flutter/foundation/DiagnosticsNode-class.html), you can use `DiagnosticsBasedDebugHelper` which automatically provides filtering.
This is also used internally by `DeviceInfoDebugHelper`, `MediaQueryDebugHelper`, and `PackageInfoDebugHelper`.
