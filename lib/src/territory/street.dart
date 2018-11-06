import 'package:ruian_api/src/territory/place.dart';
import 'package:ruian_api/src/repository/repository.dart';

class Street {
  final String name;
  final String index;
  final List<Place> places = [];

  Street(this.name) : index = Repository.normalizeName(name);

  Place findPlace(PlaceFilter filter) {
    return places.firstWhere(filter, orElse: () => null);
  }

  Map<String, dynamic> asMap() {
    return {'streetName': '$name'};
  }

  @override
  String toString() {
    return 'Street{name: $name}';
  }


}
