class RecommendationRequest {
  final String query;
  final double maxBudget;
  final int topK;
  final String postalCode;

  const RecommendationRequest({
    required this.query,
    required this.maxBudget,
    required this.topK,
    required this.postalCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'max_budget': maxBudget,
      'top_k': topK,
      'user_postal': postalCode,
    };
  }
}

