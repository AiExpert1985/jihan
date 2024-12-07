import 'package:tablets/src/common/values/constants.dart' as constants;
import 'package:tablets/src/common/interfaces/base_item.dart';

class Salesman implements BaseItem {
  @override
  String dbRef;
  @override
  String name;
  @override
  List<String> imageUrls;
  String? phone;
  double salary;

  Salesman({
    required this.dbRef,
    required this.name,
    required this.imageUrls,
    required this.salary,
    this.phone,
  });

  @override
  String get coverImageUrl => imageUrls.isNotEmpty ? imageUrls[imageUrls.length - 1] : constants.defaultImageUrl;

  @override
  Map<String, dynamic> toMap() {
    return {
      'dbRef': dbRef,
      'name': name,
      'imageUrls': imageUrls,
      'phone': phone,
      'salary': salary,
    };
  }

  factory Salesman.fromMap(Map<String, dynamic> map) {
    return Salesman(
      dbRef: map['dbRef'] ?? '',
      name: map['name'] ?? '',
      imageUrls: List<String>.from(map['imageUrls']),
      salary: map['salary'] ?? 0,
      phone: map['phone'],
    );
  }

  @override
  String toString() => 'ProductCategory(dbRef: $dbRef, name: $name, imageUrls: $imageUrls)';
}
