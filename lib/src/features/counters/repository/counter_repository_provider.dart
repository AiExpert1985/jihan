import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart';

// Repository for counter operations
class CounterRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'counters';

  // Get the next transaction number and increment the counter
  Future<int> getNextNumber(String transactionType) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(transactionType);

      // Get the current counter value (with timeout to prevent hanging on unstable internet)
      final docSnapshot = await docRef.get().timeout(const Duration(seconds: 5));

      int nextNumber = 1; // Default starting number

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['nextNumber'] != null) {
          nextNumber = data['nextNumber'] is int
              ? data['nextNumber']
              : (data['nextNumber'] as num).toInt();
        }
      } else {
        // Counter doesn't exist, create it with initial value
        await docRef.set({
          'transactionType': transactionType,
          'nextNumber': 2, // Next available will be 2
        });
        tempPrint('Counter created for $transactionType, starting at 1');
        return 1;
      }

      // Update the counter to the next value for the next user
      await docRef.update({
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

  // Update counter to ensure it's at least targetNumber
  Future<void> ensureCounterAtLeast(String transactionType, int targetNumber) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(transactionType);
      final docSnapshot = await docRef.get().timeout(const Duration(seconds: 5));

      int currentNext = 1;
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['nextNumber'] != null) {
          currentNext = data['nextNumber'] is int
              ? data['nextNumber']
              : (data['nextNumber'] as num).toInt();
        }
      }

      // Only update if target is higher than current
      if (targetNumber >= currentNext) {
        await docRef.set({
          'transactionType': transactionType,
          'nextNumber': targetNumber + 1,
        });
        tempPrint('Counter updated for $transactionType from $currentNext to ${targetNumber + 1}');
      }
    } catch (e) {
      errorPrint('Error ensuring counter for $transactionType: $e');
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
