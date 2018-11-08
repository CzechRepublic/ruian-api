// Copyright (c) 2017, tomucha. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:ruian_api/ruian.dart';
import 'package:ruian_api/src/builder/builder.dart';
import 'package:ruian_api/src/repository/downloader.dart';
import 'package:ruian_api/src/repository/repository_builder.dart';
import 'package:ruian_api/src/repository/repository_updater.dart';
import 'package:ruian_api/src/server/configuration.dart';

main(List<String> arguments) async {
  final Logger _log = new Logger('main');

  // Logging.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    String message = '[${rec.level.name}]: ${rec.time}: ${rec.loggerName}: ${rec
        .message}';
    print(rec.error == null ? message : '${message}: ${rec.error}');
  });

  final defaultPort = 80;

  // Parse arguments of a script.
  ArgParser parser = new ArgParser();
  parser.addOption('src',
      abbr: 's', help: 'Folder with RUIAN csv files in it.');
  parser.addOption('path',
      abbr: 'x',
      help:
          'Path of project with bin/, data/, ... directories. Used to run shell script.');
  parser.addOption('port',
      abbr: 'p',
      help: 'Port to listen on, optional',
      defaultsTo: defaultPort.toString());

  // overall configuration
  ArgResults args = parser.parse(arguments);
  final config = new Configuration(
    dataPath: args['src'],
    executionPath: args['path'],
    port: args['port'] != null ? int.parse(args['port']) : defaultPort,
    dataDirectory: 'data/vendor/',
    updateUrl: 'http://vdp.cuzk.cz/vymenny_format/csv/',
    filenamePostfix: '_OB_ADR_csv.zip',
    regionsDataPath: 'data/regions.csv',
    municipalityDataPath: 'data/municipality.csv',
    repositoryUpdateDataPeriod: const Duration(hours: 1),
  );

  if (config.argsMissing) {
    _log.shout('Wrong parameters.\n${parser.usage}');
    throw new Exception('Wrong parameters.');
  }

  try {
    print(config.executionPath);

    final repoHandler = new RepositoryUpdater(config, new Downloader(config), new RepositoryBuilder(config));

    new Server(
        configuration: config,
        repositoryHandler: repoHandler,
        addressBuilder: new AddressBuilder(() => repoHandler.repository))
      ..start();
  } catch (e, s) {
    _log.shout('Server is down!', e, s);
  }
}
