import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Uses Android 13+ Photo Picker for gallery picks so broad media read
/// permissions are not required. No-op on web and non-Android platforms.
void configureAndroidPhotoPicker() {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android) return;
  final impl = ImagePickerPlatform.instance;
  if (impl is ImagePickerAndroid) {
    impl.useAndroidPhotoPicker = true;
  }
}
