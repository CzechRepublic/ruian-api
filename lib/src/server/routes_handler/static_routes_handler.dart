import 'package:ruian_api/src/server/routes_handler/routes_handler.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_rest/shelf_rest.dart';
import 'package:shelf_static/shelf_static.dart';

class StaticRoutesHandler implements RoutesHandler {
  final String staticPath;

  StaticRoutesHandler([staticPath = 'web/']) : staticPath = staticPath;

  @override
  void buildRoutes(Router router) {
    Handler staticHandler = createStaticHandler(staticPath, defaultDocument: 'index.html');

    router..add('/', ['GET'], staticHandler, exactMatch: false);
  }
}
