import 'package:tablets/src/common/functions/debug_print.dart';

// multipleMatch for selecting multiple items from dropdown selection and return all items
// that contains any of these selections
enum FilterCriteria {
  contains,
  equals,
  lessThanOrEqual,
  lessThan,
  moreThanOrEqual,
  moreThan,
  dateAfter,
  dateBefore
}

// each filter is Map<String, Map<String, dynmic>>
// example {'qunatityMoreThan': {'property': 'quantity', 'criteria': FilterCriteria.moreThan, 'value': 100}}
const String propertyKey = 'property'; // the name of property in screen data that we filter
const String criteriaKey = 'criteria'; // criteria we filter on (equals, contains, more than, .. )
const String valueKey = 'value'; // the actual value we are searching for
const String filterNameKey = 'filterName'; // the name that distinquish filter from other filters

class ScreenDataFilters {
  ScreenDataFilters(this._filters);

  Map<String, Map<String, dynamic>> _filters;

  void updateFilters(
      String filterName, String propertyName, FilterCriteria filterCriteria, dynamic value) {
    _filters[filterName] = {
      propertyKey: propertyName,
      criteriaKey: filterCriteria,
      valueKey: value
    };
  }

  List<Map<String, dynamic>> applyListFilter(
    List<Map<String, dynamic>> listValue,
  ) {
    for (var filter in _filters.values) {
      String propertyName = filter[propertyKey];
      FilterCriteria criteria = filter[criteriaKey];
      dynamic value = filter[valueKey];
      if (value == null || value.toString().trim().isEmpty) {
        continue;
      } else if (criteria == FilterCriteria.contains) {
        listValue = listValue.where((item) => (item[propertyName] ?? '').contains(value)).toList();
      } else if (criteria == FilterCriteria.equals) {
        listValue = listValue.where((item) => item[propertyName] == value).toList();
      } else if (criteria == FilterCriteria.lessThanOrEqual) {
        listValue = listValue.where((item) => item[propertyName] <= value).toList();
      } else if (criteria == FilterCriteria.lessThan) {
        listValue = listValue.where((item) => item[propertyName] < value).toList();
      } else if (criteria == FilterCriteria.moreThanOrEqual) {
        listValue = listValue.where((item) => item[propertyName] >= value).toList();
      } else if (criteria == FilterCriteria.moreThan) {
        listValue = listValue.where((item) => item[propertyName] > value).toList();
      } else if (criteria == FilterCriteria.dateAfter) {
        listValue = listValue
            .where((item) =>
                item[propertyName].toDate().isAfter(value) ||
                item[propertyName].toDate().isAtSameMomentAs(value))
            .toList();
      } else if (criteria == FilterCriteria.dateBefore) {
        listValue = listValue
            .where((item) =>
                item[propertyName].toDate().isBefore(value) ||
                item[propertyName].toDate().isAtSameMomentAs(value))
            .toList();
      } else {
        errorPrint('unknown filter criteria');
      }
    }
    return listValue;
  }

  dynamic getFilterValue(String filterName) {
    if (!_filters.containsKey(filterName)) {
      return null;
    }
    dynamic value = _filters[filterName]!['value'];
    if (value == null) return null;
    if (value is int || value is double) {
      return value.toString();
    } else if (value is String || value is DateTime) {
      return value;
    } else {
      errorPrint('unknow value type for filter name $filterName');
      return value.toString();
    }
  }

  void reset() {
    _filters = {};
  }
}
