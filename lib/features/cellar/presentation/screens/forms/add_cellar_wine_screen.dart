import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/controllers/cellar_controller.dart';
import '../../../domain/models/wine_type.dart';

enum AddCellarTarget { wants }

class AddCellarArgs {
  final AddCellarTarget target;
  final String? prefillTitle;
  final WineType? prefillType;

  const AddCellarArgs({
    required this.target,
    this.prefillTitle,
    this.prefillType,
  });
}

class AddCellarWineScreen extends ConsumerStatefulWidget {
  const AddCellarWineScreen({
    super.key,
    required this.target,
    this.prefillTitle,
    this.prefillType,
  });

  final AddCellarTarget target;
  final String? prefillTitle;
  final WineType? prefillType;

  @override
  ConsumerState<AddCellarWineScreen> createState() => _AddCellarWineScreenState();
}

class _AddCellarWineScreenState extends ConsumerState<AddCellarWineScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  WineType _type = WineType.red;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefillTitle ?? '');
    _type = widget.prefillType ?? WineType.red;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _nameController.text.trim();

    debugPrint(
        'AddCellarWineScreen: saving manual want title="$title", type=${_type.label}');
    try {
      final controller = ref.read(cellarControllerProvider.notifier);
      await controller.addManualWant(title: title, type: _type);
      if (mounted) context.pop();
    } catch (e) {
      debugPrint('AddCellarWineScreen: addManualWant error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Could not add wine to Wants. Please try again later.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const label = 'Add to Wants';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text(label),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Wine details',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Wine name',
                    hintText: 'e.g. Barolo DOCG 2018',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Type',
                  ),
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
                    child: const Text('Save'),
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

