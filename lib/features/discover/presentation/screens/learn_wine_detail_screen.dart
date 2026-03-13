import 'package:flutter/material.dart';

import '../../domain/models/learn_wine_article.dart';

class LearnWineDetailScreen extends StatelessWidget {
  const LearnWineDetailScreen({
    super.key,
    required this.article,
  });

  final LearnWineArticle article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text(
          article.title,
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.brown.shade300,
                ),
              ),
              const SizedBox(height: 24),
              ...article.sections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    section,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
