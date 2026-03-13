/// Static educational article for Learn Wine section.
class LearnWineArticle {
  const LearnWineArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> sections;

  static const List<LearnWineArticle> all = [
    LearnWineArticle(
      id: 'tannin',
      title: 'What is tannin?',
      subtitle: 'Understand structure and grip in red wines.',
      sections: [
        'Tannins are natural compounds found in grape skins, seeds, and stems. They create the dry, astringent sensation you feel on your tongue and gums when drinking red wine.',
        'Think of the feeling of drinking strong black tea—that puckering quality is similar to tannin. In wine, tannins add structure, body, and aging potential.',
        'Red wines typically have more tannin than whites because red winemaking involves extended contact with grape skins during fermentation.',
        'Tips: Pair tannic reds with fatty or protein-rich foods (steak, cheese) to soften the sensation. Lighter tannins work well with lighter dishes.',
      ],
    ),
    LearnWineArticle(
      id: 'pairing-basics',
      title: 'Red vs white pairing basics',
      subtitle: 'Simple rules for pairing at the table.',
      sections: [
        'A classic rule of thumb: match the weight of the wine to the weight of the food. Light wines with light dishes, fuller wines with richer dishes.',
        'Red wines often pair well with red meat, tomato-based sauces, and hearty dishes. The tannins and body complement bold flavours.',
        'White wines tend to work with fish, poultry, salads, and cream-based sauces. Acidity and lighter body suit delicate or citrusy flavours.',
        'Don\'t overthink it—trust your palate. If it tastes good together, it works. When in doubt, a versatile option like rosé or a light red can bridge many dishes.',
      ],
    ),
    LearnWineArticle(
      id: 'choose-bottle',
      title: 'How to choose a bottle',
      subtitle: 'Tips for choosing with confidence.',
      sections: [
        'Start with what you know: if you\'ve enjoyed a grape or region before, look for similar options. Staff at wine shops can often suggest comparable bottles.',
        'Read the label: the back label often describes flavour profile and food pairings. Use it as a quick guide when you\'re unsure.',
        'Consider the occasion: everyday sipping might call for something affordable and easy-drinking; a special dinner might warrant a step up.',
        'Trust your budget: great wine exists at every price point. You don\'t need to spend a lot to find something you\'ll enjoy.',
      ],
    ),
  ];

  static LearnWineArticle? byId(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
