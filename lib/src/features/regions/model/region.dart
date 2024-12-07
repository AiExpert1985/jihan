import 'package:tablets/src/common/values/constants.dart' as constants;
import 'package:tablets/src/common/interfaces/base_item.dart';

class Region implements BaseItem {
  @override
  String dbRef;
  @override
  String name;
  @override
  List<String> imageUrls;

  Region({
    required this.dbRef,
    required this.name,
    required this.imageUrls,
  });

  @override
  String get coverImageUrl => imageUrls.isNotEmpty ? imageUrls[imageUrls.length - 1] : constants.defaultImageUrl;

  @override
  Map<String, dynamic> toMap() {
    return {
      'dbRef': dbRef,
      'name': name,
      'imageUrls': imageUrls,
    };
  }

  factory Region.fromMap(Map<String, dynamic> map) {
    return Region(
      dbRef: map['dbRef'] ?? '',
      name: map['name'] ?? '',
      imageUrls: List<String>.from(map['imageUrls']),
    );
  }

  @override
  String toString() => 'Region(dbRef: $dbRef, name: $name, imageUrls: $imageUrls)';
}
