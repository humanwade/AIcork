import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_providers.dart';

/// Legacy global keys (no user scoping) - removed on first load when user-scoped keys exist.
const _kLegacyStyles = 'wine_pref_styles';
const _kLegacyBody = 'wine_pref_body';
const _kLegacyFlavors = 'wine_pref_flavors';
const _kLegacyBudget = 'wine_pref_budget';

String _key(String base, String suffix) => 'wine_pref_${base}_$suffix';

final winePreferencesProvider =
    StateNotifierProvider<WinePreferencesNotifier, WinePreferences>((ref) {
  final auth = ref.watch(authProvider);
  final userId = auth.userId?.toString() ?? '';
  return WinePreferencesNotifier(userId);
});

class WinePreferences {
  final Set<String> preferredStyles;
  final String preferredBody;
  final Set<String> preferredFlavors;
  final double defaultBudget;
  final bool isLoaded;

  const WinePreferences({
    this.preferredStyles = const {},
    this.preferredBody = '',
    this.preferredFlavors = const {},
    this.defaultBudget = 0,
    this.isLoaded = false,
  });

  WinePreferences copyWith({
    Set<String>? preferredStyles,
    String? preferredBody,
    Set<String>? preferredFlavors,
    double? defaultBudget,
    bool? isLoaded,
  }) {
    return WinePreferences(
      preferredStyles: preferredStyles ?? this.preferredStyles,
      preferredBody: preferredBody ?? this.preferredBody,
      preferredFlavors: preferredFlavors ?? this.preferredFlavors,
      defaultBudget: defaultBudget ?? this.defaultBudget,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class WinePreferencesNotifier extends StateNotifier<WinePreferences> {
  WinePreferencesNotifier(this._userId) : super(const WinePreferences()) {
    _load();
  }

  final String _userId;

  bool get _isActive => mounted;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_isActive) return;
    await prefs.remove('wine_pref_postal_code');
    if (!_isActive) return;

    if (_userId.isEmpty) {
      if (!_isActive) return;
      state = state.copyWith(isLoaded: true);
      return;
    }

    final stylesKey = _key('styles', _userId);
    final bodyKey = _key('body', _userId);
    final flavorsKey = _key('flavors', _userId);
    final budgetKey = _key('budget', _userId);

    final styles = prefs.getStringList(stylesKey) ?? [];
    final flavors = prefs.getStringList(flavorsKey) ?? [];
    if (!_isActive) return;
    state = state.copyWith(
      preferredStyles: styles.toSet(),
      preferredBody: prefs.getString(bodyKey) ?? '',
      preferredFlavors: flavors.toSet(),
      defaultBudget: prefs.getDouble(budgetKey) ?? 0,
      isLoaded: true,
    );

    await _removeLegacyGlobalKeys(prefs);
  }

  Future<void> _removeLegacyGlobalKeys(SharedPreferences prefs) async {
    await prefs.remove(_kLegacyStyles);
    if (!_isActive) return;
    await prefs.remove(_kLegacyBody);
    if (!_isActive) return;
    await prefs.remove(_kLegacyFlavors);
    if (!_isActive) return;
    await prefs.remove(_kLegacyBudget);
  }

  Future<void> setStyles(Set<String> styles) async {
    if (!_isActive) return;
    state = state.copyWith(preferredStyles: styles);
    if (_userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (!_isActive) return;
    await prefs.setStringList(_key('styles', _userId), styles.toList());
  }

  Future<void> setBody(String body) async {
    if (!_isActive) return;
    state = state.copyWith(preferredBody: body);
    if (_userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (!_isActive) return;
    await prefs.setString(_key('body', _userId), body);
  }

  Future<void> setFlavors(Set<String> flavors) async {
    if (!_isActive) return;
    state = state.copyWith(preferredFlavors: flavors);
    if (_userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (!_isActive) return;
    await prefs.setStringList(_key('flavors', _userId), flavors.toList());
  }

  Future<void> setBudget(double budget) async {
    if (!_isActive) return;
    state = state.copyWith(defaultBudget: budget);
    if (_userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (!_isActive) return;
    await prefs.setDouble(_key('budget', _userId), budget);
  }
}

const _styleOptions = ['Red', 'White', 'Rosé', 'Sparkling'];
const _bodyOptions = ['Light', 'Medium', 'Full'];
const _flavorOptions = ['Fruity', 'Crisp', 'Bold', 'Dry', 'Earthy', 'Smooth'];

class WinePreferencesScreen extends ConsumerStatefulWidget {
  const WinePreferencesScreen({super.key});

  static const routePath = '/profile/wine-preferences';

  @override
  ConsumerState<WinePreferencesScreen> createState() =>
      _WinePreferencesScreenState();
}

class _WinePreferencesScreenState extends ConsumerState<WinePreferencesScreen> {
  Set<String> _styles = {};
  String _body = '';
  Set<String> _flavors = {};
  final _budgetCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _initFromPrefs(WinePreferences prefs) {
    if (!prefs.isLoaded) {
      _initialized = false;
      return;
    }
    if (_initialized) return;
    _initialized = true;
    _styles = Set.from(prefs.preferredStyles);
    _body = prefs.preferredBody;
    _flavors = Set.from(prefs.preferredFlavors);
    if (prefs.defaultBudget > 0) {
      _budgetCtrl.text = prefs.defaultBudget.toStringAsFixed(0);
    }
  }

  Future<void> _save() async {
    final notifier = ref.read(winePreferencesProvider.notifier);
    await notifier.setStyles(_styles);
    await notifier.setBody(_body);
    await notifier.setFlavors(_flavors);
    final budget = double.tryParse(_budgetCtrl.text.trim()) ?? 0;
    await notifier.setBudget(budget);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = ref.watch(winePreferencesProvider);
    _initFromPrefs(prefs);

    if (!prefs.isLoaded) {
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 24,
          title: Text('Wine preferences', style: theme.textTheme.titleLarge),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text('Wine preferences', style: theme.textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Preferred wine styles',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _styleOptions.map((s) {
                final selected = _styles.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      if (selected) {
                        _styles.remove(s);
                      } else {
                        _styles.add(s);
                      }
                    });
                  },
                  selectedColor: const Color(0xFFF1ECE7),
                  checkmarkColor: const Color(0xFF5C4A3F),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Preferred body',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _bodyOptions.map((s) {
                final selected = _body == s;
                return ChoiceChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (_) => setState(() => _body = s),
                  selectedColor: const Color(0xFFF1ECE7),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Preferred flavor profile',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _flavorOptions.map((s) {
                final selected = _flavors.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      if (selected) {
                        _flavors.remove(s);
                      } else {
                        _flavors.add(s);
                      }
                    });
                  },
                  selectedColor: const Color(0xFFF1ECE7),
                  checkmarkColor: const Color(0xFF5C4A3F),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Default budget (\$)',
                hintText: 'e.g. 25',
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5C4A3F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Save preferences'),
            ),
          ],
        ),
      ),
    );
  }
}
