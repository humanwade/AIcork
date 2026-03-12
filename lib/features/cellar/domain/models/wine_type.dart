enum WineType {
  red('Red'),
  white('White'),
  rose('Rosé'),
  sparkling('Sparkling'),
  dessert('Dessert'),
  fortified('Fortified'),
  orange('Orange'),
  other('Other');

  const WineType(this.label);
  final String label;

  static WineType fromLabel(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    switch (v) {
      case 'red':
        return WineType.red;
      case 'white':
        return WineType.white;
      case 'rosé':
      case 'rose':
        return WineType.rose;
      case 'sparkling':
        return WineType.sparkling;
      case 'dessert':
        return WineType.dessert;
      case 'fortified':
        return WineType.fortified;
      case 'orange':
        return WineType.orange;
      default:
        return WineType.other;
    }
  }
}

