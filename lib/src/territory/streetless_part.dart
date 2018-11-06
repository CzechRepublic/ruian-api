import 'package:ruian_api/src/territory/street.dart';

class StreetLessPart extends Street {

  StreetLessPart(String name) : super(name);

  @override
  Map<String, dynamic> asMap() {
    return {'stretlessPartName': '$name'};
  }

  @override
  String toString() {
    return 'StreetlessPart{name: $name}';
  }

}
