import 'package:shelf/shelf.dart';
import 'package:shelf_rest/shelf_rest.dart';
import 'package:shelf_static/shelf_static.dart';

import 'package:ruian_api/src/server/routes_handler/routes_handler.dart';

class StaticRoutesHandler implements RoutesHandler {
  final String staticPath;

  StaticRoutesHandler([staticPath = 'build/web/']) : staticPath = staticPath;

  @override
  void buildRoutes(Router router) {
    Handler staticHandler = createStaticHandler(staticPath, defaultDocument: 'index.html');

    router..add('/', ['GET'], staticHandler, exactMatch: false);
  }
}
