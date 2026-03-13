import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../discover/presentation/providers/discover_providers.dart';
import '../../../domain/controllers/cellar_controller.dart';
import '../../../domain/models/tried_wine_entry.dart';
import '../../../domain/models/wine_type.dart';
import '../../widgets/chips/multi_select_chips.dart';
import '../../widgets/rating/star_rating_selector.dart';

class EditTriedWineScreen extends ConsumerStatefulWidget {
  const EditTriedWineScreen({
    super.key,
    required this.entry,
  });

  final TriedWineEntry entry;

  @override
  ConsumerState<EditTriedWineScreen> createState() =>
      _EditTriedWineScreenState();
}

class _EditTriedWineScreenState extends ConsumerState<EditTriedWineScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _customNotesController;
  late final TextEditingController _revisitController;

  late WineType _type;
  late double _rating;
  DateTime? _tastedAt;

  late Set<String> _flavors;
  late Set<String> _aromas;
  late Set<String> _styles;

  static const _flavorOptions = [
    'Blackberry',
    'Cherry',
    'Citrus',
    'Apple',
    'Peach',
    'Vanilla',
    'Chocolate',
    'Pepper',
  ];

  static const _aromaOptions = [
    'Floral',
    'Earthy',
    'Oak',
    'Mineral',
  ];

  static const _styleOptions = [
    'Light-bodied',
    'Medium-bodied',
    'Full-bodied',
    'Dry',
    'Off-dry',
    'Sweet',
    'Crisp',
    'Smooth',
    'Bold',
    'Elegant',
  ];

  TriedWineEntry get entry => widget.entry;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: entry.title);
    _customNotesController = TextEditingController(text: entry.customNotes);
    _revisitController =
        TextEditingController(text: entry.revisitNotes ?? '');
    _type = entry.type;
    _rating = entry.rating;
    _tastedAt = entry.tastedAt;
    _flavors = {...entry.flavorTags};
    _aromas = {...entry.aromaTags};
    _styles = {...entry.styleTags};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customNotesController.dispose();
    _revisitController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _tastedAt ?? now;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      initialDate: initial,
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _tastedAt = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(cellarControllerProvider.notifier);

    final customNotes = _customNotesController.text.trim();
    final revisitNotes = _revisitController.text.trim();

    try {
      await controller.updateTried(
        original: entry,
        rating: _rating,
        flavorTags: _flavors,
        styleTags: _styles,
        customNotes: customNotes,
        type: _type,
        purchaseNotes: revisitNotes.isEmpty ? null : revisitNotes,
        tastedAt: _tastedAt,
      );
      if (mounted) {
        ref.invalidate(cellarInsightsProvider);
        ref.invalidate(discoverForYouProvider);
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not update tasting entry. Please try again later.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: const Text('Edit tasting'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Wine', style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Wine name',
                  ),
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Type'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<WineType>(
                      value: _type,
                      isDense: true,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _type = v);
                      },
                      items: WineType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Rating', style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                StarRatingSelector(
                  value: _rating,
                  onChanged: (v) => setState(() => _rating = v),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Date', style: theme.textTheme.titleLarge),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(
                        _tastedAt == null
                            ? 'Pick'
                            : '${_tastedAt!.year}-${_tastedAt!.month.toString().padLeft(2, '0')}-${_tastedAt!.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Flavors', style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                MultiSelectChips(
                  options: _flavorOptions,
                  selected: _flavors,
                  onChanged: (s) => setState(() => _flavors = s),
                ),
                const SizedBox(height: 18),
                Text('Aromas', style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                MultiSelectChips(
                  options: _aromaOptions,
                  selected: _aromas,
                  onChanged: (s) => setState(() => _aromas = s),
                ),
                const SizedBox(height: 18),
                Text('Body & style', style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                MultiSelectChips(
                  options: _styleOptions,
                  selected: _styles,
                  onChanged: (s) => setState(() => _styles = s),
                ),
                const SizedBox(height: 20),
                Text('Notes', style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customNotesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Additional comments (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _revisitController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Purchase / revisit notes (optional)',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5C4A3F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

