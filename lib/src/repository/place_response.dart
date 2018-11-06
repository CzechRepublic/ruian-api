import 'package:ruian_api/src/repository/place_match.dart';
import 'package:ruian_api/src/territory/place.dart';

/// Possibilities of response status.
enum ResponseStatus { ERROR, NOT_FOUND, POSSIBLE, MATCH }

/// API response of the [Place].
class PlaceResponse {
  final ResponseStatus status;
  final String message;
  final PlaceMatch placeMatch;

  PlaceResponse(this.status, this.placeMatch) : message = null;

  PlaceResponse.error(this.message)
      : status = ResponseStatus.ERROR,
        placeMatch = null;

  PlaceResponse.notFound(this.message)
      : status = ResponseStatus.NOT_FOUND,
        placeMatch = null;

  bool get isFullMatch =>
      status == ResponseStatus.MATCH && placeMatch?.confidence == 1;

  bool get isPossibleMatch =>
      status == ResponseStatus.POSSIBLE &&
      placeMatch?.confidence > 0 &&
      placeMatch?.confidence < 1;

  Map<String, dynamic> asMap() {
    return {
      'status': status.toString().replaceAll('ResponseStatus.', ''),
      'message': message,
      'place': placeMatch == null ? null : placeMatch.asMap()
    };
  }
}
