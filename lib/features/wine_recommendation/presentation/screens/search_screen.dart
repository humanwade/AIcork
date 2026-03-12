import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/recommendation_request.dart';
import '../providers/recommendation_providers.dart';
import '../providers/recent_searches_provider.dart';
import '../widgets/suggestion_chips_row.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import 'results_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  static const String routePath = '/search';
  static const String routeName = 'search';

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _queryController = TextEditingController();
  final _postalController = TextEditingController();
  int _topK = 3;
  double _budget = 50; // Slider: 10–200, step 5

  @override
  void dispose() {
    _queryController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(recommendationNotifierProvider.notifier);
    final state = ref.read(recommendationNotifierProvider);

    if (state.isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final query = _queryController.text.trim();
    final budget = _budget;
    final postal = _postalController.text.trim();

    final request = RecommendationRequest(
      query: query,
      maxBudget: budget,
      topK: _topK,
      postalCode: postal,
    );

    ref.read(recentSearchesProvider.notifier).add(
          RecentSearch(
            query: query,
            maxBudget: budget.toDouble(),
            topK: _topK,
            postalCode: postal,
          ),
        );

    try {
      final wines = await notifier.fetch(request);
      if (!mounted) return;
      context.push('/home/results', extra: wines);
    } catch (_) {}
  }

  void _applySuggestion(String suggestion) {
    setState(() {
      _queryController.text = suggestion;
    });
  }

  void _applyRecent(RecentSearch search) {
    setState(() {
      _queryController.text = search.query;
      _budget = search.maxBudget.clamp(10.0, 200.0);
      _topK = search.topK;
      _postalController.text = search.postalCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recState = ref.watch(recommendationNotifierProvider);
    final recent = ref.watch(recentSearchesProvider);

    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final isCompact = media.size.height < 700;

    final auth = ref.watch(authProvider);

    return LoadingOverlay(
      isLoading: recState.isSubmitting,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
          appBar: AppBar(
            titleSpacing: 24,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pairings',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  'Natural language wine recommendations',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.brown.shade300,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: auth.isAuthenticated ? 'Profile' : 'Sign in',
                onPressed: () {
                  if (auth.isAuthenticated) {
                    debugPrint('SearchScreen: profile icon tapped (logged in)');
                    context.push(MyProfileScreen.routePath);
                  } else {
                    context.push(LoginScreen.routePath);
                  }
                },
                icon: const Icon(Icons.person_outline_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCompact) const SizedBox(height: 12),
                  Text(
                    'What are you pairing for?',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Describe the meal, occasion, or mood. '
                    'We will handle the wine.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SuggestionChipsRow(
                    suggestions: const [
                      'Best wine for sirloin steak',
                      'Wine for salmon dinner',
                      'Red wine for pasta',
                      'Budget wine for party',
                    ],
                    onSelected: _applySuggestion,
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _queryController,
                          maxLines: 3,
                          minLines: 2,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            labelText: 'What are you eating?',
                            hintText: 'e.g. steak, pasta, seafood',
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty ||
                                value.trim().length < 4) {
                              return 'Tell us a bit more about what you\'re pairing.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1ECE7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Max budget',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: const Color(0xFF5C4A3F),
                                    ),
                                  ),
                                  Text(
                                    '\$${_budget.round()}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF5C4A3F),
                                    ),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFF5C4A3F),
                                  inactiveTrackColor: const Color(0xFFE3D9CF),
                                  thumbColor: const Color(0xFF5C4A3F),
                                  overlayColor: const Color(0xFF5C4A3F)
                                      .withOpacity(0.2),
                                ),
                                child: Slider(
                                  value: _budget,
                                  min: 10,
                                  max: 200,
                                  divisions: 38,
                                  onChanged: (value) {
                                    setState(() {
                                      _budget = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Results',
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _topK,
                                    isDense: true,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _topK = value;
                                      });
                                    },
                                    items: const [1, 3, 5, 8]
                                        .map(
                                          (k) => DropdownMenuItem<int>(
                                            value: k,
                                            child: Text('Top $k'),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _postalController,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Postal code',
                            hintText: 'e.g. M1T 2G8',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Postal code helps show inventory near you.';
                            }
                            if (value.trim().length < 5) {
                              return 'Please enter a valid postal code.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            label: recState.isSubmitting
                                ? 'Finding wines...'
                                : 'Search recommendations',
                            onPressed: recState.isSubmitting ? null : _submit,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildFeedbackSection(context, recState),
                  if (recent.isNotEmpty) const SizedBox(height: 24),
                  if (recent.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent searches',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: recent
                              .map(
                                (s) => ActionChip(
                                  label: Text(
                                    s.query,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () => _applyRecent(s),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(
    BuildContext context,
    RecommendationState recState,
  ) {
    return recState.results.when(
      data: (wines) {
        if (wines.isEmpty) {
          return const EmptyState(
            title: 'Awaiting your first pairing',
            message:
                'Describe the meal or occasion above and we\'ll suggest thoughtful wines.',
          );
        }
        return Text(
          'Last search returned ${wines.length} wines.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, _) => ErrorState.inline(
        message: 'We couldn\'t reach the wine service.',
        onRetry: _submit,
      ),
    );
  }
}

