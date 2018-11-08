import 'package:mockito/mockito.dart';
import 'package:ruian_api/src/repository/downloader.dart';
import 'package:ruian_api/src/repository/repository.dart';
import 'package:ruian_api/src/repository/repository_builder.dart';
import 'package:ruian_api/src/repository/repository_updater.dart';
import 'package:ruian_api/src/server/configuration.dart';
import 'package:test/test.dart';

main() {
  group('repository updater tests', () {
    DownloaderMock downloaderMock;
    RepositoryBuilderMock builderMock;
    Configuration config;

    setUp(() {
      config = new Configuration.forTests(
        regionsDataPath: 'data/regions.csv',
        municipalityDataPath: 'data/municipality.csv',
        dataPath: 'test/test-data',
        dataDirectory: 'test/test-data',
      );
      downloaderMock = new DownloaderMock();
      builderMock = new RepositoryBuilderMock();
    });

    test('simulated repository downlaoder fail', () async {
      final downloadFailText = 'downloadUnzipAndRecode fail';
      when(downloaderMock.downloadUnzipAndRecode(any))
          .thenAnswer((_) => throw downloadFailText);

      var updater = new RepositoryUpdater(config, downloaderMock, builderMock);
      await updater.initialize();
      await updater.update();

      expect(updater.state.latestDataPath, isNull);
    });

    test('simulated repository builder fail', () async {
      when(downloaderMock.downloadUnzipAndRecode(any))
          .thenAnswer((_) async => 'test/new-downloaded-test-data');

      var updater = new RepositoryUpdater(config, downloaderMock, builderMock);
      await updater.initialize();

      final repoBuildFailText = 'repository builder fail';
      when(builderMock.buildRepository(any))
          .thenAnswer((_) => throw repoBuildFailText);

      await updater.update();

      expect(updater.state.latestDataValidity, equals(RepositoryDataValidity.invalid));
    });

    test('simulated repository sanity check fail', () async {
      when(downloaderMock.downloadUnzipAndRecode(any))
          .thenAnswer((_) async => 'test/new-downloaded-test-data');

      var updater = new RepositoryUpdater(config, downloaderMock, builderMock);
      await updater.initialize();

      when(builderMock.buildRepository(any))
          .thenAnswer((_) async => new Repository({}, [], {}));

      await updater.update();

      expect(updater.state.latestDataValidity, equals(RepositoryDataValidity.invalid));
    });

    test('successfull repository update', () async {
      const newDataPath = 'test/new-downloaded-test-data';
      when(downloaderMock.downloadUnzipAndRecode(any))
          .thenAnswer((_) async => newDataPath);

      var updater = new RepositoryUpdater(config, downloaderMock, new RepositoryBuilder(config));

      await updater.initialize();
      await updater.update();

      expect(updater.state.dataPath, equals(newDataPath));
      expect(updater.state.shouldUpdate, isFalse);
      expect(updater.repository, isNotNull);
      expect(updater.repository.streetCount, greaterThan(0));
    });
  });
}

class DownloaderMock extends Mock implements Downloader {}

class RepositoryBuilderMock extends Mock implements RepositoryBuilder {}
