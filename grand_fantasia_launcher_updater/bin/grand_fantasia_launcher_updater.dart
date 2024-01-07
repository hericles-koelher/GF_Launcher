import 'dart:io';

import 'package:path/path.dart' as path;

void main() async {
  var launcherFileName = Platform.environment['LAUNCHER_FILE_NAME'];

  var tempLauncherFile =
      File(path.join(Directory.current.path, '$launcherFileName.tmp'));
  var launcherFile = File(path.join(Directory.current.path, launcherFileName));

  var launcherWasUpdated = false;

  while (!launcherWasUpdated) {
    print('Trying to update launcher...');
    print('Time: ${DateTime.now()}');

    try {
      var subscription = tempLauncherFile.openRead().listen(
        (bytes) {
          launcherFile.writeAsBytes(bytes);
        },
        cancelOnError: true,
      );

      await subscription.asFuture();

      await tempLauncherFile.delete();

      launcherWasUpdated = true;

      print('Launcher updated!');
    } catch (e) {
      print('Error: $e');

      sleep(Duration(seconds: 1));
    }
  }
}
