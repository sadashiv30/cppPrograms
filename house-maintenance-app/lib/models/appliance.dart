class Appliance {
  final int? id;
  final String name;
  final String brand;
  final String model;
  final String serialNumber;
  final String location;
  final String installDate;
  final String warrantyExpiry;
  final String notes;

  const Appliance({
    this.id,
    required this.name,
    this.brand = '',
    this.model = '',
    this.serialNumber = '',
    this.location = '',
    this.installDate = '',
    this.warrantyExpiry = '',
    this.notes = '',
  });

  Appliance copyWith({
    int? id,
    String? name,
    String? brand,
    String? model,
    String? serialNumber,
    String? location,
    String? installDate,
    String? warrantyExpiry,
    String? notes,
  }) => Appliance(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    serialNumber: serialNumber ?? this.serialNumber,
    location: location ?? this.location,
    installDate: installDate ?? this.installDate,
    warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'brand': brand,
    'model': model,
    'serial_number': serialNumber,
    'location': location,
    'install_date': installDate,
    'warranty_expiry': warrantyExpiry,
    'notes': notes,
  };

  factory Appliance.fromMap(Map<String, dynamic> m) => Appliance(
    id: m['id'] as int?,
    name: m['name'] as String? ?? '',
    brand: m['brand'] as String? ?? '',
    model: m['model'] as String? ?? '',
    serialNumber: m['serial_number'] as String? ?? '',
    location: m['location'] as String? ?? '',
    installDate: m['install_date'] as String? ?? '',
    warrantyExpiry: m['warranty_expiry'] as String? ?? '',
    notes: m['notes'] as String? ?? '',
  );

  bool get warrantyExpired {
    if (warrantyExpiry.isEmpty) return false;
    return DateTime.tryParse(warrantyExpiry)?.isBefore(DateTime.now()) ?? false;
  }
}
