// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/features/authentication/model/user_account.dart';
import 'package:tablets/src/features/authentication/repository/accounts_repository.dart';

class UserInfoNotifier extends StateNotifier<UserAccount> {
  UserInfoNotifier()
      : super(UserAccount(
            '', '', null, null)); // Initialize with null or a default SalesmanInfo instance

  void setDbRef(String value) {
    state = UserAccount(state.name, value, state.email, state.privilage);
  }

  void setName(String value) {
    state = UserAccount(value, state.dbRef, state.email, state.privilage);
  }

  void setEmail(String value) {
    state = UserAccount(state.name, state.dbRef, value, state.privilage);
  }

  void setPrivilage(String value) {
    state = UserAccount(state.name, state.dbRef, state.email, value);
  }

  void setAccess(bool value) {
    state = UserAccount(state.name, state.dbRef, state.email, state.privilage, isBlocked: value);
  }

  UserAccount get salesmanInfo => state;

  UserAccount get data => state;
}

// Create a provider for the SalesmanInfoNotifier
final userInfoProvider = StateNotifierProvider<UserInfoNotifier, UserAccount>((ref) {
  return UserInfoNotifier();
});

Future<void> loadUserInfo(WidgetRef ref) async {
  final accountsRepository = ref.read(accountsRepositoryProvider);
  final email = FirebaseAuth.instance.currentUser!.email;
  final accounts = await accountsRepository.fetchItemListAsMaps();
  final salesmanInfoNotifier = ref.read(userInfoProvider.notifier);
  var matchingAccounts = accounts.where((account) => account['email'] == email);
  if (matchingAccounts.isNotEmpty) {
    final dbRef = matchingAccounts.first['dbRef'];
    salesmanInfoNotifier.setDbRef(dbRef);
    final name = matchingAccounts.first['name'];
    salesmanInfoNotifier.setName(name);
    final email = matchingAccounts.first['email'];
    salesmanInfoNotifier.setEmail(email);
    final privilage = matchingAccounts.first['privilage'];
    salesmanInfoNotifier.setPrivilage(privilage);
    bool isBlocked = matchingAccounts.first['isBlocked'] ?? false;
    salesmanInfoNotifier.setAccess(isBlocked);
  }
}
