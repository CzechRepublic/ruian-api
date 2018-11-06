import 'dart:collection';

import 'package:ruian_api/src/territory/csv_row.dart';

class Place {
  int id;
  String street;
  String ce;
  String cp;
  String co;
  int zip;

  Set<String> numbers = new HashSet();

  Place();

  factory Place.fromRow(CsvRow row) {
    return placeFromRow(row);
  }

  @override
  String toString() {
    return 'id: $id, zip: $zip, street: $street, cp: $cp, co: $co, ce: $ce.';
  }

  Map<String, dynamic> asMap() {
    return {'placeCe': ce, 'placeCp': cp, 'placeCo': co, 'placeZip': zip, 'placeId': id};
  }
}
