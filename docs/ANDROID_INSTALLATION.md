# Creator Yard Android Installation

Creator Yard provides an Android release APK through GitHub Actions.

## Get the APK

1. Open the Creator Yard GitHub repository.
2. Open **Actions**.
3. Select **Creator Yard Android Release**.
4. Select **Run workflow**.
5. Wait for the workflow to finish successfully.
6. Open the completed workflow run.
7. Under **Artifacts**, download:
   `creator-yard-release-apk`
8. Extract the downloaded artifact to get:
   `app-release.apk`.

## Install on Android

Transfer `app-release.apk` to the Android device.

Open the APK and allow installation from the requested source if Android asks for permission.

Install and open **Creator Yard**.

## Licensing

The APK is the standard release build.

Commercial activation is handled through the Creator Yard licensing and administration system. The APK does not require a special commercial build command.

If the installation requires activation, complete the normal Creator Yard registration and licensing process.

## Build Details

The release workflow uses:

- Flutter 3.44.4
- Java 17
- Ubuntu GitHub Actions runner
- `flutter build apk --release`

The generated APK is:

```text
build/app/outputs/flutter-apk/app-release.apk

```
