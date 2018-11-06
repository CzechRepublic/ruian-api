/// [Builder] response data.
class BuilderResponse {
  List data;

  BuilderResponse([this.data = const []]);

  Map<String, dynamic> asMap() {
    return {'data': data};
  }
}
