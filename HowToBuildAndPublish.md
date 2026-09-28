# Build and install a Native Alpha release

## Prerequisites

Install JDK 17, Android SDK Command-line Tools, SDK Platform 35, SDK Build
Tools, and Platform Tools (`adb`). The repository includes the Gradle wrapper.
Set `ANDROID_HOME` to your SDK directory.

## Release signing

Local release variants require a private signing key. Keep the keystore and
passwords outside Git and back them up securely. On this machine, the local
configuration is in
`$HOME/.local/share/android-release-signing/nativealpha/signing.env`.

For a new installation, generate a key once:

```bash
install -d -m 700 "$HOME/.local/share/android-release-signing/nativealpha"
keytool -genkeypair -storetype PKCS12 \
  -keystore "$HOME/.local/share/android-release-signing/nativealpha/release.jks" \
  -alias nativealpha -keyalg RSA -keysize 3072 -validity 10000
```

Create a private `signing.env` in the same directory with these exported
variables: `NATIVEALPHA_ANDROID_STORE_FILE` (absolute keystore path),
`NATIVEALPHA_ANDROID_STORE_PASSWORD`, `NATIVEALPHA_ANDROID_KEY_ALIAS`, and
`NATIVEALPHA_ANDROID_KEY_PASSWORD`. Set its permissions to `600`. Never commit
the keystore or the environment file.

## Build and verify

Open this project directory in VS Code and select a configuration from
**Run and Debug**. **Build Full Release** cleans Gradle outputs and builds
signed release artifacts; **Build Release** builds them incrementally.
**Install on Android** installs the existing signed release APK. Both
builds use the same private signing key and verify the APK signature.
The key is created only once per project, not on each build or session.
Set `ANDROID_SERIAL` if more than one device is connected.
Build progress appears in the VS Code **Terminal** tab. The VS Code
launcher needs Node.js on `PATH` or in `$HOME/.local/nodejs/node-v*/bin`.
Its process ends with the build while the terminal keeps the output.

The `extendedGithub` flavor has the public `com.cylonid.nativealpha` package
name. The build creates ABI-specific APKs and a universal APK.

```bash
cd /home/david/Code/NativeAlphaForAndroid
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
source "$HOME/.local/share/android-release-signing/nativealpha/signing.env"
./gradlew :app:assembleExtendedGithubRelease
apk=$(find app/build/outputs/apk/extendedGithub/release \
  -maxdepth 1 -type f -name '*universal*.apk' -print -quit)
test -n "$apk"
"$ANDROID_HOME/build-tools/35.0.0/apksigner" verify --verbose "$apk"
```

The Gradle build temporarily generates Android manifest and activity files.
Its final task restores the source manifest; check `git status --short` after
an interrupted build before committing. Increase `versionCode` in
`app/build.gradle` for each published update.

## Install or copy to a phone

Enable USB debugging on the phone, connect it, and authorize the computer.

```bash
"$ANDROID_HOME/platform-tools/adb" devices -l
"$ANDROID_HOME/platform-tools/adb" install -r "$apk"
```

To copy the APK to Downloads without installing it:

```bash
"$ANDROID_HOME/platform-tools/adb" push "$apk" /sdcard/Download/NativeAlpha-release.apk
```

An update requires the same package name and signing key as the installed app.
A locally signed APK cannot update the upstream publisher's APK or an APK
signed with a previous local debug key. Uninstalling an old app can remove its
local data.
