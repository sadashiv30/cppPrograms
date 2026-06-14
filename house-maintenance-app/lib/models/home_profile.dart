class HomeProfile {
  final int? id;
  final String address;
  final String city;
  final String state;
  final String zip;
  final int? yearBuilt;
  final int? bedrooms;
  final double? bathrooms;
  final double? sqft;
  final String? propertyType;
  final String? heatingType;
  final String? coolingType;
  final String? roofType;
  final String? foundationType;
  final bool? hasPool;
  final String? parkingType;

  const HomeProfile({
    this.id,
    required this.address,
    this.city = '',
    this.state = '',
    this.zip = '',
    this.yearBuilt,
    this.bedrooms,
    this.bathrooms,
    this.sqft,
    this.propertyType,
    this.heatingType,
    this.coolingType,
    this.roofType,
    this.foundationType,
    this.hasPool,
    this.parkingType,
  });

  HomeProfile copyWith({
    int? id,
    String? address,
    String? city,
    String? state,
    String? zip,
    int? yearBuilt,
    int? bedrooms,
    double? bathrooms,
    double? sqft,
    String? propertyType,
    String? heatingType,
    String? coolingType,
    String? roofType,
    String? foundationType,
    bool? hasPool,
    String? parkingType,
  }) => HomeProfile(
    id: id ?? this.id,
    address: address ?? this.address,
    city: city ?? this.city,
    state: state ?? this.state,
    zip: zip ?? this.zip,
    yearBuilt: yearBuilt ?? this.yearBuilt,
    bedrooms: bedrooms ?? this.bedrooms,
    bathrooms: bathrooms ?? this.bathrooms,
    sqft: sqft ?? this.sqft,
    propertyType: propertyType ?? this.propertyType,
    heatingType: heatingType ?? this.heatingType,
    coolingType: coolingType ?? this.coolingType,
    roofType: roofType ?? this.roofType,
    foundationType: foundationType ?? this.foundationType,
    hasPool: hasPool ?? this.hasPool,
    parkingType: parkingType ?? this.parkingType,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'address': address,
    'city': city,
    'state': state,
    'zip': zip,
    'year_built': yearBuilt,
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'sqft': sqft,
    'property_type': propertyType,
    'heating_type': heatingType,
    'cooling_type': coolingType,
    'roof_type': roofType,
    'foundation_type': foundationType,
    'has_pool': hasPool == null ? null : (hasPool! ? 1 : 0),
    'parking_type': parkingType,
  };

  factory HomeProfile.fromMap(Map<String, dynamic> m) => HomeProfile(
    id: m['id'] as int?,
    address: m['address'] as String? ?? '',
    city: m['city'] as String? ?? '',
    state: m['state'] as String? ?? '',
    zip: m['zip'] as String? ?? '',
    yearBuilt: m['year_built'] as int?,
    bedrooms: m['bedrooms'] as int?,
    bathrooms: (m['bathrooms'] as num?)?.toDouble(),
    sqft: (m['sqft'] as num?)?.toDouble(),
    propertyType: m['property_type'] as String?,
    heatingType: m['heating_type'] as String?,
    coolingType: m['cooling_type'] as String?,
    roofType: m['roof_type'] as String?,
    foundationType: m['foundation_type'] as String?,
    hasPool: m['has_pool'] == null ? null : (m['has_pool'] as int) == 1,
    parkingType: m['parking_type'] as String?,
  );

  String get fullAddress {
    final parts = [address, city, state, zip].where((s) => s.isNotEmpty);
    return parts.join(', ');
  }

  String? get installDateFromYear => yearBuilt != null ? '$yearBuilt-01-01' : null;
}
