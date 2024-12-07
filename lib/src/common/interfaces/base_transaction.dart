import 'package:tablets/src/common/interfaces/base_item.dart';

abstract class BaseTransaction implements BaseItem {
  int get number;
  DateTime get date;
  double get amount;
  String get currencty;
  String get notes;
}
