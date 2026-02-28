import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tablets/src/common/interfaces/base_item.dart';
import 'package:tablets/src/common/functions/debug_print.dart';

class DbRepository {
  DbRepository(this._collectionName);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collectionName;
  final String _dbReferenceKey = 'dbRef';

  /// Returns true if save succeeded, false if failed
  /// Uses dbRef as document ID to ensure idempotency (prevents duplicates)
  /// With persistence enabled, writes go to local cache first and sync in background
  Future<bool> addItem(BaseItem item) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(item.dbRef)
          .set(item.toMap())
          .timeout(const Duration(seconds: 5));
      debugLog('Item added successfully!');
      return true;
    } catch (e) {
      errorPrint('Error adding item to firestore: $e');
      return false;
    }
  }

  /// Add or update an item using its dbRef as the document ID
  /// This is preferred for cache collections where we need predictable IDs
  Future<void> addOrUpdateItemWithRef(BaseItem item) async {
    try {
      final itemMap = item.toMap();
      final collectionRef = _firestore.collection(_collectionName);
      final docRef = collectionRef.doc(item.dbRef);
      // Use merge: true for Flutter Web compatibility
      await docRef.set(itemMap, SetOptions(merge: true));
    } catch (e) {
      errorPrint('Error saving item to $_collectionName: $e');
    }
  }

  /// Batch add or update multiple items using their dbRef as document IDs
  /// Firebase allows max 500 operations per batch, so we chunk the items
  /// This is MUCH faster than individual writes for large collections
  Future<void> batchAddOrUpdateItemsWithRef(List<BaseItem> items) async {
    if (items.isEmpty) return;

    const int batchSize = 500; // Firebase batch limit
    final collectionRef = _firestore.collection(_collectionName);

    // Process items in chunks of 500
    for (var i = 0; i < items.length; i += batchSize) {
      final chunk = items.skip(i).take(batchSize).toList();
      final batch = _firestore.batch();

      for (var item in chunk) {
        final docRef = collectionRef.doc(item.dbRef);
        // Use merge: true for Flutter Web compatibility
        batch.set(docRef, item.toMap(), SetOptions(merge: true));
      }

      try {
        await batch.commit();
        debugLog('Batch committed ${chunk.length} items to $_collectionName');
      } catch (e) {
        errorPrint('Error in batch commit to $_collectionName: $e');
      }
    }
  }

  /// Returns true if update succeeded, false if failed
  /// Queries Firestore cache first to find the actual document reference,
  /// which handles documents where document ID differs from dbRef field
  /// (e.g., documents created by mobile app with auto-generated IDs).
  /// Falls back to direct doc(dbRef).set() if not found in cache.
  Future<bool> updateItem(BaseItem updatedItem) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where(_dbReferenceKey, isEqualTo: updatedItem.dbRef)
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(seconds: 5));
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference
            .set(updatedItem.toMap())
            .timeout(const Duration(seconds: 5));
      } else {
        // Document not in cache - use direct document ID
        await _firestore
            .collection(_collectionName)
            .doc(updatedItem.dbRef)
            .set(updatedItem.toMap())
            .timeout(const Duration(seconds: 5));
      }
      debugLog('Item updated successfully!');
      return true;
    } catch (e) {
      errorPrint('Error updating item in firestore: $e');
      return false;
    }
  }

  /// Returns true if delete succeeded, false if failed
  /// Queries Firestore cache first to find the actual document reference,
  /// which handles documents where document ID differs from dbRef field
  /// (e.g., documents created by mobile app with auto-generated IDs).
  /// Falls back to direct doc(dbRef).delete() if not found in cache.
  Future<bool> deleteItem(BaseItem item) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where(_dbReferenceKey, isEqualTo: item.dbRef)
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(seconds: 5));
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference
            .delete()
            .timeout(const Duration(seconds: 5));
      } else {
        // Document not in cache - try direct delete by document ID as fallback
        await _firestore
            .collection(_collectionName)
            .doc(item.dbRef)
            .delete()
            .timeout(const Duration(seconds: 5));
      }
      debugLog('Item deleted successfully!');
      return true;
    } catch (e) {
      errorPrint('Error deleting item from firestore: $e');
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> watchItemListAsMaps() {
    final ref = _firestore.collection(_collectionName);
    return ref.snapshots().map((snapshot) =>
        snapshot.docs.map((docSnapshot) => docSnapshot.data()).toList());
  }

  // watch collection that is filtered by on one criterial, example watch specific date
  Stream<List<Map<String, dynamic>>> watchItemListAsFilteredMaps(
      String key, dynamic value) {
    final ref =
        _firestore.collection(_collectionName).where(key, isEqualTo: value);
    return ref.snapshots().map((snapshot) =>
        snapshot.docs.map((docSnapshot) => docSnapshot.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> watchItemListAsFilteredDateMaps(
      String key, DateTime targetDate) {
    // Get the start and end of the target date in UTC
    final startOfDay =
        DateTime(targetDate.year, targetDate.month, targetDate.day, 00, 00, 00);
    final endOfDay =
        DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

    // Log the start and end dates for debugging
    tempPrint('Filtering from $startOfDay to $endOfDay');

    final ref = _firestore
        .collection(_collectionName)
        .where(key, isGreaterThanOrEqualTo: startOfDay)
        .where(key, isLessThanOrEqualTo: endOfDay);

    return ref.snapshots().map((snapshot) {
      return snapshot.docs.map((docSnapshot) => docSnapshot.data()).toList();
    });
  }

  // /// below function was not tested
  // Stream<List<BaseItem>> watchItemListAsItems() {
  //   final query = _firestore.collection(_collectionName);
  //   final ref = query.withConverter(
  //     fromFirestore: (doc, _) => BaseItem.fromMap(doc.data()!),
  //     toFirestore: (BaseItem product, options) => product.toMap(),
  //   );
  //   return ref
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs.map((docSnapshot) => docSnapshot.data()).toList());
  // }

  // Future<BaseItem> fetchItemAsObject({String? filterKey, String? filterValue}) async {
  //   Query query = _firestore.collection(_collectionName);
  //   if (filterKey != null) {
  //     query = query
  //         .where(filterKey, isGreaterThanOrEqualTo: filterValue)
  //         .where(filterKey, isLessThan: '$filterValue\uf8ff');
  //   }
  //   final ref = query.withConverter(
  //     fromFirestore: (doc, _) => BaseItem.fromMap(doc.data()!),
  //     toFirestore: (BaseItem product, options) => product.toMap(),
  //   );
  //   final snapshot = await ref.get(const GetOptions(source: Source.cache));
  //   return snapshot.docs.map((docSnapshot) => docSnapshot.data()).toList().first;
  // }

  // Future<Map<String, dynamic>> fetchItemAsMap({String? filterKey, String? filterValue}) async {
  //   try {
  //     Query query = _firestore.collection(_collectionName);
  //     if (filterKey != null) {
  //       query = query
  //           .where(filterKey, isGreaterThanOrEqualTo: filterValue)
  //           .where(filterKey, isLessThan: '$filterValue\uf8ff');
  //     }
  //     final snapshot = await query.get(const GetOptions(source: Source.cache));
  //     return snapshot.docs
  //         .map((docSnapshot) => docSnapshot.data() as Map<String, dynamic>)
  //         .toList()
  //         .first;
  //   } catch (e) {
  //     errorLog('Error during fetching items from firbase - $e');
  //     return {};
  //   }
  // }

  // Future<List<BaseItem>> fetchItemListAsObjects({String? filterKey, String? filterValue}) async {
  //   try {
  //     Query query = _firestore.collection(_collectionName);
  //     if (filterKey != null) {
  //       query = query
  //           .where(filterKey, isGreaterThanOrEqualTo: filterValue)
  //           .where(filterKey, isLessThan: '$filterValue\uf8ff');
  //     }
  //     final ref = query.withConverter(
  //       fromFirestore: (doc, _) => BaseItem.fromMap(doc.data()!),
  //       toFirestore: (BaseItem product, options) => product.toMap(),
  //     );
  //     final snapshot = await ref.get(const GetOptions(source: Source.cache));
  //     return snapshot.docs.map((docSnapshot) => docSnapshot.data()).toList();
  //   } catch (e) {
  //     errorLog('Error during fetching items from firbase - $e');
  //     return [];
  //   }
  // }

  // Future<List<Map<String, dynamic>>> fetchItemListAsMaps(
  //     {String? filterKey, String? filterValue}) async {
  //   try {
  //     Query query = _firestore.collection(_collectionName);
  //     if (filterKey != null) {
  //       query = query
  //           .where(filterKey, isGreaterThanOrEqualTo: filterValue)
  //           .where(filterKey, isLessThan: '$filterValue\uf8ff');
  //     }
  //     final snapshot = await query.get(const GetOptions(source: Source.cache));
  //     return snapshot.docs
  //         .map((docSnapshot) => docSnapshot.data() as Map<String, dynamic>)
  //         .toList();
  //   } catch (e) {
  //     errorLog('Error during fetching items from firbase - $e');
  //     return [];
  //   }
  // }

  /// Fetches data from Firestore. Default behavior: uses server if online, cache if offline.
  /// Pass [source] to force a specific source (e.g., Source.server for sync buttons)
  Future<List<Map<String, dynamic>>> fetchItemListAsMaps(
      {String? filterKey, String? filterValue, Source? source}) async {
    try {
      Query query = _firestore.collection(_collectionName);

      if (filterKey != null) {
        query = query
            .where(filterKey, isGreaterThanOrEqualTo: filterValue)
            .where(filterKey, isLessThan: '$filterValue\uf8ff');
      }

      // If a specific source is requested, use it directly
      if (source != null) {
        final snapshot = await query.get(GetOptions(source: source));
        tempPrint('data fetched from $_collectionName (source: $source)');
        return snapshot.docs
            .map((docSnapshot) => docSnapshot.data() as Map<String, dynamic>)
            .toList();
      }

      // Default behavior: use server if online, cache if offline
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet) ||
          connectivityResult.contains(ConnectivityResult.vpn) ||
          connectivityResult.contains(ConnectivityResult.mobile)) {
        final snapshot = await query.get();
        tempPrint('data fetched from firebase ($_collectionName)live data');
        return snapshot.docs
            .map((docSnapshot) => docSnapshot.data() as Map<String, dynamic>)
            .toList();
      } else {
        tempPrint('data fetched from cache ($_collectionName)');
        final cachedSnapshot =
            await query.get(const GetOptions(source: Source.cache));
        return cachedSnapshot.docs
            .map((docSnapshot) => docSnapshot.data() as Map<String, dynamic>)
            .toList();
      }
    } catch (e) {
      debugLog('Error during fetching items from Firebase - $e');
      return [];
    }
  }
}
