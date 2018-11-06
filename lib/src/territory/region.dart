class Region {
  static final Region EMPTY = new Region(null, null);

  final String id;
  final String name;

  Region(this.id, this.name);

  @override
  String toString() {
    return 'region $id $name';
  }

  Map<String, dynamic> asMap() {
    return {'regionId': id, 'regionName': name};
  }
}
