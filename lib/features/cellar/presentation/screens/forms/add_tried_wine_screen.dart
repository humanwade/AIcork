import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/controllers/cellar_controller.dart';
import '../../../domain/models/tried_wine_entry.dart';
import '../../../domain/models/wine_source.dart';
import '../../../domain/models/wine_type.dart';
import '../../widgets/chips/multi_select_chips.dart';
import '../../widgets/rating/star_rating_selector.dart';

class AddTriedWineScreen extends ConsumerStatefulWidget {
  const AddTriedWineScreen({
    super.key,
    this.prefillTitle,
    this.prefillType,
  });

  final String? prefillTitle;
  final WineType? prefillType;

  @override
  ConsumerState<AddTriedWineScreen> createState() => _AddTriedWineScreenState();
}

class AddTriedArgs {
  final String? prefillTitle;
  final WineType? prefillType;

  const AddTriedArgs({this.prefillTitle, this.prefillType});
}

class _AddTriedWineScreenState extends ConsumerState<AddTriedWineScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _customNotesController;
  late final TextEditingController _revisitController;

  WineType _type = WineType.red;
  double _rating = 4;
  DateTime? _tastedAt = DateTime.now();

  Set<String> _flavors = {};
  Set<String> _aromas = {};
  Set<String> _styles = {};

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefillTitle ?? '');
    _customNotesController = TextEditingController();
    _revisitController = TextEditingController();
    _type = widget.prefillType ?? WineType.red;
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

    final entry = TriedWineEntry(
      id: 'tried:${DateTime.now().millisecondsSinceEpoch}',
      title: _nameController.text.trim(),
      type: _type,
      rating: _rating,
      flavorTags: _flavors.toList()..sort(),
      aromaTags: _aromas.toList()..sort(),
      styleTags: _styles.toList()..sort(),
      customNotes: _customNotesController.text.trim(),
      revisitNotes: _revisitController.text.trim().isEmpty
          ? null
          : _revisitController.text.trim(),
      addedAt: DateTime.now(),
      tastedAt: _tastedAt,
      source: WineSource.manual,
    );

    debugPrint(
        'AddTriedWineScreen: saving tried entry title="${entry.title}", rating=${entry.rating}');
    try {
      await ref.read(cellarControllerProvider.notifier).addTried(entry);
      if (mounted) context.pop();
    } catch (e) {
      debugPrint('AddTriedWineScreen: addTried error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Could not save tasting entry. Please try again later.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: const Text('Add to Tried'),
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
                  decoration: const InputDecoration(
                    labelText: 'Wine name',
                    hintText: 'e.g. Rioja Reserva',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                    hintText: 'What stood out? Food pairing? Would you buy again?',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _revisitController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Purchase / revisit notes (optional)',
                    hintText: 'e.g. Rebuy for special occasions',
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
                    child: const Text('Save tasting'),
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

