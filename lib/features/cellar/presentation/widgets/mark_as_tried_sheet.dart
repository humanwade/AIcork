import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/controllers/cellar_controller.dart';
import '../../domain/models/cellar_wine.dart';
import 'chips/multi_select_chips.dart';
import 'rating/star_rating_selector.dart';

Future<void> showMarkAsTriedSheet(
  BuildContext context,
  WidgetRef ref, {
  required CellarWine want,
}) async {
  final parentContext = context;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    builder: (ctx) => _MarkAsTriedSheetContent(
      want: want,
      ref: ref,
      parentContext: parentContext,
    ),
  );
}

const _flavorOptions = [
  'Chocolate',
  'Blackberry',
  'Cherry',
  'Citrus',
  'Apple',
  'Vanilla',
  'Pepper',
  'Floral',
  'Oak',
  'Earthy',
  'Mineral',
];

const _styleOptions = [
  'Light-bodied',
  'Medium-bodied',
  'Full-bodied',
  'Dry',
  'Sweet',
  'Crisp',
  'Bold',
  'Smooth',
  'Elegant',
];

class _MarkAsTriedSheetContent extends StatefulWidget {
  const _MarkAsTriedSheetContent({
    required this.want,
    required this.ref,
    required this.parentContext,
  });

  final CellarWine want;
  final WidgetRef ref;
  final BuildContext parentContext;

  @override
  State<_MarkAsTriedSheetContent> createState() =>
      _MarkAsTriedSheetContentState();
}

class _MarkAsTriedSheetContentState extends State<_MarkAsTriedSheetContent> {
  late final TextEditingController _notesController;
  late final TextEditingController _purchaseNotesController;

  double _rating = 4;
  DateTime _tastedAt = DateTime.now();
  Set<String> _flavors = {};
  Set<String> _styles = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _purchaseNotesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _purchaseNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDate: _tastedAt,
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _tastedAt = picked);
    }
  }

  Future<void> _saveTasting() async {
    if (_isSaving) return;
    debugPrint('Save Tasting tapped for wineId=${widget.want.id}');
    FocusScope.of(context).unfocus();
    debugPrint('Dismissing keyboard before save');
    setState(() => _isSaving = true);

    final notes = _notesController.text.trim();
    final purchaseNotes = _purchaseNotesController.text.trim();
    debugPrint(
        'Sending tasting update payload: rating=$_rating, tastedAt=$_tastedAt, flavors=${_flavors.length}, styles=${_styles.length}');

    try {
      await widget.ref.read(cellarControllerProvider.notifier).markWantAsTried(
            want: widget.want,
            rating: _rating,
            flavorTags: _flavors.toList()..sort(),
            styleTags: _styles.toList()..sort(),
            customNotes: notes,
            purchaseNotes: purchaseNotes.isEmpty ? null : purchaseNotes,
            tastedAt: _tastedAt,
          );
      debugPrint('Tasting save success');
      if (!mounted) return;
      debugPrint('Closing Mark as Tried page');
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('Refreshing cellar providers after save');
        widget.ref.invalidate(cellarControllerProvider);
        if (widget.parentContext.mounted) {
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            const SnackBar(content: Text('Tasting saved successfully.')),
          );
        }
      });
    } catch (e) {
      debugPrint('MarkAsTriedSheet: markWantAsTried error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save tasting. Please try again.'),
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Mark as Tried', style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                widget.want.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              StarRatingSelector(
                value: _rating,
                onChanged: (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: Text(
                    '${_tastedAt.year}-${_tastedAt.month.toString().padLeft(2, '0')}-${_tastedAt.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Flavors', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              MultiSelectChips(
                options: _flavorOptions,
                selected: _flavors,
                onChanged: (s) => setState(() => _flavors = s),
              ),
              const SizedBox(height: 16),
              Text('Body & Style', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              MultiSelectChips(
                options: _styleOptions,
                selected: _styles,
                onChanged: (s) => setState(() => _styles = s),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Quick thoughts, pairing, would you buy again?',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purchaseNotesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Purchase / Revisit notes (optional)',
                  hintText: 'Where you bought it, revisit plans',
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSaving ? null : _saveTasting,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5C4A3F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save Tasting'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
