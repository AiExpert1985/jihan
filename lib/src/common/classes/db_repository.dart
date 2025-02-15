import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tablets/src/common/interfaces/base_item.dart';
import 'package:tablets/src/common/functions/debug_print.dart';

class DbRepository {
  DbRepository(this._collectionName);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collectionName;
  final String _dbReferenceKey = 'dbRef';

  Future<void> addItem(BaseItem item) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.vpn)) {
      // Device is connected to the internet
      try {
        await _firestore.collection(_collectionName).doc().set(item.toMap());
        tempPrint('Item added to live firestore successfully!');
        return;
      } catch (e) {
        errorPrint('Error adding item to live firestore: $e');
        return;
      }
    }
    // Device is offline
    final docRef = _firestore.collection(_collectionName).doc();
    docRef.set(item.toMap()).then((_) {
      tempPrint('Item added to firestore cache!');
    }).catchError((e) {
      errorPrint('Error adding item to firestore cache: $e');
    });
  }

  Future<void> updateItem(BaseItem updatedItem) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.vpn)) {
      // Device is connected to the internet
      try {
        final query = _firestore
            .collection(_collectionName)
            .where(_dbReferenceKey, isEqualTo: updatedItem.dbRef);
        final querySnapshot = await query.get(const GetOptions(source: Source.cache));
        if (querySnapshot.size > 0) {
          final documentRef = querySnapshot.docs[0].reference;
          await documentRef.update(updatedItem.toMap());
          debugLog('Item updated in live firestore successfully!');
        }
        return;
      } catch (e) {
        errorPrint('Error updating item in live firestore: $e');
        return;
      }
    }
    // when offline
    final query =
        _firestore.collection(_collectionName).where(_dbReferenceKey, isEqualTo: updatedItem.dbRef);
    final querySnapshot = await query.get(const GetOptions(source: Source.cache));
    if (querySnapshot.size > 0) {
      final documentRef = querySnapshot.docs[0].reference;
      await documentRef.update(updatedItem.toMap()).then((_) {
        tempPrint('Item updated in firestore cache!');
      }).catchError((e) {
        errorPrint('Error updating item in firebase cache: $e');
      });
    }
  }

  Future<void> deleteItem(BaseItem item) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.vpn)) {
      // Device is connected to the internet
      try {
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .where(_dbReferenceKey, isEqualTo: item.dbRef)
            .get(const GetOptions(source: Source.cache));
        if (querySnapshot.size > 0) {
          final documentRef = querySnapshot.docs[0].reference;
          await documentRef.delete();
          tempPrint('Item deleted from live firestore successfully!');
        }
        return;
      } catch (e) {
        errorPrint('Error deleting item from firestore cache: $e');
        return;
      }
    }
    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where(_dbReferenceKey, isEqualTo: item.dbRef)
        .get(const GetOptions(source: Source.cache));
    if (querySnapshot.size > 0) {
      final documentRef = querySnapshot.docs[0].reference;
      await documentRef.delete().then((_) {
        tempPrint('Item deleted from firestore cache!');
      }).catchError((e) {
        errorPrint('Error deleting item from firestore cache: $e');
      });
    }
  }

  Stream<List<Map<String, dynamic>>> watchItemListAsMaps() {
    final ref = _firestore.collection(_collectionName);
    return ref
        .snapshots()
        .map((snapshot) => snapshot.docs.map((docSnapshot) => docSnapshot.data()).toList());
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

  /// below function fetch data from firestore if there is internet connection
  /// if not, it fetch from cache
  Future<List<Map<String, dynamic>>> fetchItemListAsMaps(
      {String? filterKey, String? filterValue}) async {
    try {
      Query query = _firestore.collection(_collectionName);

      if (filterKey != null) {
        query = query
            .where(filterKey, isGreaterThanOrEqualTo: filterValue)
            .where(filterKey, isLessThan: '$filterValue\uf8ff');
      }
      // Attempt to fetch data from Firestore
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet) ||
          connectivityResult.contains(ConnectivityResult.vpn)) {
        final snapshot = await query.get();
        tempPrint('data fetched from firebase ($_collectionName)live data');
        return snapshot.docs
            .map((docSnapshot) => docSnapshot.data() as Map<String, dynamic>)
            .toList();
      } else {
        tempPrint('data fetched from cache ($_collectionName)');
        final cachedSnapshot = await query.get(const GetOptions(source: Source.cache));
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
