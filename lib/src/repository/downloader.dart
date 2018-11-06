import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:ruian_api/src/server/configuration.dart';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

class Downloader {
  static final Logger _log = new Logger('Downloader');

  final Configuration _config;

  String get dataDirectory => _config.dataDirectory;

  Downloader(this._config);

  Future<String> downloadUnzipAndRecode(String repoId) async {
    final String repoFileName = '$repoId${_config.filenamePostfix}';
    final String urlToDownload = '${_config.updateUrl}$repoFileName';

    _log.info("Downloading '$urlToDownload'...");
    http.Response res = await http.get(urlToDownload);

    if (res.statusCode != 200) {
      var message =
          "Downloading of '$urlToDownload' failed with status code ${res
          .statusCode}.";
      _log.shout(message);
      throw message;
    }
    _log.info('Downloading is done, new data saved.');

    await new Directory('$dataDirectory').create(recursive: true);
    File zipFile = await new File('$dataDirectory$repoFileName')
      ..create(recursive: true);
    await zipFile.writeAsBytes(res.bodyBytes);
    _log.info("Repository saved as '$dataDirectory$repoFileName' file.");

    List<int> bytes = await zipFile.readAsBytes();
    Archive archive = await new ZipDecoder().decodeBytes(bytes);

    for (ArchiveFile file in archive.files) {
      // Only create recursively files, not directories.
      if (file.isFile) {
        var csvFile = await new File('$dataDirectory$repoId/${file.name}');
        await csvFile.create(recursive: true);
        await csvFile.writeAsBytes(file.content);
      }
    }
    _log.info('Data unzipped to $dataDirectory$repoId directory.');

    _log.info('Starting recoding');
    ProcessResult recodeResult = await Process.run(
        'tool/recode_files.sh', ['$repoId'],
        runInShell: true, workingDirectory: _config.executionPath);

    if (recodeResult.exitCode == 0) {
      _log.info('Finished recoding to UTF-8.');
      _log.info(recodeResult.stdout);
    } else {
      var message = 'Recoding error, code ${recodeResult.exitCode}';
      _log.shout(message);
      _log.shout(recodeResult.stderr);
      throw message;
    }

    return '$dataDirectory$repoId';
  }

}