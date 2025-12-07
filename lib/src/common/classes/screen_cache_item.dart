import 'package:tablets/src/common/interfaces/base_item.dart';

/// A wrapper class that allows storing Map data as a BaseItem
/// This is used to save screen cache data to Firebase using DbRepository
class ScreenCacheItem implements BaseItem {
  ScreenCacheItem(this._data);

  final Map<String, dynamic> _data;

  @override
  String get dbRef => (_data['dbRef'] ?? '') as String;

  @override
  String get name => _data['name'] as String? ?? '';

  @override
  List<String> get imageUrls => [];

  @override
  String get coverImageUrl => '';

  @override
  Map<String, dynamic> toMap() => _data;
}
