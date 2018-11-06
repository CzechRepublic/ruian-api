import 'package:ruian_api/src/builder/builder.dart';
import 'package:ruian_api/src/builder/builder_request.dart';
import 'package:ruian_api/src/builder/builder_response.dart';
import 'package:ruian_api/src/repository/repository.dart';
import 'package:ruian_api/src/repository/repository_builder.dart';
import 'package:ruian_api/src/server/configuration.dart';
import 'package:test/test.dart';

main() {
  Repository repository;
  AddressBuilder builder;
  BuilderRequest request;
  BuilderResponse response;

  group('repository address builder tests', () {
    setUp(() async {
      var config = new Configuration.forTests(
        regionsDataPath: 'data/regions.csv',
        municipalityDataPath: 'data/municipality.csv',
      );
      repository =
          await new RepositoryBuilder(config).buildRepository('test/test-data');
      builder = new AddressBuilder(() => repository);
    });

    group('region', () {
      test('response is not empty', () {
        request = new BuilderRequest();
        response = builder.processBuildRegions(request);

        expect(response.asMap()['data'].isNotEmpty, isTrue);
      });

      test('response data are correct', () {
        request = new BuilderRequest();
        response = builder.processBuildRegions(request);

        expect(response.asMap()['data'].first['regionId'], equals('CZ010'));
        expect(response.asMap()['data'].first['regionName'],
            equals('Hlavní město Praha'));
      });
    });

    group('municipality', () {
      test('empty request has response with no data', () {
        request = new BuilderRequest();
        response = builder.processBuildMunicipalities(request);

        expect(response.asMap()['data'].isEmpty, isTrue);
      });

      test('response is not empty', () {
        request = new BuilderRequest()..regionId = 'CZ072';
        response = builder.processBuildMunicipalities(request);

        expect(response.asMap()['data'].isNotEmpty, isTrue);
      });

      test('find Želechovice nad Dřevnicí in its region', () {
        request = new BuilderRequest()..regionId = 'CZ072';
        response = builder.processBuildMunicipalities(request);

        expect(
            response.asMap()['data'].firstWhere((Map m) {
              return m['municipalityId'] == 500011;
            })['municipalityName'],
            equals('Želechovice nad Dřevnicí'));
      });

      test('find Bražec in its region', () {
        request = new BuilderRequest()..regionId = 'CZ041';
        response = builder.processBuildMunicipalities(request);

        expect(
            response.asMap()['data'].firstWhere((Map m) {
              return m['municipalityId'] == 500101;
            })['municipalityName'],
            equals('Bražec'));
      });
    });

    group('street', () {
      test('empty request has response with no data', () {
        request = new BuilderRequest();
        response = builder.processBuildStreets(request);

        expect(response.asMap()['data'].isEmpty, isTrue);
      });

      test('streets not empty', () {
        request = new BuilderRequest()..municipalityId = 500011;
        response = builder.processBuildStreets(request);

        expect(response.asMap()['data'].isNotEmpty, isTrue);
      });

      test('find exact street', () {
        request = new BuilderRequest()..municipalityId = 500011;
        response = builder.processBuildStreets(request);

        expect(
            response
                .asMap()['data']
                .where((Map m) => m['streetName'] == 'Podřevnická'),
            isNotEmpty);
      });

      test('find another street', () {
        request = new BuilderRequest()..municipalityId = 500011;
        response = builder.processBuildStreets(request);

        expect(
            response
                .asMap()['data']
                .where((Map m) => m['streetName'] == 'Papírenská'),
            isNotEmpty);
      });

      test('non existent street', () {
        request = new BuilderRequest()..municipalityId = 500011;
        response = builder.processBuildStreets(request);

        expect(
            response
                .asMap()['data']
                .where((Map m) => m['streetName'] == 'Vymyšlená neexistující'),
            isEmpty);
      });
    });

    group('place', () {
      test('empty request has response with no data', () {
        request = new BuilderRequest();
        response = builder.processBuildPlaces(request);

        expect(response.asMap()['data'].isEmpty, isTrue);
      });

      test('place is not empty', () {
        request = new BuilderRequest()
          ..municipalityId = 500011
          ..streetName = 'Papírenská';
        response = builder.processBuildPlaces(request);

        expect(response.asMap()['data'].isNotEmpty, isTrue);
      });

      test('find exact place by municipalityId and streetName', () {
        request = new BuilderRequest()
          ..municipalityId = 500011
          ..streetName = 'Přílucká';
        response = builder.processBuildPlaces(request);

        expect(response.asMap()['data'].first['placeCe'], isNull);
        expect(response.asMap()['data'].first['placeCo'], isNull);
        expect(response.asMap()['data'].first['placeCp'], equals('1'));
        expect(response.asMap()['data'].first['placeZip'], equals(76311));
        expect(response.asMap()['data'].first['placeId'], equals(4192575));
      });

      test('find another place by municipalityId and streetName', () {
        request = new BuilderRequest()
          ..municipalityId = 500011
          ..streetName = 'Papírenská';
        response = builder.processBuildPlaces(request);

        expect(response.asMap()['data'].first['placeCe'], isNull);
        expect(response.asMap()['data'].first['placeCo'], isNull);
        expect(response.asMap()['data'].first['placeCp'], equals('28'));
        expect(response.asMap()['data'].first['placeZip'], equals(76311));
        expect(response.asMap()['data'].first['placeId'], equals(4192788));
      });
    });
  });
}
