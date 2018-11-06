import 'package:ruian_api/src/territory/csv_row.dart';
import 'package:ruian_api/src/territory/region.dart';
import 'package:ruian_api/src/territory/street.dart';
import 'package:ruian_api/src/territory/streetless_part.dart';

class Municipality {
  final int id;
  final String name;
  final String index;
  final Map<String, Street> streets = {};
  final Map<String, StreetLessPart> streetLessParts = {};
  final Region region;

  Municipality(this.id, this.name, this.index, this.region);

  factory Municipality.fromRow(CsvRow row, Region region) {
    return municipalityFromRow(row, region);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Municipality &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Municipality{id: $id, name: $name, streets: ${streets
        .length}, streetLessParts: ${streetLessParts.length}';
  }

  Map<String, dynamic> asMap() {
    return {'municipalityId': id, 'municipalityName': name};
  }
}
