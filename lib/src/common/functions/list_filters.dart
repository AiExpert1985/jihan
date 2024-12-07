import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/utils.dart' as utils;

enum FilterCriteria { contains, equals, lessThanOrEqual, lessThan, moreThanOrEqual, moreThan }

enum DataTypes { int, double, string }

/// add filter to filtersMap
/// if value is empty, then the filter is removed from filtersMap
Map<String, Map<String, dynamic>> updateFilters(
  Map<String, Map<String, dynamic>> filters,
  String dataType,
  String key,
  dynamic value,
  String filterCriteria,
) {
  if (value == null || value.isEmpty) {
    filters.remove(key);
    return filters;
  }

  if (dataType == DataTypes.double.name) {
    value = double.parse(value);
  }
  filters[key] = {
    'value': value,
    'criteria': filterCriteria,
  };
  return filters;
}

/// filters should have these keys {'xxx':{'criteria': xxx, 'value': xxx}}
AsyncValue<List<Map<String, dynamic>>> applyListFilterOnAsync(
  AsyncValue<List<Map<String, dynamic>>> listValue,
  Map<String, Map<String, dynamic>> filters,
) {
  List<Map<String, dynamic>> filteredList = utils.convertAsyncValueListToList(listValue);
  filters.forEach((key, filter) {
    String criteria = filter['criteria'];
    dynamic value = filter['value'];
    if (criteria == FilterCriteria.contains.name) {
      filteredList = filteredList.where((item) => item[key].contains(value)).toList();
      return;
    }
    if (criteria == FilterCriteria.equals.name) {
      filteredList = filteredList.where((product) => product[key] == value).toList();
      return;
    }
  });
  return AsyncValue.data(filteredList);
}

/// filters should have these keys {'propertyName':{'criteria': xxx, 'value': xxx}}
/// for example, in propertyNamed 'name' the criteria is 'contains' the vaue 'moh'
List<Map<String, dynamic>> applyListFilter(
  List<Map<String, dynamic>> listValue,
  Map<String, Map<String, dynamic>> filters,
) {
  filters.forEach((key, filter) {
    String criteria = filter['criteria'];
    dynamic value = filter['value'];
    if (criteria == FilterCriteria.contains.name) {
      listValue = listValue.where((item) => item[key].contains(value)).toList();
    } else if (criteria == FilterCriteria.equals.name) {
      listValue = listValue.where((product) => product[key] == value).toList();
    } else if (criteria == FilterCriteria.lessThanOrEqual.name) {
      listValue = listValue.where((product) => product[key] <= value).toList();
    } else if (criteria == FilterCriteria.lessThan.name) {
      listValue = listValue.where((product) => product[key] < value).toList();
    } else if (criteria == FilterCriteria.moreThanOrEqual.name) {
      listValue = listValue.where((product) => product[key] >= value).toList();
    } else if (criteria == FilterCriteria.moreThan.name) {
      listValue = listValue.where((product) => product[key] > value).toList();
    } else {
      errorPrint('unknown filter criteria');
    }
  });
  return listValue;
}
