import 'package:flutter_cache_manager/flutter_cache_manager.dart' as caching_manager;
// import 'package:tablets/src/constants/gaps.dart' as constants;

void customInialization() {
  clearCachedNetworkImages();
  // initializDefaultImageFile();
}

// I needed to remove cached images for two reasons:
// (1) app stopped when I first used cached images, and worked only after I cleared cache
// (2) I don't want to slow the device due to my app cached image accumulation
void clearCachedNetworkImages() {
  caching_manager.DefaultCacheManager().emptyCache();
}

// I didn't any good way to run static method when class is loaded, so I run below code
// void initializDefaultImageFile() {
//   gaps.DefaultImage.initializDefaultImageFile();
// }
