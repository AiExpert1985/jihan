import 'package:tablets/src/common/interfaces/base_item.dart';

enum UserPrivilage { admin, salesman, guest }

class UserAccount implements BaseItem {
  UserAccount(this.name, this.dbRef, this.email, this.privilage, this.hasAccess);

  @override
  String name;
  @override
  String dbRef;
  String email;
  String privilage;
  bool hasAccess;

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
      'hasAccess': hasAccess,
    };
  }
}
