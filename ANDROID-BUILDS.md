# Android test and production builds

## Test APK

From this app's directory:

```sh
flutter build apk
```

This builds the release-optimized APK with Android's automatic **debug signing
key** for local installation/testing. No registered application ID, production
keystore or `key.properties` is required. The output is
`build/app/outputs/flutter-apk/app-release.apk`.

For a Flutter debug build with debugging support:

```sh
flutter build apk --debug
# Or run on a connected device:
flutter run
```

The debug APK is `build/app/outputs/flutter-apk/app-debug.apk`.

## Production signing

Copy `android/key.properties.example` to `android/key.properties` and supply
your existing production upload key and registered application ID. The real
file and keystores are ignored by Git. Application ID lookup supports a Gradle
property, environment variable, `android/local.properties`, or `applicationId`
in `android/key.properties`.

Explicitly enable production signing:

```sh
MARKETGO_PRODUCTION=true flutter build appbundle --release
# Or a production-signed APK:
MARKETGO_PRODUCTION=true flutter build apk --release
```

The flag also supports `-PMARKETGO_PRODUCTION=true` for direct Gradle invocations
or `MARKETGO_PRODUCTION=true` in the ignored `android/local.properties`.
Production mode rejects missing/placeholder identities and incomplete signing
configuration. It does not fall back to a test key when production is requested.
Only `true` and `false` are accepted flag values.

Test-signed APKs cannot update an installed app signed with a different key.
Use production signing for store distribution and updates to existing releases.
