import 'package:ruian_api/src/repository/place_request.dart';
import 'package:ruian_api/src/repository/place_response.dart';
import 'package:ruian_api/src/repository/repository.dart';
import 'package:ruian_api/src/repository/repository_builder.dart';
import 'package:ruian_api/src/server/configuration.dart';
import 'package:test/test.dart';

main() {
  group('repository address validator tests', () {
    Repository repository;

    setUp(() async {
      var config = new Configuration.forTests(
        regionsDataPath: 'data/regions.csv',
        municipalityDataPath: 'data/municipality.csv',
      );
      repository =
          await new RepositoryBuilder(config).buildRepository('test/test-data');
    });

    test('place exact match', () {
      final request = new PlaceRequest()
        ..municipalityId = 500011
        ..place.street = 'Přílucká'
        ..place.cp = '2'
        ..place.zip = 76311;

      final response = repository.findPlace(request);

      expect(response.status, equals(ResponseStatus.MATCH));
      expect(response.placeMatch?.street?.name, equals('Přílucká'));
      expect(response.placeMatch?.confidence, equals(1.0));
    });

    test('corrupted diacritic and case sensitivity in street name', () {
      final request = new PlaceRequest()
        ..municipalityId = 500011
        ..place.street = 'prILUCka'
        ..place.cp = '2'
        ..place.zip = 76311;

      final response = repository.findPlace(request);

      expect(response.status, equals(ResponseStatus.MATCH));
      expect(response.placeMatch?.street?.name, equals('Přílucká'));
      expect(response.placeMatch?.confidence, equals(1.0));
    });

    test('missing letter in a street name', () {
      final request = new PlaceRequest()
        ..municipalityId = 500011
        ..place.street = 'prilcka'
        ..place.cp = '2'
        ..place.zip = 76311;

      final response = repository.findPlace(request);

      expect(response.status, equals(ResponseStatus.POSSIBLE));
      expect(response.placeMatch?.street?.name, equals('Přílucká'));
      expect(response.placeMatch?.confidence, greaterThan(0.95));
    });

    test('missing two letters in a street name', () {
      final request = new PlaceRequest()
        ..municipalityId = 500011
        ..place.street = 'prlcka'
        ..place.cp = '2'
        ..place.zip = 76311;

      final response = repository.findPlace(request);

      expect(response.status, equals(ResponseStatus.POSSIBLE));
      expect(response.placeMatch?.street?.name, equals('Přílucká'));
      expect(response.placeMatch?.confidence, greaterThan(0.91));
    });

    test('long street name instead of abbreviated name', () {
      final request = new PlaceRequest()
        ..municipalityId = 500062
        ..place.street = 'Bratří Podmolů'
        ..place.cp = '213'
        ..place.zip = 75663;

      final response = repository.findPlace(request);

      expect(response.status, equals(ResponseStatus.POSSIBLE));
      expect(response.placeMatch?.street?.name, equals('Bří Podmolů'));
      expect(response.placeMatch?.confidence, greaterThan(0.85));
    });

    test('places w/o street (in a tiny municipality)', () {
      final request = new PlaceRequest()
        ..municipalityId = 500101
        ..place.cp = '32'
        ..place.zip = 36471;

      final response = repository.findPlace(request);

      expect(response.status, equals(ResponseStatus.MATCH));
      expect(response.placeMatch?.confidence, equals(1));
    });

    test(
        'place with streetless municipality part - part of municipality entered as street name',
        () {
      final request = new PlaceRequest()
        ..place.street = 'Košov'
        ..place.cp = '27'
        ..municipalityName = 'Lomnice nad Popelkou'
        ..place.zip = 51251;

      final response = repository.findPlace(request);

      expect(response.status, equals(ResponseStatus.MATCH));
      expect(response.placeMatch?.confidence, equals(1));
    });

    test('place with streetless municipality part II - with ev. number', () {
      final request = new PlaceRequest()
        ..place.street = 'Mnichovice'
        ..place.ce = '555'
        ..municipalityName = 'Mnichovice'
        ..place.zip = 25164;

      final response = repository.findPlace(request);

      expect(response.status, equals(ResponseStatus.MATCH));
      expect(response.placeMatch?.confidence, equals(1));
    });

    test(
        'place with common address - street, cp, municipality name, but without zip',
        () {
      final request = new PlaceRequest()
        ..place.street = 'Batalická'
        ..place.cp = '12'
        ..municipalityName = 'Želechovice nad Dřevnicí';

      final response = repository.findPlace(request);

      expect(response.status, equals(ResponseStatus.POSSIBLE));
      expect(response.placeMatch?.confidence, greaterThan(0.95));
    });

    test('place with full common address - street, cp, municipality name, zip',
        () {
      final request = new PlaceRequest()
        ..place.street = 'Výpusta'
        ..place.cp = '32'
        ..municipalityName = 'Želechovice nad Dřevnicí'
        ..place.zip = 76311;

      final response = repository.findPlace(request);

      expect(response.status, equals(ResponseStatus.MATCH));
      expect(response.placeMatch?.confidence, equals(1));
    });

    test('Non-existent place', () {
      final request = new PlaceRequest()
        ..municipalityId = 594881
        ..place.cp = '1'
        ..place.zip = 7122;

      final response = repository.findPlace(request);

      expect(response.status, equals(ResponseStatus.NOT_FOUND));
    });
  });
}
