import 'package:logging/logging.dart';
import 'package:ruian_api/src/builder/builder_request.dart';
import 'package:ruian_api/src/builder/builder_response.dart';
import 'package:ruian_api/src/territory/municipality.dart';
import 'package:ruian_api/src/territory/place.dart';
import 'package:ruian_api/src/territory/region.dart';
import 'package:ruian_api/src/territory/street.dart';

/// Builds possible [Region], [Municipality], [Street] or [Place] from [_repositoryF] from acquired some parameters.
class AddressBuilder {
  static final Logger _log = new Logger('AddressBuilder');

  final Function _repositoryF;

  AddressBuilder(this._repositoryF);

  /// Requests for [Region].
  BuilderResponse processBuildRegions(BuilderRequest request) {
    _log.info('Building of regions request:: $request.');

    List<Map<String, dynamic>> data = [];

    _repositoryF().regions.forEach((Region region) {
      // Testing against 'Z' because of extra regions.
      if (region.id.length == 5 && '${region.id[4]}'.toLowerCase() != 'z') {
        data.add(region.asMap());
      }
    });

    return new BuilderResponse(data);
  }

  /// Requests for [Municipality].
  BuilderResponse processBuildMunicipalities(BuilderRequest request) {
    _log.info('Building of municipalities request:: $request.');

    List<Map<String, dynamic>> data = [];

    _repositoryF().municipalities.values.where((Municipality municipality) {
      return _passesRegion(request: request, id: municipality.region.id);
    }).forEach((Municipality municipality) {
      data.add(municipality.asMap());
    });

    return new BuilderResponse(data);
  }

  /// Requests for [Street].
  BuilderResponse processBuildStreets(BuilderRequest request) {
    _log.info('Building of streets request:: $request.');

    List<Map<String, dynamic>> data = [];

    _repositoryF().municipalities.values.where((Municipality municipality) {
      return _passesMunicipality(request: request, id: municipality.id);
    }).forEach((Municipality municipality) {
      municipality.streets.values.forEach((Street street) {
        data.add(street.asMap());
      });
    });

    return new BuilderResponse(data);
  }

  /// Requests for [Place].
  BuilderResponse processBuildPlaces(BuilderRequest request) {
    _log.info('Building of places request:: $request.');

    List<Map<String, dynamic>> data = [];

    _repositoryF().municipalities.values.where((Municipality municipality) {
      return _passesMunicipality(
        request: request,
        id: municipality.id,
      );
    }).forEach((Municipality municipality) {
      municipality.streets.values.where((Street street) {
        return _passesStreet(request: request, name: street.name);
      }).forEach((Street street) {
        street.places.forEach((Place place) {
          data.add(place.asMap());
        });
      });
    });

    return new BuilderResponse(data);
  }

  /// Generic request.
  BuilderResponse processBuild(BuilderRequest request) {
    _log.info('Building of $request.');

    List<Map<String, dynamic>> data = [];

    return new BuilderResponse(data);
  }

  /// Determines if [Region] passes this [request].
  bool _passesRegion({BuilderRequest request, String id}) {
    if (request.regionId != null) {
      return request.regionId == id;
    }

    return false;
  }

  /// Determines if [Municipality] passes this [request].
  bool _passesMunicipality({BuilderRequest request, int id}) {
    if (request.municipalityId != null) {
      return request.municipalityId == id;
    }

    return false;
  }

  /// Determines if [Street] passes this [request].
  bool _passesStreet({BuilderRequest request, String name}) {
    if (request.streetName != null) {
      return request.streetName == name;
    }

    return false;
  }
}
