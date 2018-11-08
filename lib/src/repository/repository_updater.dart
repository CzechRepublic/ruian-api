import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:ruian_api/src/repository/downloader.dart';
import 'package:ruian_api/src/repository/place_request.dart';
import 'package:ruian_api/src/repository/place_response.dart';
import 'package:ruian_api/src/repository/repository.dart';
import 'package:ruian_api/src/repository/repository_builder.dart';
import 'package:ruian_api/src/server/configuration.dart';

class RepositoryUpdater {
  static final Logger _log = new Logger('RepositoryUpdater');

  final Configuration _config;

  final Downloader _downloader;

  final RepositoryBuilder _repoBuilder;

  String get dataDirectory => _config.dataDirectory;

  RepositoryState _state;

  RepositoryState get state => _state;

  Repository get repository => _state?.repository;

  RepositoryUpdater(this._config, this._downloader, this._repoBuilder,) {
    _state = new RepositoryState()..dataPath = _config.dataPath;
  }

  Future<Null> initialize() async {
    _state.repository = await _repoBuilder.buildRepository(_state.dataPath);
    _state.latestDataPath = await latestLocalRepoDir;
  }

  Future<Null> update([_]) async {
    _log.info('Automatic update check started...');

    try {
      if (await latestRepoNotDownloaded) {
        _log.info('New data available.');
        _state.latestDataPath = await _downloader.downloadUnzipAndRecode(latestRepoId);
      }
    } catch (e, s) {
      _log.severe('Error occured while processing new repository data.', e, s);
    }

    try {
      if (_state.shouldUpdate) {
        await updateRepository(_state.latestDataPath);
        await deleteOldData();
      }
    } catch (e, s) {
      _state.latestDataValidity = RepositoryDataValidity.invalid;
      var message = 'Error updating to new repository ${_state
          .latestDataPath}.';
      _log.severe(message, e, s);
    }

    _log.info('Automatic update finished, using repository data from ${_state
        .dataPath}.');
  }

  Future<Null> updateRepository(String dataPath) async {
    var newRepository = await _repoBuilder.buildRepository(dataPath);
    assertRepositorySanity(newRepository);

    _state.repository = newRepository;
    _state.dataPath = dataPath;
    _state.latestDataPath = null;

    _log.info('New repository created from $dataPath source.');
  }

  Future<Null> deleteOldData() async {
    _log.info('Cleaning up old data');

    Directory f = new Directory('$dataDirectory');

    var isNotLatestRepo = (entity) async =>
        await FileSystemEntity.isDirectory(entity.path) &&
        !entity.path.toLowerCase().endsWith(latestRepoId);

    var isNotInUse = (entity) async =>
        await FileSystemEntity.isDirectory(entity.path) &&
        !await FileSystemEntity.identical(entity.path, _state.dataPath);

    var isZipArchive = (entity) async =>
        await FileSystemEntity.isFile(entity.path) &&
        entity.path.toLowerCase().endsWith('.zip');

    var someDataDeleted = false;
    await for (FileSystemEntity entity in f.list()) {
      if ((await isNotLatestRepo(entity) && await isNotInUse(entity)) ||
          await isZipArchive(entity)) {
        try {
          entity.delete(recursive: true);
          someDataDeleted = true;
        } catch (e, s) {
          _log.warning('File ${entity.path} cannot be deleted.', e, s);
        }
      }
    }

    _log.info(someDataDeleted ? 'Old data deleted.' : 'Nothing to clean up.');
  }

  Future<bool> get latestRepoNotDownloaded async =>
      await FileSystemEntity.type('$dataDirectory/$latestRepoId') ==
      FileSystemEntityType.NOT_FOUND;

  String get latestRepoId {
    DateTime lastMonthDay = lastDayOfPreviousMonth;

    return '${lastMonthDay.year}${lastMonthDay.month
        .toString().padLeft(2, '0')}${lastMonthDay.day}';
  }

  /// see https://stackoverflow.com/questions/14814941/how-to-find-last-day-of-month
  DateTime get lastDayOfPreviousMonth {
    final DateTime now = new DateTime.now();
    return (now.month < 12)
        ? new DateTime(now.year, now.month, 0)
        : new DateTime(now.year + 1, 0, 0);
  }

  Future<String> get latestLocalRepoDir async {
    Directory f = new Directory('$dataDirectory');
    if (!await f.exists()) {
      await f.create();
    }

    var pathComparator =
        (e1, e2) => e1 == null ? e2 : e1.path.compareTo(e2.path) > 0 ? e1 : e2;

    var latestDataDir =
        await f.list().where((e) => e is Directory).fold(null, pathComparator);

    return latestDataDir?.path;
  }

  void assertRepositorySanity(Repository repo) {
    _log.info('Checking repository sanity...');

    var placeRequest = new PlaceRequest()
      ..place.street = 'Výpusta'
      ..place.cp = '32'
      ..municipalityName = 'Želechovice nad Dřevnicí'
      ..place.zip = 76311;

    PlaceResponse placeResponse = repo.findPlace(placeRequest);

    if (!placeResponse.isFullMatch)
      throw "Sanity check fail, address '$placeRequest' not found, exact match with confidence 1.0 expected";

    placeRequest = new PlaceRequest()
      ..place.cp = '33'
      ..municipalityName = 'Bražec';

    placeResponse = repo.findPlace(placeRequest);

    if (!placeResponse.isPossibleMatch)
      throw "Sanity check fail, address '$placeRequest' not found, possible match with confidence inside (0, 1) expected";

    _log.info('Repository sanity check ok.');
  }

}

class RepositoryState {
  String dataPath;

  Repository repository;

  String _latestDataPath;

  RepositoryDataValidity latestDataValidity =
      RepositoryDataValidity.notTriedYet;

  bool get shouldUpdate =>
      latestDataValidity != RepositoryDataValidity.invalid &&
      _latestDataPath != null &&
      dataPath?.toLowerCase() != _latestDataPath?.toLowerCase();

  set latestDataPath(String value) {
    _latestDataPath = value;
    latestDataValidity = RepositoryDataValidity.notTriedYet;
  }

  String get latestDataPath => _latestDataPath;
}

enum RepositoryDataValidity { notTriedYet, invalid }
