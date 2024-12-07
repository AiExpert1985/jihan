import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/providers/storage_repository.dart';
import 'package:tablets/src/common/functions/utils.dart' as utils;
import 'package:tablets/src/common/values/constants.dart' as constants;
import 'package:tablets/src/common/functions/debug_print.dart' as debug;

class CustomImagePicker {
  static Future<Uint8List?> selectImage({uploadingMethod, imageSource = 'gallery'}) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);

      if (result != null && result.files.isNotEmpty) {
        Uint8List? image = result.files.first.bytes;
        return utils.compressImage(image);
      }
    } catch (e) {
      debug.errorPrint(e, stackTrace: StackTrace.current);
      return null;
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

  void addImage() async {
    String? newUrl;
    String imageName = utils.generateRandomString();
    Uint8List? imageFile = await CustomImagePicker.selectImage();
    if (imageFile != null) {
      newUrl = await _imageStorage.uploadImage(fileName: imageName, file: imageFile);
    }
    if (newUrl != null) {
      state = [...state, newUrl];
      addedUrls.add(newUrl);
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
