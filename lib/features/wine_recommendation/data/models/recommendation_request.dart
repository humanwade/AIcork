class WinePreferencesPayload {
  final List<String> preferredStyles;
  final String preferredBody;
  final List<String> preferredFlavors;
  final double defaultBudget;

  const WinePreferencesPayload({
    this.preferredStyles = const [],
    this.preferredBody = '',
    this.preferredFlavors = const [],
    this.defaultBudget = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'preferred_styles': preferredStyles,
      'preferred_body': preferredBody,
      'preferred_flavors': preferredFlavors,
      'default_budget': defaultBudget,
    };
  }

  bool get isEmpty =>
      preferredStyles.isEmpty &&
      preferredBody.isEmpty &&
      preferredFlavors.isEmpty &&
      defaultBudget <= 0;
}

class RecommendationRequest {
  final String query;
  final double maxBudget;
  final int topK;
  final WinePreferencesPayload? winePreferences;

  const RecommendationRequest({
    required this.query,
    required this.maxBudget,
    required this.topK,
    this.winePreferences,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'query': query,
      'max_budget': maxBudget,
      'top_k': topK,
    };
    if (winePreferences != null && !winePreferences!.isEmpty) {
      map['wine_preferences'] = winePreferences!.toJson();
    }
    return map;
  }
}

