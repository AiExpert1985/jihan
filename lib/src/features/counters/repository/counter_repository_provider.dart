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

      // Get the current counter value
      final docSnapshot = await docRef.get();

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
      // Fallback to timestamp-based number to avoid blocking
      return DateTime.now().millisecondsSinceEpoch % 100000;
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
    }
  }

  // Get current counter value without incrementing
  Future<int> getCurrentNumber(String transactionType) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(transactionType);
      final docSnapshot = await docRef.get();

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
}

final counterRepositoryProvider = Provider<CounterRepository>((ref) => CounterRepository());
