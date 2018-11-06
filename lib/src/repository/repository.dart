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

import 'dart:math';

import 'package:edit_distance/edit_distance.dart';
import 'package:logging/logging.dart';
import 'package:ruian_api/src/diacritics.dart';
import 'package:ruian_api/src/territory/place.dart';
import 'package:ruian_api/src/repository/place_match.dart';
import 'package:ruian_api/src/repository/place_request.dart';
import 'package:ruian_api/src/repository/place_response.dart';
import 'package:ruian_api/src/territory/municipality.dart';
import 'package:ruian_api/src/territory/region.dart';
import 'package:ruian_api/src/territory/street.dart';

typedef bool PlaceFilter(Place p);

/// Repository of territorial identification, address and real estate.
class Repository {
  static final Logger _log = new Logger('Repository');

  static const noStreet = '-';

  final Map<int, Municipality> municipalities;

  final List<Region> regions;

  /// [Municipality.id] and [Region.name];
  final Map<int, String> municipalitiesRegions;

  final JaroWinkler jw = new JaroWinkler();

  Repository(this.municipalities, this.regions, this.municipalitiesRegions);

  get streetCount => municipalities.values
      .map((m) => m.streets.length)
      .fold(0, (a, b) => a + b);

  PlaceResponse findPlace(PlaceRequest request) {
    _log.info('Searching for place: ${request}');

    if (request == null) return errorResponse('Empty request.');
    if (request.municipalityId == null && request.municipalityName == null)
      return errorResponse('Missing municipalityId or municipalityName.');
    if (request.place.zip != null && request.place.zip < 0)
      return errorResponse('Wrong zip code format.');
    if (request.place.ce == null &&
        request.place.co == null &&
        request.place.cp == null) {
      return errorResponse('Specify at least one c[eop] parameter.');
    }

    Municipality bestMunicipality;
    int municipalityId = request.municipalityId;

    if (request.municipalityId == null) {
//      municipalityId = municipalities.values.firstWhere((Municipality municipality) => municipality.name == request.municipalityName)?.id;

      String municipalityIndex = normalizeName(request.municipalityName);

      bestMunicipality = municipalities.values.firstWhere(
          (Municipality municipality) =>
              municipality.index == municipalityIndex,
          orElse: () => null);
      double bestMunicipalityDistance = 1.0;

      if (bestMunicipality == null) {
        // nemame presny match
        municipalities.values.forEach((Municipality municipality) {
          double distance =
              jw.normalizedDistance(municipality.index, municipalityIndex);

          if (distance < bestMunicipalityDistance) {
            bestMunicipality = municipality;
            bestMunicipalityDistance = distance;
          }
        });
      }

      if (bestMunicipality == null) {
        return notFoundResponse(
            "Municipality name doesn't match any known municipality.");
      } else {
        municipalityId = bestMunicipality.id;
      }

      if (bestMunicipality == null && bestMunicipalityDistance > 0.8) {
        return notFoundResponse('Cannot find municipality.');
      }
    }

    if (municipalities[municipalityId] == null) {
      return notFoundResponse("Unknown municipality id.");
    }

    Municipality municipality = municipalities[municipalityId];

    if (municipality == null) {
      return errorResponse(
          "Municipality ${request.municipalityId} doesn't exist");
    }

    if (request.place.street == null) {
      if (municipality.streets.length == 1 &&
          municipality.streets[noStreet] != null) {
        // toto je ok, nepotrebujeme jmeno ulice
        request.place.street = noStreet;
      } else {
        return notFoundResponse(
            'Municipality uses street names, specify street.');
      }
    }

    String streetIndex = normalizeName(request.place.street);
    Street bestStreet = municipality.streets[streetIndex];

    // nemame-li presny match, zkusime casti obce bez nazvu ulic
    bestStreet ??= municipality.streetLessParts[streetIndex];

    double bestStreetDistance = 1.0;

    if (bestStreet == null) {
      // stale nemame match, tak zkousime dostatecne priblizne jmena ulic
      StreetWithDistance nearestNamed =
          findBestStreet(municipality.streets.values, streetIndex);

      if (nearestNamed.isNotNear) {
        // zkousime problizna jmena casti obci
        nearestNamed =
            findBestStreet(municipality.streetLessParts.values, streetIndex);
      }

      if (nearestNamed.isNear) {
        bestStreet = nearestNamed.street;
        bestStreetDistance = nearestNamed.nameDistance;
      } else {
        return notFoundResponse('Cannot find street.');
      }
    } else {
      // mame presny match
      bestStreetDistance = 0.0;
    }

    double confidence = 1.0 - bestStreetDistance;

    // zkusime presnou shodu cisel
    Place foundPlace = bestStreet.findPlace((Place place) {
      return place.co == request.place.co &&
          place.ce == request.place.ce &&
          place.cp == request.place.cp &&
          place.zip == request.place.zip;
    });

    if (foundPlace != null) {
      return foundResponse(confidence, municipality, bestStreet, foundPlace);
    }

    confidence *= 0.99;

    // tak bez PSC
    foundPlace = bestStreet.findPlace((Place place) {
      return place.co == request.place.co &&
          place.ce == request.place.ce &&
          place.cp == request.place.cp;
    });
    if (foundPlace != null) {
      return foundResponse(confidence, municipality, bestStreet, foundPlace);
    }

    confidence *= 0.99;

    if (request.place.co != null) {
      // tak jen co
      foundPlace = bestStreet.findPlace((Place place) {
        return place.co == request.place.co;
      });
      if (foundPlace != null) {
        return foundResponse(confidence, municipality, bestStreet, foundPlace);
      }

      confidence *= 0.99;

      // tak zamena?
      foundPlace = bestStreet.findPlace((Place place) {
        return place.cp == request.place.co;
      });
      if (foundPlace != null) {
        return foundResponse(confidence, municipality, bestStreet, foundPlace);
      }
    }

    confidence *= 0.99;

    // tak jen cp
    if (request.place.cp != null) {
      foundPlace = bestStreet.findPlace((Place place) {
        return place.cp == request.place.cp;
      });
      if (foundPlace != null) {
        return foundResponse(confidence, municipality, bestStreet, foundPlace);
      }
    }

    confidence *= 0.95;

    // tak alespon neco
    foundPlace = bestStreet.findPlace((Place place) {
      return place.numbers.contains(request.place.cp) ||
          place.numbers.contains(request.place.co) ||
          place.numbers.contains(request.place.ce);
    });
    if (foundPlace != null) {
      return foundResponse(confidence, municipality, bestStreet, foundPlace);
    }

    return notFoundResponse('Cannot find similar address in street.');
  }

  PlaceResponse errorResponse(String s) {
    return new PlaceResponse.error(s);
  }

  PlaceResponse notFoundResponse(String s) {
    return new PlaceResponse.notFound(s);
  }

  PlaceResponse foundResponse(double confidence, Municipality municipality,
      Street bestStreet, Place foundPlace) {
    if (confidence < 0.5) {
      return new PlaceResponse.notFound(
          'Cannot find an address similar enough.');
    }

    if (confidence > 1) confidence = 1.0;

    return new PlaceResponse(
        (confidence > 0.999 ? ResponseStatus.MATCH : ResponseStatus.POSSIBLE),
        new PlaceMatch(confidence, municipality, bestStreet, foundPlace));
  }

  static String normalizeName(String name) {
    if (name == null) return noStreet;
    if (name == noStreet) return noStreet;
    return Diacritics.removeDiacritics(name.toLowerCase()).replaceAll('.', '');
  }

  void printRandomDebug(int count) {
    Random r = new Random();
    for (int a = 0; a < count; a++) {
      var mun = municipalities.values
          .elementAt(r.nextInt(municipalities.values.length));
      var str =
          mun.streets.values.elementAt(r.nextInt(mun.streets.values.length));
      var pl = str.places[r.nextInt(str.places.length)];
      print("${mun.name} ${str.name} ${pl.ce}/${pl.co}/${pl.cp}");
    }
  }

  void printTargetedDebug(String city, String street) {
    municipalities.values
        .where((Municipality m) => m.name.contains(city))
        .forEach((Municipality mun) {
      print(mun);
      mun.streets.values
          .where((Street m) => m.name.contains(street))
          .forEach((Street str) {
        print(str);
        str.places.forEach((Place p) {
          print(p);
        });
      });
    });
  }

  StreetWithDistance findBestStreet(
      Iterable<Street> streets, String normalizedName) {
    double bestDistance = 1.0;
    Street bestStreet;

    streets.forEach((Street street) {
      double distance = jw.normalizedDistance(street.index, normalizedName);

      if (distance < bestDistance) {
        bestStreet = street;
        bestDistance = distance;
      }
    });

    return new StreetWithDistance(bestStreet, bestDistance);
  }
}

class StreetWithDistance {
  final Street street;
  final double nameDistance;

  StreetWithDistance(this.street, this.nameDistance);

  bool get isNear => street != null && nameDistance <= 0.8;

  bool get isNotNear => !isNear;
}
