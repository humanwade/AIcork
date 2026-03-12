class WineEntity {
  final String title;
  final double price;
  final String sku;
  final String? thumbnailUrl;
  final String? tastingNotes;
  final String? sommelierNote;
  final String? inventoryUrl;
  final bool matchedDb;
  final bool canContribute;
  final String? recognizedWineName;
  final String? recognizedWinery;
  final String? recognizedVintage;
  final String? wineType;

  const WineEntity({
    required this.title,
    required this.price,
    required this.sku,
    this.thumbnailUrl,
    this.tastingNotes,
    this.sommelierNote,
    this.inventoryUrl,
    this.matchedDb = true,
    this.canContribute = false,
    this.recognizedWineName,
    this.recognizedWinery,
    this.recognizedVintage,
    this.wineType,
  });
}

