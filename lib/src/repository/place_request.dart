import 'package:ruian_api/src/territory/place.dart';
import 'package:ruian_api/src/territory/municipality.dart';

/// API request data - [Place] in a particular [Municipality] by [Municipality.id].
class PlaceRequest {
  /// Requested [Municipality.id].
  int municipalityId;
  String municipalityName;

  /// Requested [Place].
  Place place = new Place();

  /// Returns string output of [Municipality.id] and [Place].
  @override
  String toString() {
    return 'municipality id: $municipalityId, municipality name: $municipalityName, $place';
  }
}
