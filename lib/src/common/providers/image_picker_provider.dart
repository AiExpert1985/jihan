import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/providers/storage_repository.dart';
import 'package:tablets/src/common/functions/utils.dart' as utils;
import 'package:tablets/src/common/values/constants.dart' as constants;
import 'package:tablets/src/common/functions/debug_print.dart' as debug;

class CustomImagePicker {
  static Future<Uint8List?> selectImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'bmp', 'gif'], // Windows-specific extensions
        allowMultiple: false,
        withData: true, // Ensure file bytes are loaded
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) {
          debug.errorPrint('File bytes are null');
          return null;
        }
        return utils.compressImage(file.bytes!);
      }
    } catch (e, stackTrace) {
      debug.errorPrint('Image selection error: $e', stackTrace: stackTrace);
    }
    return null;
  }
}

class ImageSliderNotifier extends StateNotifier<List<String>> {
  ImageSliderNotifier(this._imageStorage, super.state);
  final StorageRepository _imageStorage;
  List<String> addedUrls = [];
  List<String> removedUrls = [];

  void initialize({List<String>? urls}) {
    state = urls ?? [constants.defaultImageUrl];
    addedUrls = [];
    removedUrls = [];
  }

  void addImage(BuildContext context) async {
    String? newUrl;
    String imageName = utils.generateRandomString();
    Uint8List? imageFile = await CustomImagePicker.selectImage();
    if (imageFile != null) {
      newUrl = await _imageStorage.uploadImage(fileName: imageName, file: imageFile);
    }
    if (newUrl != null) {
      state = [...state, newUrl];
      addedUrls.add(newUrl);
      if (context.mounted) {
        successUserMessage(context, 'تم تحميل الصورة بنجاح');
      }
      return;
    }
  }

  void removeImage(int urlIndex) async {
    if (state[urlIndex] == constants.defaultImageUrl) return; // don't remove default image
    removedUrls.add(state[urlIndex]);
    List<String> tempList = [...state];
    tempList.removeAt(urlIndex);
    state = [...tempList];
  }

// delete all images removed by user and return the new updated Urls currently used
  List<String> saveChanges() {
    for (String url in removedUrls) {
      _imageStorage.deleteImage(url);
    }
    addedUrls = [];
    return state;
  }

  void close() {
    for (String url in addedUrls) {
      _imageStorage.deleteImage(url);
    }
  }
}

final imagePickerProvider = StateNotifierProvider<ImageSliderNotifier, List<String>>((ref) {
  final imageStorage = ref.read(imageStorageProvider);
  return ImageSliderNotifier(imageStorage, []);
});
