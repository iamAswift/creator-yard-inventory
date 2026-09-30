# Creator Yard Windows Installation

Creator Yard provides a Windows release through GitHub Actions.

## Get the Windows Release

1. Open the Creator Yard GitHub repository.

2. Open **Actions**.

3. Select **Creator Yard Windows Release**.

4. Select **Run workflow**.

5. Wait for the workflow to finish successfully.

6. Open the completed workflow run.

7. Under **Artifacts**, download:

   `creator-yard-windows-release`

8. Extract the downloaded artifact.

The extracted folder contains the Windows application files.

## Install on Windows

Extract the downloaded release artifact to a suitable folder on the Windows computer.

Open the extracted release folder.

Launch:

`supermarket_inventory.exe`

Windows may display a security prompt the first time the application is opened. If the application is trusted, allow it to run.

## Licensing

The Windows release is the standard release build.

Commercial activation is handled through the Creator Yard licensing and administration system. The installation does not require a separate commercial build.

If the installation requires activation, complete the normal Creator Yard registration and licensing process.

## Build Details

The release workflow uses:

* Flutter 3.44.4
* Windows GitHub Actions runner
* `flutter build windows --release`

The generated Windows application is located at:

```text
build/windows/x64/runner/Release/
```
