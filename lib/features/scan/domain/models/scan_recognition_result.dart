class ScanRecognitionResult {
  final String? barcode;
  final String? productName;

  const ScanRecognitionResult({
    this.barcode,
    this.productName,
  });

  bool get hasAnything =>
      (barcode != null && barcode!.trim().isNotEmpty) ||
      (productName != null && productName!.trim().isNotEmpty);
}

