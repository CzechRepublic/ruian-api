import 'package:ruian_api/src/territory/municipality.dart';
import 'package:ruian_api/src/territory/place.dart';
import 'package:ruian_api/src/territory/street.dart';

/// Search result – found [Place].
class PlaceMatch {
  final double confidence;
  final Municipality municipality;
  final Street street;
  final Place place;

  PlaceMatch(this.confidence, this.municipality, this.street, this.place);

  @override
  String toString() {
    return 'PlaceMatch{confidence: $confidence,'
        ' regionId: ${municipality.region.id},'
        ' regionName: ${municipality.region.name},'
        ' municipalityId: ${municipality.id},'
        ' municipalityName: ${municipality.name},'
        ' streetName: ${street.name},'
        ' ce: ${place.ce},'
        ' cp: ${place.cp},'
        ' co: ${place.co},'
        ' zip: ${place.zip}';
  }

  Map<String, dynamic> asMap() {
    return {
      'confidence': confidence,
      'regionId': municipality.region.id,
      'regionName': municipality.region.name,
      'municipalityId': municipality.id,
      'municipalityName': municipality.name,
      'streetName': street.name,
      'ce': place.ce,
      'cp': place.cp,
      'co': place.co,
      'zip': place.zip,
      'id': place.id
    };
  }
}
