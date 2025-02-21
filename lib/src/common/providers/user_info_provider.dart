// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/features/authentication/model/user_account.dart';
import 'package:tablets/src/features/authentication/repository/accounts_repository.dart';

class UserInfoNotifier extends StateNotifier<UserAccount?> {
  UserInfoNotifier() : super(null);

  void setUserAccount(UserAccount userInfo) {
    state = userInfo;
  }

  bool hasPermission(List<String> allowedPrivilages) {
    if (state == null || !state!.hasAccess) {
      return false;
    }
    return allowedPrivilages.contains(state!.privilage) ||
        state!.privilage == UserPrivilage.admin.name;
  }

  void reset() {
    state = null;
  }

  Future<void> loadUserInfo(WidgetRef ref) async {
    final accountsRepository = ref.read(accountsRepositoryProvider);
    final email = FirebaseAuth.instance.currentUser!.email;
    final accounts = await accountsRepository.fetchItemListAsMaps();
    var matchingAccounts = accounts.where((account) => account['email'] == email);
    if (matchingAccounts.isNotEmpty) {
      final dbRef = matchingAccounts.first['dbRef'];
      final name = matchingAccounts.first['name'];
      final email = matchingAccounts.first['email'];
      final privilage = matchingAccounts.first['privilage'];
      final hasAccess = matchingAccounts.first['hasAccess'];
      final userInfo = UserAccount(name, dbRef, email, privilage, hasAccess);
      setUserAccount(userInfo);
    }
  }
}

// Create a provider for the SalesmanInfoNotifier
final userInfoProvider = StateNotifierProvider<UserInfoNotifier, UserAccount?>((ref) {
  return UserInfoNotifier();
});
