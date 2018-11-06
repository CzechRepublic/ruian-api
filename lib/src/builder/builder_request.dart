import 'package:ruian_api/src/builder/builder.dart';

/// Prepares data for [AddressBuilder].
class BuilderRequest {
  String regionId;
  int municipalityId;
  String streetName;

  /// Processes requests data and if needed parses them.
  BuilderRequest({
    this.regionId,
    this.municipalityId,
    this.streetName,
  });

  @override
  String toString() {
    return 'regionId: $regionId, municipalityId: $municipalityId, streetName: $streetName';
  }
}
