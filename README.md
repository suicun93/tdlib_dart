TDLib for Dart (WIP)
===

A port of the Telegram Database Library (TDLib) for Dart.

## How To Use It

### 1: Building TDLib

You'll need to download and build TDLib yourself. You can figure out how to do that 
[here](https://tdlib.github.io/td/build.html?language=Other) (just select your OS, 
don't change the language option). It doesn't especially matter where you build it, as
long as the path to the root directory of TDLib is passed to the `TelegramClient()`.

### 2: Including This Project

As it's incomplete and requires a lot of setup, I'm not putting this on pub just yet. You have two basic
options for using this.

1. Clone the repository and copy the `lib` directory into your own project folder.
1. (Recommended) Include the following in your `pubspec.yaml` file:

```yaml
dependencies:
  #...
  tdlib:
    git: git://github/periodicaidan/dart_tdlib
  #...
```

### 3: Generating Reflectors

This library has a small reliance on reflection, which isn't allowed in Flutter
because Flutter does "tree shaking" to eliminate unused classes, which wouldn't work
if there is code that's dynamically parsed and run from strings, as it wouldn't be able
to safely eliminate anything. So it makes use of [reflectable](https://pub.dev/packages/reflectable), which generates
static code ahead of time to work like dart:mirrors. But you will have to generate the reflectables
yourself. To do this, you can use [build runner](https://pub.dev/packages/build_runner).

Include the following in your `package.yaml` file:

```yaml
dev_dependencies:
  #...
  build_runner: ^1.0.0
  #...
```

Then, make a `build.yaml` file with the following (or add the new parts to your existing `build.yaml` file):

```yaml
targets:
  $default:
    builders:
      reflectable:
        generate_for:
          - path/to/file.dart
        options:
          formatted: true
```

Finaly run `pub run build_runner build`. It *should* only take a few seconds though reflectable has been having some issues recently with long build times.

### 4: Now You're Ready to Rock and Roll

The general structure of a program using this library is something like this:

```dart
// tdlib_ex.dart
import 'package:tdlib/tdlib.dart' as td;
import 'tdlib_ex.reflectable.dart';

Future main() async {
  initializeReflectable();

  final client = td.TelegramClient('path/to/td');

  client.defineTdlibParams(
    // There are other parameters but these four are required!
    apiId: apiId,
    apiHash: apiHash,
    deviceModel: 'PearPhone G1',
    systemVersion: 'PearOS 1.0',
  );
  
  try {
    // Get a stream to handle changes to the authorization state
    // Mind you, there are other authorization states and it's better to switch
    // over [state.runtimeType].
    client.authorizationState.listen((state) async {
      if (state is td.AuthorizationStateWaitTdlibParameters) {
        await client.send(td.SetTdlibParameters(client.tdlibParams));
      }
    });
    
    await for (final update in client.incoming()) {
      // Handle each incoming update
    }
  } finally {
    // Be sure to close the client
    await client.close();
  }
}
```
