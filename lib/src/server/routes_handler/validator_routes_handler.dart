import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:ruian_api/src/repository/place_request.dart';
import 'package:ruian_api/src/server/routes_handler/routes_handler.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_rest/shelf_rest.dart';

class ValidatorRoutesHandler implements RoutesHandler {
  static final Logger _log = new Logger('ApiRoutesHandler');

  Function getCurrentRepository;

  ValidatorRoutesHandler({this.getCurrentRepository});

  @override
  void buildRoutes(Router router) {
    router..get('/', processValidateRoute(getCurrentRepository));
  }

  static Function processValidateRoute(Function getCurrentRepository) {
    return (Request request) {
      var requestParams = request.requestedUri.queryParameters;

      try {
        PlaceRequest placeRequest = new PlaceRequest()
          ..municipalityId = int.parse(
              requestParams['municipalityId'].toString(),
              onError: (_) => null)
          ..municipalityName = requestParams['municipalityName']
          ..place.street = requestParams['street']
          ..place.ce = requestParams['ce']
          ..place.cp = requestParams['cp']
          ..place.co = requestParams['co']
          ..place.zip =
              int.parse(requestParams['zip'].toString(), onError: (_) => null);

        return new Response.ok(
            JSON.encode(getCurrentRepository().findPlace(placeRequest).asMap()),
            headers: {'content-type': 'application/json'});
      } catch (e, s) {
        _log.warning(e);
        _log.warning(s);

        return new Response.internalServerError(body: e.toString());
      }
    };
  }
}
