import 'package:tablets/src/common/interfaces/base_item.dart';

class UserAccount implements BaseItem {
  UserAccount(this.name, this.dbRef, this.email, this.privilage, {this.isBlocked = false});

  @override
  String name;
  @override
  String dbRef;
  String? email;
  String? privilage;
  bool isBlocked;

  @override
  String get coverImageUrl => '';

  @override
  List<String> get imageUrls => [];

  @override
  Map<String, dynamic> toMap() {
    return {
      'dbRef': dbRef,
      'name': name,
      'imageUrls': imageUrls,
      'email': email,
      'privilage': privilage,
      'isBlocked': isBlocked,
    };
  }
}
