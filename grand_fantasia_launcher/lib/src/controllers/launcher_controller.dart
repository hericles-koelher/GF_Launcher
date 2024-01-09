import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:grand_fantasia_launcher/src/utils/environment_variables.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class LauncherController {
  static const versionFileName = ".version";
  static const initialVersion = "0.0";

  List<(String, String)>? _metadata;

  LauncherController();

  bool get isMetadataLoaded => _metadata != null;

  Future<void> downloadMetadata() async {
    final response = await http.get(Uri.parse(EnvironmentVariables.versionUrl));

    if (response.statusCode != 200) {
      throw const HttpException('Failed to get metadata');
    }

    _metadata = (jsonDecode(response.body) as List)
        .cast<Map<String, dynamic>>()
        .map(
          (item) => (item['version']! as String, item['url']! as String),
        )
        .toList();

    debugPrint('Metadata: $_metadata');
  }

  Future<String> _getCurrentLocalVersion() async {
    final localVersionFile =
        File(path.join(Directory.current.path, versionFileName));

    if (!(await localVersionFile.exists())) {
      await localVersionFile.create();
      await localVersionFile.writeAsString(initialVersion);
    }

    return await localVersionFile.readAsString();
  }

  Future<void> _updateCurrentLocalVersion(String version) async {
    debugPrint('Updating Local Version to $version');

    final localVersionFile =
        File(path.join(Directory.current.path, versionFileName));

    await localVersionFile.writeAsString(version);
  }

  Future<(String, bool)> isUpdated() async {
    if (_metadata == null) {
      await downloadMetadata();
    }

    final currentLocalVersion = await _getCurrentLocalVersion();

    return currentLocalVersion == _metadata!.last.$1
        ? (currentLocalVersion, true)
        : (currentLocalVersion, false);
  }

  Future<void> _updateVersion({
    required String version,
    required String updateUrl,
    required double progressUntilNow,
    required double progressFactor,
    void Function(double progress)? progressCallback,
  }) async {
    final client = http.Client();

    final request = http.Request(
      'GET',
      Uri.parse(updateUrl),
    );

    final response = await client.send(request);

    if (response.statusCode != 200) {
      throw const HttpException('Failed to get update');
    }

    final tempFile =
        File(path.join(Directory.current.path, 'update-$version.tmp'));
    final sink = tempFile.openWrite();

    final totalBytes = response.contentLength ?? 0;
    var downloadedBytes = 0;

    final streamController = StreamController<int>();

    streamController.stream.listen((int chunk) {
      downloadedBytes += chunk;

      final progress = (downloadedBytes / totalBytes);

      //debugPrint('Download Update $version Progress: ${((progress) * 100).toStringAsFixed(2)}%');

      progressCallback?.call(progressUntilNow + progress * progressFactor / 2);
    });

    await response.stream.map((List<int> chunk) {
      streamController.add(chunk.length);
      return chunk;
    }).pipe(sink);

    await streamController.close();
    await sink.close();

    final archive = await compute(
      (bytes) => ZipDecoder().decodeBytes(bytes),
      await tempFile.readAsBytes(),
    );

    final numberOfFiles = archive.files.length;
    var currentFileIndex = 0;

    debugPrint('File Update $version Progress: 0%');

    for (var file in archive.files) {
      if (file.isFile) {
        await compute(
          (file) async {
            final newFile = File(
              path.join(
                Directory.current.path,
                file.name == EnvironmentVariables.launcherFileName
                    ? '${EnvironmentVariables.launcherFileName}.tmp'
                    : file.name,
              ),
            );

            if (!(await newFile.exists())) {
              newFile.createSync(recursive: true);
            }

            await newFile.writeAsBytes(file.content);
          },
          file,
        );

        currentFileIndex++;

        //debugPrint('File Update Progress: ${((currentFileIndex / numberOfFiles) * 100).toStringAsFixed(2)}%');

        progressCallback?.call(progressUntilNow +
            progressFactor / 2 +
            (currentFileIndex / numberOfFiles) * (progressFactor / 2));
      }
    }

    await tempFile.delete();

    await _updateCurrentLocalVersion(version);
  }

  Future<void> update(
    void Function(double progress)? progressCallback,
  ) async {
    final currentLocalVersion = await _getCurrentLocalVersion();

    final startIndex =
        _metadata!.indexWhere((item) => item.$1 == currentLocalVersion);

    if (startIndex == _metadata!.length - 1) {
      debugPrint('Already Updated');

      return;
    }

    final updates = _metadata!.sublist(startIndex + 1);

    progressCallback?.call(0);

    final progressFactor = 1.0 / updates.length;

    for (var indexedUpdate in updates.indexed) {
      await _updateVersion(
        version: indexedUpdate.$2.$1,
        updateUrl: indexedUpdate.$2.$2,
        progressUntilNow: indexedUpdate.$1 * progressFactor,
        progressFactor: progressFactor,
        progressCallback: progressCallback,
      );
    }

    progressCallback?.call(1.0);
  }

  Future<void> startGame({bool updateLauncher = false}) async {
    debugPrint('Starting Game');

    await Process.start(
      path.join(Directory.current.path, EnvironmentVariables.exeFileName),
      [],
    );

    debugPrint('Game Started');

    if (updateLauncher) {
      debugPrint('Starting Launcher Updater');

      await Process.start(
        path.join(
          Directory.current.path,
          EnvironmentVariables.launcherUpdaterFileName,
        ),
        [],
        environment: {
          "LAUNCHER_FILE_NAME": EnvironmentVariables.launcherFileName
        },
        runInShell: true,
      );

      debugPrint('Launcher Updater Started');
    }
  }
}
