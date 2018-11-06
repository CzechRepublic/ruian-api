import 'package:meta/meta.dart';

class Configuration {
  final String dataPath;

  final int port;

  final String executionPath;

  final String dataDirectory;

  final String updateUrl;

  final String filenamePostfix;

  final String regionsDataPath;

  final String municipalityDataPath;

  final Duration repositoryUpdateDataPeriod;

  Configuration({
    @required this.dataPath,
    @required this.executionPath,
    @required this.port,
    @required this.dataDirectory,
    @required this.updateUrl,
    @required this.filenamePostfix,
    @required this.regionsDataPath,
    @required this.municipalityDataPath,
    @required this.repositoryUpdateDataPeriod,
  });

  Configuration.forTests({
    this.dataPath,
    this.executionPath,
    this.port,
    this.dataDirectory,
    this.updateUrl,
    this.filenamePostfix,
    this.regionsDataPath,
    this.municipalityDataPath,
    this.repositoryUpdateDataPeriod,
  });

  bool get argsMissing => dataPath == null || executionPath == null;
}
