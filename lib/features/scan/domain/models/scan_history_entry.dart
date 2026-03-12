class ScanHistoryEntry {
  final int id;
  final String wineName;
  final String? sku;
  final String? imageUrl;

  const ScanHistoryEntry({
    required this.id,
    required this.wineName,
    this.sku,
    this.imageUrl,
  });

  factory ScanHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ScanHistoryEntry(
      id: json['id'] as int,
      wineName: json['wine_name'] as String? ?? '',
      sku: json['sku'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}

