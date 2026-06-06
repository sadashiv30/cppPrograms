class HomeFeature {
  final int? id;
  final String category;
  final String name;
  final String location;
  final String installDate;
  final String lastServiced;
  final String notes;

  static const List<String> categories = [
    'HVAC',
    'Plumbing',
    'Electrical',
    'Roof',
    'Foundation',
    'Landscaping',
    'Pool',
    'Security',
    'Other',
  ];

  const HomeFeature({
    this.id,
    required this.category,
    required this.name,
    this.location = '',
    this.installDate = '',
    this.lastServiced = '',
    this.notes = '',
  });

  HomeFeature copyWith({
    int? id,
    String? category,
    String? name,
    String? location,
    String? installDate,
    String? lastServiced,
    String? notes,
  }) => HomeFeature(
    id: id ?? this.id,
    category: category ?? this.category,
    name: name ?? this.name,
    location: location ?? this.location,
    installDate: installDate ?? this.installDate,
    lastServiced: lastServiced ?? this.lastServiced,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'category': category,
    'name': name,
    'location': location,
    'install_date': installDate,
    'last_serviced': lastServiced,
    'notes': notes,
  };

  factory HomeFeature.fromMap(Map<String, dynamic> m) => HomeFeature(
    id: m['id'] as int?,
    category: m['category'] as String? ?? 'Other',
    name: m['name'] as String? ?? '',
    location: m['location'] as String? ?? '',
    installDate: m['install_date'] as String? ?? '',
    lastServiced: m['last_serviced'] as String? ?? '',
    notes: m['notes'] as String? ?? '',
  );
}
