import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart' as debug;

class StorageRepository {
  StorageRepository(this._storage);
  final FirebaseStorage _storage;

  Future<String?> uploadImage({required String fileName, required Uint8List file}) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.vpn)) {
      // TODO I didn't find way similar to firestore to sync with firebase storage
      // TODO so I only allowed adding images when user is online
      // Device is connected to the internet
      try {
        final storageRef = _storage.ref().child('images').child('$fileName.jpg');
        await storageRef.putData(file);
        return await storageRef.getDownloadURL();
      } catch (e) {
        debug.errorPrint(e, stackTrace: StackTrace.current);
        return null;
      }
    }
    return null;
  }

  Future<void> deleteImage(String url) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.vpn)) {
      // currently only delete if online
      // TODO later I will find a way to delete when I am offline
      // TODO one way to put links to be deleted in database, and when back online
      // TODO check at the beginning of app and loop through them and delete ?
      // Device is connected to the internet
      try {
        final storageRef = _storage.refFromURL(url);
        await storageRef.delete();
      } catch (e) {
        debug.errorPrint(e, stackTrace: StackTrace.current);
      }
    }
  }
}

final imageStorageProvider = Provider<StorageRepository>((ref) {
  final FirebaseStorage storage = FirebaseStorage.instance;
  return StorageRepository(storage);
});
