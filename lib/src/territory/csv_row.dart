import 'dart:collection';

import 'package:ruian_api/src/repository/repository.dart';
import 'package:ruian_api/src/territory/municipality.dart';
import 'package:ruian_api/src/territory/place.dart';
import 'package:ruian_api/src/territory/region.dart';

// 0 Kód ADM;
// 1 Kód obce;
// 2 Název obce;
// 3 Kód MOMC;
// 4 Název MOMC;
// 5 Kód MOP;
// 6 Název MOP;
// 7 Kód části obce;
// 8 Název části obce;
// 9 Kód ulice;
// 10 Název ulice;
// 11 Typ SO;
// 12 Číslo domovní;
// 13 Číslo orientační;
// 14 Znak čísla orientačního;
// 15 PSČ;
// 16 Souřadnice Y;
// 17 Souřadnice X;
// 18 Platí Od
class CsvRow {

  final List _row;

  CsvRow(this._row);

  get id => _row[0];

  get idObce => _row[1];

  get nazevObce => _row[2];

  get nazevCastiObce => _row[8];

  get nazevUlice => _row[10];

  get typSO => _row[11];

  get cisloDomovni => _row[12];

  get cisloOrientacni => _row[13];

  get znakCislaOrientacniho => _row[14];

  get psc => _row[15];
}

Municipality municipalityFromRow(CsvRow row, Region region) => new Municipality(
    row.idObce, row.nazevObce, Repository.normalizeName(row.nazevObce), region);

Place placeFromRow(CsvRow row) {
  String street;
  String ce;
  String cp;
  String co;
  int zip;
  Set<String> numbers = new HashSet();

  if (row.typSO is String && row.typSO.contains('e')) {
    ce = row.cisloDomovni.toString();
  } else {
    cp = row.cisloDomovni.toString();
  }

  if (row.cisloOrientacni != null) {
    if (row.znakCislaOrientacniho != null) {
      co = '${row.cisloOrientacni}${row.znakCislaOrientacniho}'.toLowerCase();
    } else {
      co = '${row.cisloOrientacni}';
    }
  }

  zip = row.psc;

  if (cp == '') {
    cp = null;
  } else {
    numbers.add(cp);
  }

  if (ce == '') {
    ce = null;
    numbers.add(ce);
  }

  if (co == '') {
    co = null;
    numbers.add(co);
  }

  return new Place()
    ..id = row.id
    ..street = street
    ..ce = ce
    ..cp = cp
    ..co = co
    ..zip = zip
    ..numbers = numbers;
}

