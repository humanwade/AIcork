import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/scan/data/datasources/scanner_api_service.dart';
import '../../features/scan/domain/models/scan_wine_response.dart';
import '../../features/scan/domain/models/scan_history_entry.dart';
import '../../features/wine_recommendation/domain/entities/wine_entity.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  static const String routePath = '/scan';
  static const String routeName = 'scan';

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  bool _isRecognizing = false;
  final ScannerApiService _scannerApi = ScannerApiService.create();
  bool _loadingHistory = false;
  List<ScanHistoryEntry> _history = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _takePhoto() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file != null && mounted) {
      setState(() => _imagePath = file.path);
      _scanImage(file.path);
    }
  }

  Future<void> _chooseFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null && mounted) {
      setState(() => _imagePath = file.path);
      _scanImage(file.path);
    }
  }

  WineEntity _responseToWineEntity(ScanWineResponse response) {
    if (response.wineData != null) {
      final d = response.wineData!;
      return WineEntity(
        title: d.systitle,
        price: d.ecFinalPrice,
        sku: d.sku ?? 'scan-${DateTime.now().millisecondsSinceEpoch}',
        thumbnailUrl: d.ecThumbnails,
        tastingNotes: d.lcboTastingnotes.isNotEmpty ? d.lcboTastingnotes : null,
        sommelierNote: d.sommelierNote.isNotEmpty ? d.sommelierNote : null,
        inventoryUrl: d.inventoryUrl,
        matchedDb: response.matchedDb,
        canContribute: response.canContribute,
        recognizedWineName: response.wineName,
        recognizedWinery: response.winery,
        recognizedVintage: response.vintage,
        wineType: d.wineType,
      );
    }
    final parts = <String>[
      if (response.wineName != null && response.wineName!.isNotEmpty) response.wineName!,
      if (response.winery != null && response.winery!.isNotEmpty) response.winery!,
      if (response.vintage != null && response.vintage!.isNotEmpty) response.vintage!,
    ];
    final title = parts.isEmpty ? 'Unknown wine' : parts.join(' ');
    return WineEntity(
      title: title,
      price: 0,
      sku: 'scan-${DateTime.now().millisecondsSinceEpoch}',
      thumbnailUrl: null,
      tastingNotes: null,
      sommelierNote: null,
      inventoryUrl: null,
      matchedDb: false,
      canContribute: response.canContribute,
      recognizedWineName: response.wineName,
      recognizedWinery: response.winery,
      recognizedVintage: response.vintage,
      wineType: null,
    );
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final items = await _scannerApi.fetchScanHistory();
      if (!mounted) return;
      setState(() {
        _history = items;
        _loadingHistory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _history = const [];
        _loadingHistory = false;
      });
    }
  }

  Future<void> _scanImage(String path) async {
    if (_isRecognizing) return;
    setState(() => _isRecognizing = true);

    try {
      final file = File(path);
      if (!file.existsSync()) {
        if (mounted) _showError('Could not read the selected image.');
        return;
      }
      final response = await _scannerApi.scanWineLabel(file);

      if (!mounted) return;
      if (!response.recognized) {
        _showError('Could not recognize the wine label. Please try again with a clearer photo.');
        return;
      }
      debugPrint('Scan result received: matched_db=${response.matchedDb}');
      final wine = _responseToWineEntity(response);
      // Best-effort save to scan history; failures should not break flow.
      final historyName = wine.title.isNotEmpty
          ? wine.title
          : (response.wineName ?? 'Unknown wine');
      _scannerApi.saveScanHistory(
        wineName: historyName,
        sku: wine.sku,
        imageUrl: wine.thumbnailUrl,
      );
      // Refresh history in background.
      _loadHistory();
      context.push('/home/results/detail', extra: wine);
    } catch (e) {
      debugPrint('ScanPage: scan API error: $e');
      if (e is DioException && e.response?.statusCode == 404) {
        debugPrint('Scan API returned 404');
        debugPrint('Backend /scan route may not be registered');
      }
      if (mounted) {
        _showError('Could not recognize the wine label. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isRecognizing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scan & Search', style: theme.textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              'Identify wine from a photo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.brown.shade300,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ImageSourceButton(
                          icon: Icons.camera_alt_rounded,
                          label: 'Take Photo',
                          onPressed: _isRecognizing ? null : _takePhoto,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ImageSourceButton(
                          icon: Icons.photo_library_rounded,
                          label: 'Choose from Gallery',
                          onPressed: _isRecognizing ? null : _chooseFromGallery,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        File(_imagePath!),
                        fit: BoxFit.cover,
                        height: 280,
                        width: double.infinity,
                      ),
                    ),
                  ] else ...[
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1ECE7),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE3D9CF),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Take a photo or choose from gallery',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_loadingHistory) ...[
                    Text(
                      'Scan history',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading recent scans...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ] else if (_history.isNotEmpty) ...[
                    Text(
                      'Scan history',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: _history
                          .map(
                            (h) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.history_rounded,
                                color: Color(0xFF5C4A3F),
                              ),
                              title: Text(
                                h.wineName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: h.sku != null
                                  ? Text(
                                      'SKU ${h.sku}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: Colors.grey.shade700,
                                      ),
                                    )
                                  : null,
                              trailing: IconButton(
                                tooltip: 'Remove from history',
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.grey.shade500,
                                ),
                                onPressed: () async {
                                  await _scannerApi.deleteScanHistory(h.id);
                                  if (!mounted) return;
                                  setState(() {
                                    _history = _history
                                        .where((e) => e.id != h.id)
                                        .toList();
                                  });
                                },
                              ),
                              onTap: () {
                                final title = h.wineName.isNotEmpty
                                    ? h.wineName
                                    : 'Unknown wine';
                                final wine = WineEntity(
                                  title: title,
                                  price: 0,
                                  sku: h.sku ??
                                      'scan-history-${h.id.toString()}',
                                  thumbnailUrl: h.imageUrl,
                                  tastingNotes: null,
                                  sommelierNote: null,
                                  inventoryUrl: null,
                                  matchedDb: h.sku != null,
                                  canContribute: false,
                                  recognizedWineName: null,
                                  recognizedWinery: null,
                                  recognizedVintage: null,
                                  wineType: null,
                                );
                                context.push(
                                  '/home/results/detail',
                                  extra: wine,
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isRecognizing)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF5C4A3F),
                          ),
                          SizedBox(height: 16),
                          Text('Analyzing wine label...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  const _ImageSourceButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: theme.colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
