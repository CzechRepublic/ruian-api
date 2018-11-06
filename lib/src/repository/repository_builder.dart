import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:logging/logging.dart';
import 'package:ruian_api/src/repository/repository.dart';
import 'package:ruian_api/src/server/configuration.dart';
import 'package:ruian_api/src/territory/csv_row.dart';
import 'package:ruian_api/src/territory/municipality.dart';
import 'package:ruian_api/src/territory/place.dart';
import 'package:ruian_api/src/territory/region.dart';
import 'package:ruian_api/src/territory/street.dart';
import 'package:ruian_api/src/territory/streetless_part.dart';

class RepositoryBuilder {
  static final Logger _log = new Logger('RepositoryBuilder');

  final Configuration _configuration;

  RepositoryBuilder(this._configuration);

  Future<Repository> buildRepository(String dataPath) async {
    _log.config(
        'Building repository from $dataPath - this will take some time.');
    var stopWatch = new Stopwatch()..start();

    var regions = await loadRegions();

    var municipalitiesRegions = await loadMunicipalityRegions();

    var municipalities =
        await new _MunicipalityBuilder(dataPath, regions, municipalitiesRegions)
            .loadMunicipalities();

    Repository repo =
        new Repository(municipalities, regions, municipalitiesRegions);

    stopWatch.stop();
    _log.config('Repository initialized in ${stopWatch.elapsed}');
    _log.config('totals: ${repo.municipalities
        .length} municipalities, ${repo.streetCount} streets');
    return repo;
  }

  Future<Map<int, String>> loadMunicipalityRegions() async {
    var rows = const CsvToListConverter(fieldDelimiter: ';', eol: '\n')
        .convert(
            await new File(_configuration.municipalityDataPath).readAsString())
        .skip(1);

    return new Map<int, String>.fromIterable(rows,
        key: (row) => row[0],
        value: (row) => (row[2] as String).substring(0, 5));
  }

  Future<List<Region>> loadRegions() async {
    return const CsvToListConverter(fieldDelimiter: ';', eol: '\n')
        .convert(await new File(_configuration.regionsDataPath).readAsString())
        .skip(1)
        .map((List<dynamic> row) => new Region(row[0], row[1]))
        .toList();
  }
}

/// Loads [Municipality], [Street] & [Place] data.
class _MunicipalityBuilder {
  static final _log = RepositoryBuilder._log;

  final String dataPath;

  final List<Region> regions;

  final Map<int, String> municipalitiesRegions;

  Map<int, Municipality> municipalities = {};

  _MunicipalityBuilder(this.dataPath, this.regions, this.municipalitiesRegions);

  Future<Map<int, Municipality>> loadMunicipalities() async {
    await for (FileSystemEntity file in csvDataFiles) {
      try {
        String csvContent = await (file as File).readAsString();
        const CsvToListConverter(fieldDelimiter: ';', eol: '\n')
            .convert(csvContent)
            .skip(1)
            .forEach((row) => processCsvRow(new CsvRow(row)));
      } catch (e, s) {
        _log.shout('File ${file.path} cannot be read.', e, s);
        throw 'Cannot use this repository: $e';
      }
    }

    return municipalities;
  }

  void processCsvRow(CsvRow row) {
    var m =
        municipalities.putIfAbsent(row.idObce, () => createMunicipality(row));
    attachStreetAndPlace(m, row);
    attachStreetLessParts(m, row);
  }

  Municipality createMunicipality(CsvRow row) {
    Region region = regions.firstWhere(
        (r) => r.id == municipalitiesRegions[row.idObce], orElse: () {
      _log.severe('Unknown region for municipality with id ${row.idObce}.');
      return Region.EMPTY;
    });

    return new Municipality.fromRow(row, region);
  }

  void attachStreetAndPlace(Municipality m, CsvRow row) {
    String streetName = row.nazevUlice;

    if (streetName == null || streetName.isEmpty)
      streetName = Repository.noStreet;
    String streetKey = Repository.normalizeName(streetName);
    Street street = m.streets[streetKey];

    if (street == null) {
      street = new Street(streetName);
      m.streets[streetKey] = street;
    }

    street.places.add(new Place.fromRow(row));
  }

  void attachStreetLessParts(Municipality m, CsvRow row) {
    if (isStreetLessPart(row)) {
      String partName = row.nazevCastiObce;
      String partKey = Repository.normalizeName(partName);

      m.streetLessParts
          .putIfAbsent(partKey, () => new StreetLessPart(partName));
      m.streetLessParts[partKey].places.add(new Place.fromRow(row));
    }
  }

  bool isStreetLessPart(CsvRow row) =>
      (row.nazevUlice == null || row.nazevUlice.isEmpty) &&
      row.nazevCastiObce != null &&
      row.nazevCastiObce.isNotEmpty;

  Stream<FileSystemEntity> get csvDataFiles => new Directory(dataPath)
      .list(recursive: true)
      .where((FileSystemEntity e) =>
          FileSystemEntity.isFileSync(e.path) &&
          e.path.toLowerCase().endsWith('.csv'));
}
