import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grand_fantasia_launcher/src/utils/environment_variables.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'package:connectivity_plus/connectivity_plus.dart';

class LauncherController {
  static const versionFileName = ".version";

  const LauncherController();

  Future<(String, bool)> isUpdated() async {
    final connResult = await Connectivity().checkConnectivity();

    if (connResult == ConnectivityResult.none) {
      throw const HttpException('No internet connection');
    }

    final response = await http.get(Uri.parse(EnvironmentVariables.versionUrl));

    if (response.statusCode != 200) {
      throw const HttpException('Failed to get version');
    }

    final remoteVersion = response.body;

    debugPrint('Remote Version: $remoteVersion');

    debugPrint('Current Directory: ${Directory.current.path}');

    final localVersionFile =
        File(path.join(Directory.current.path, versionFileName));

    if (!(await localVersionFile.exists())) {
      await localVersionFile.create();
      await localVersionFile.writeAsString('0.0');
    }

    final localVersion = await localVersionFile.readAsString();

    return (remoteVersion, remoteVersion == localVersion);
  }

  Future<void> update(
    String remoteVersion,
    void Function(double progress)? progressCallback,
  ) async {
    final client = http.Client();

    final request = http.Request(
      'GET',
      Uri.parse(EnvironmentVariables.updateUrl),
    );

    final response = await client.send(request);

    if (response.statusCode != 200) {
      throw const HttpException('Failed to get update');
    }

    final tempFile = File(path.join(Directory.current.path, 'update.zip'));
    final sink = tempFile.openWrite();

    final totalBytes = response.contentLength ?? 0;
    var downloadedBytes = 0;

    progressCallback?.call(0);

    debugPrint('Download Update Progress: 0%');

    final streamController = StreamController<int>();

    streamController.stream.listen((int chunk) {
      downloadedBytes += chunk;

      final progress = downloadedBytes / totalBytes;

      debugPrint(
          'Download Update Progress: ${(progress * 100).toStringAsFixed(2)}%');

      progressCallback?.call(progress / 2);
    });

    await response.stream.map((List<int> chunk) {
      streamController.add(chunk.length);
      return chunk;
    }).pipe(sink);

    await streamController.close();
    await sink.close();

    final archive = ZipDecoder().decodeBytes(await tempFile.readAsBytes());

    final numberOfFiles = archive.files.length;
    var currentFileIndex = 0;

    debugPrint('File Update Progress: 0%');

    for (var file in archive.files) {
      if (file.isFile) {
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

        currentFileIndex++;

        debugPrint(
            'File Update Progress: ${((currentFileIndex / numberOfFiles) * 100).toStringAsFixed(2)}%');

        progressCallback?.call(.5 + (currentFileIndex / numberOfFiles) * .5);
      }
    }

    await tempFile.delete();

    final localVersionFile =
        File(path.join(Directory.current.path, versionFileName));

    await localVersionFile.writeAsString(remoteVersion);
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
