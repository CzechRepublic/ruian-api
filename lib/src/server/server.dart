import 'dart:async';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:ruian_api/src/builder/builder.dart';
import 'package:ruian_api/src/repository/repository.dart';
import 'package:ruian_api/src/repository/repository_updater.dart';
import 'package:ruian_api/src/server/configuration.dart';
import 'package:ruian_api/src/server/routes_handler/builder_routes_handler.dart';
import 'package:ruian_api/src/server/routes_handler/static_routes_handler.dart';
import 'package:ruian_api/src/server/routes_handler/validator_routes_handler.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_rest/shelf_rest.dart';

class Server {
  static final Logger _log = new Logger('Server');

  final RepositoryUpdater repositoryHandler;

  final AddressBuilder addressBuilder;

  final Configuration configuration;

  Repository get repository => repositoryHandler.repository;

  Server(
      {@required this.configuration,
      @required this.repositoryHandler,
      @required this.addressBuilder,
      }) {
    _log.config('Server initialized.');
  }

  /// Starts this [Server] and provides periodic check of new data version.
  Future start() async {
    await repositoryHandler.initialize();

    repositoryHandler.update();

    // Set auto updating of repository data.
    new Timer.periodic(
        configuration.repositoryUpdateDataPeriod, repositoryHandler.update);

    Router rootRouter = router(middleware: _createCorsHeadersMiddleware());

    const version = 'v1';
    const apiPath = '/api/$version/ruian';

    new ValidatorRoutesHandler(
        getCurrentRepository: () => repository)
      ..buildRoutes(rootRouter.child('$apiPath/validate'));

    new BuilderRoutesHandler(
        builder: addressBuilder)
      ..buildRoutes(rootRouter.child('$apiPath/build'));

    new StaticRoutesHandler()..buildRoutes(rootRouter.child('/'));

    printRoutes(rootRouter);

    _log.config('Starting on localhost: ${configuration.port}');
    io.serve(rootRouter.handler, 'localhost', configuration.port);
  }

  /// Handles OPTIONS requests, handles CORS headers.
  Middleware _createCorsHeadersMiddleware() {
    // FIXME: Origin * nebude to prave orechove!
    const CORS_HEADERS = const {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Accept, Authorization, Content-Type'
    };

    // Handle preflight (OPTIONS) requests by just adding headers and an empty
    // response.
    Response handleOptionsRequest(Request request) {
      if (request.method == 'OPTIONS') {
        // this is workaround - shelf_cors package returns ok(null, ...) which
        // leads to server never committing the response and
        // browser waits endlessly. Let's return 'something':
        return new Response.ok('OK', headers: CORS_HEADERS);
      } else {
        return null;
      }
    }

    Response addCorsHeaders(Response response) =>
        response.change(headers: CORS_HEADERS);

    return createMiddleware(
        requestHandler: handleOptionsRequest, responseHandler: addCorsHeaders);
  }

}
