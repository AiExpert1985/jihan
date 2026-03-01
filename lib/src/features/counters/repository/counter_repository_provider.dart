import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart';

// Repository for counter operations
class CounterRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'counters';

  // Get the next transaction number and increment the counter
  // Reads from local Firebase cache for instant response (cache is fresh from app startup)
  // Falls back to server if cache is empty (e.g., first launch)
  // Counter increment is fire-and-forget (syncs to server via Firebase persistence)
  Future<int> getNextNumber(String transactionType) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(transactionType);

      // Read from cache first (instant), fallback to server if cache miss
      DocumentSnapshot docSnapshot;
      try {
        docSnapshot = await docRef.get(const GetOptions(source: Source.cache));
      } catch (e) {
        // Cache miss (e.g., first launch before startup fetch completes) - fallback to server
        docSnapshot = await docRef.get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
      }

      int nextNumber = 1; // Default starting number

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>?;
        if (data != null && data['nextNumber'] != null) {
          nextNumber = data['nextNumber'] is int
              ? data['nextNumber']
              : (data['nextNumber'] as num).toInt();
        }
      } else {
        // Counter doesn't exist, create it (fire-and-forget, syncs via Firebase persistence)
        // ignore: unawaited_futures
        docRef.set({
          'transactionType': transactionType,
          'nextNumber': 2, // Next available will be 2
        });
        tempPrint('Counter created for $transactionType, starting at 1');
        return 1;
      }

      // Fire-and-forget: update counter for next use (syncs to server via Firebase persistence)
      // ignore: unawaited_futures
      docRef.update({
        'nextNumber': nextNumber + 1,
      });

      tempPrint('Counter for $transactionType: returning $nextNumber, updated to ${nextNumber + 1}');
      return nextNumber;
    } catch (e) {
      errorPrint('Error getting next number for $transactionType: $e');
      rethrow;
    }
  }

  // Initialize counter with a specific starting value
  Future<void> initializeCounter(String transactionType, int startingNumber) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(transactionType);
      await docRef.set({
        'transactionType': transactionType,
        'nextNumber': startingNumber,
      });
      tempPrint('Counter initialized for $transactionType with starting value $startingNumber');
    } catch (e) {
      errorPrint('Error initializing counter for $transactionType: $e');
      rethrow; // Propagate error so button handler can show it
    }
  }

  // Get current counter value without incrementing
  Future<int> getCurrentNumber(String transactionType) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(transactionType);
      final docSnapshot = await docRef.get().timeout(const Duration(seconds: 5));

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['nextNumber'] != null) {
          return data['nextNumber'] is int
              ? data['nextNumber']
              : (data['nextNumber'] as num).toInt();
        }
      }
      return 1; // Default if counter doesn't exist
    } catch (e) {
      errorPrint('Error getting current number for $transactionType: $e');
      return 1;
    }
  }

  /// Fetch all counters from server to warm the local cache.
  /// Called at app startup and from the transaction sync button.
  Future<void> refreshCountersFromServer() async {
    try {
      await _firestore.collection(_collectionName)
          .get(const GetOptions(source: Source.server));
      tempPrint('Counters refreshed from server');
    } catch (e) {
      errorPrint('Error refreshing counters from server: $e');
    }
  }

  // Decrement counter by one
  Future<void> decrementCounter(String transactionType) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(transactionType);
      final docSnapshot = await docRef.get().timeout(const Duration(seconds: 5));

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['nextNumber'] != null) {
          int currentNext = data['nextNumber'] is int
              ? data['nextNumber']
              : (data['nextNumber'] as num).toInt();

          // Only decrement if counter is > 1
          if (currentNext > 1) {
            await docRef.update({'nextNumber': currentNext - 1});
            tempPrint('Counter decremented for $transactionType from $currentNext to ${currentNext - 1}');
          }
        }
      }
    } catch (e) {
      errorPrint('Error decrementing counter for $transactionType: $e');
    }
  }
}

final counterRepositoryProvider = Provider<CounterRepository>((ref) => CounterRepository());
