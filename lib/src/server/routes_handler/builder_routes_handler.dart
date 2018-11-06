import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:ruian_api/src/builder/builder.dart';
import 'package:ruian_api/src/builder/builder_request.dart';
import 'package:ruian_api/src/builder/error_response.dart';
import 'package:ruian_api/src/server/routes_handler/routes_handler.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_rest/shelf_rest.dart';

class BuilderRoutesHandler implements RoutesHandler {
  static final Logger _log = new Logger('ApiRoutesHandler');

  AddressBuilder builder;

  BuilderRoutesHandler({this.builder});

  @override
  void buildRoutes(Router router) {
    router
      ..get('/regions', regionsHandler)
      ..get('/municipalities', municipalitiesHandler)
      ..get('/streets', streetsHandler)
      ..get('/places', placesHandler);
  }

  Response regionsHandler(Request request) {
    try {
      return new Response.ok(
          JSON.encode(
              builder.processBuildRegions(new BuilderRequest()).asMap()),
          headers: {'content-type': 'application/json'});
    } catch (e, s) {
      _log.warning(e);
      _log.warning(s);

      return new Response.internalServerError(body: e.toString());
    }
  }

  Response municipalitiesHandler(Request request) {
    var requestParams = request.requestedUri.queryParameters;

    try {
      Map<String, dynamic> argumentsRequired = {
        'regionId': requestParams['regionId'],
      };

      if (argumentsRequired.containsValue(null)) {
        return new ErrorResponse.missingArguments(argumentsRequired)
            .getResponse();
      }

      return new Response.ok(
          JSON.encode(builder
              .processBuildMunicipalities(new BuilderRequest(
                regionId: requestParams['regionId'],
              ))
              .asMap()),
          headers: {'content-type': 'application/json'});
    } catch (e, s) {
      _log.warning(e);
      _log.warning(s);

      return new Response.internalServerError(body: e.toString());
    }
  }

  Response streetsHandler(Request request) {
    var requestParams = request.requestedUri.queryParameters;

    try {
      Map<String, dynamic> argumentsRequired = {
        'municipalityId': requestParams['municipalityId'],
      };

      if (argumentsRequired.containsValue(null)) {
        return new ErrorResponse.missingArguments(argumentsRequired)
            .getResponse();
      }

      return new Response.ok(
          JSON.encode(builder
              .processBuildStreets(new BuilderRequest(
                municipalityId: int.parse(
                    requestParams['municipalityId'].toString(),
                    onError: (_) => null),
              ))
              .asMap()),
          headers: {'content-type': 'application/json'});
    } catch (e, s) {
      _log.warning(e);
      _log.warning(s);

      return new Response.internalServerError(body: e.toString());
    }
  }

  Response placesHandler(Request request) {
    var requestParams = request.requestedUri.queryParameters;

    try {
      Map<String, dynamic> argumentsRequired = {
        'municipalityId': requestParams['municipalityId'],
        'streetName': requestParams['streetName'],
      };

      if (argumentsRequired.containsValue(null)) {
        return new ErrorResponse.missingArguments(argumentsRequired)
            .getResponse();
      }

      return new Response.ok(
          JSON.encode(builder
              .processBuildPlaces(new BuilderRequest(
                municipalityId: int.parse(
                    requestParams['municipalityId'].toString(),
                    onError: (_) => null),
                streetName: requestParams['streetName'],
              ))
              .asMap()),
          headers: {'content-type': 'application/json'});
    } catch (e, s) {
      _log.warning(e);
      _log.warning(s);

      return new Response.internalServerError(body: e.toString());
    }
  }
}
