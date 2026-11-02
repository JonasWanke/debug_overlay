# debug_overlay_http

Records requests of the [`http`](https://pub.dev/packages/http) package in the `debug_overlay` network inspector.

<img src="https://github.com/JonasWanke/debug_overlay/raw/main/debug_overlay_http/doc/helpers-network.png?raw=true" width="400px" alt="NetworkDebugHelper demo" />

Part of [<kbd>debug_overlay</kbd>](https://pub.dev/packages/debug_overlay).

## Usage

```dart
final networkRequests = NetworkRequestCollection();
final client = DebugHttpClient(networkRequests); // Optionally pass `inner:`.

DebugOverlay.appendTool(NetworkDebugHelper.tool(networkRequests));
```
