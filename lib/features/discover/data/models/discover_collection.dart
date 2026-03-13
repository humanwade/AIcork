class DiscoverCollection {
  final String slug;
  final String title;
  final String subtitle;

  const DiscoverCollection({
    required this.slug,
    required this.title,
    required this.subtitle,
  });

  factory DiscoverCollection.fromJson(Map<String, dynamic> json) {
    return DiscoverCollection(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
    );
  }
}

