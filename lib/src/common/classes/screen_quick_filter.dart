import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/interfaces/screen_controller.dart';
import 'package:tablets/src/common/providers/screen_data_notifier.dart';

// Enum for filter types
enum QuickFilterType {
  contains,
  equals,
  lessThanOrEqual,
  lessThan,
  moreThanOrEqual,
  moreThan,
  dateAfter,
  dateBefore,
  dateSameDay
}

// Class representing a quick filter
class QuickFilter {
  QuickFilterType type;
  String property;
  dynamic value;

  QuickFilter(this.property, this.type, this.value);
}

// StateNotifier for managing quick filters
class ScreenDataQuickFilters extends StateNotifier<List<QuickFilter>> {
  ScreenDataQuickFilters(this._screenDataNotifier, this._screenController) : super([]);
  final ScreenDataNotifier _screenDataNotifier;
  final ScreenDataController _screenController;

  // Update or add a filter
  void updateFilters(QuickFilter newFilter) {
    final index = state.indexWhere((filter) => filter.property == newFilter.property);
    if (index != -1) {
      state[index] = newFilter; // Replace existing filter
    } else {
      state = [...state, newFilter]; // Add new filter
    }
  }

  QuickFilter? getFilter(String propertyName) {
    final index = state.indexWhere((filter) => filter.property == propertyName);
    if (index != -1) {
      return state[index];
    }
    return null;
  }

  // Remove a filter by property
  void removeFilter(String property) {
    state = state.where((filter) => filter.property != property).toList();
  }

  // Apply filters to a list of maps
  void applyListFilter(BuildContext context) {
    _screenController.setFeatureScreenData(context);
    List<Map<String, dynamic>> listValue = _screenDataNotifier.data as List<Map<String, dynamic>>;
    for (var filter in state) {
      String property = filter.property;
      QuickFilterType type = filter.type;
      dynamic value = filter.value;

      if (value == null || value.toString().trim().isEmpty) {
        continue;
      } else if (type == QuickFilterType.contains) {
        listValue = listValue.where((item) => (item[property] ?? '').contains(value)).toList();
      } else if (type == QuickFilterType.equals) {
        listValue = listValue.where((item) => item[property] == value).toList();
      } else if (type == QuickFilterType.lessThanOrEqual) {
        listValue = listValue.where((item) => item[property] <= value).toList();
      } else if (type == QuickFilterType.lessThan) {
        listValue = listValue.where((item) => item[property] < value).toList();
      } else if (type == QuickFilterType.moreThanOrEqual) {
        listValue = listValue.where((item) => item[property] >= value).toList();
      } else if (type == QuickFilterType.moreThan) {
        listValue = listValue.where((item) => item[property] > value).toList();
      } else if (type == QuickFilterType.dateAfter) {
        listValue = listValue
            .where((item) =>
                item[property].toDate().isAfter(value) ||
                item[property].toDate().isAtSameMomentAs(value))
            .toList();
      } else if (type == QuickFilterType.dateBefore) {
        listValue = listValue
            .where((item) =>
                item[property].toDate().isBefore(value) ||
                item[property].toDate().isAtSameMomentAs(value))
            .toList();
      } else if (type == QuickFilterType.dateSameDay) {
        listValue = listValue.where((item) => isSameDay(item[property].toDate(), value)).toList();
      } else {
        errorPrint('unknown filter criteria');
      }
    }
    _screenDataNotifier.set(listValue);
  }

  // Get the value of a specific filter
  String getFilterValue(String property) {
    final index = state.indexWhere((filter) => filter.property == property);
    if (index == -1) {
      return '';
    }
    QuickFilter filter = state[index];
    dynamic value = filter.value;
    if (value is int || value is double) {
      return value.toString();
    } else if (value is String) {
      return value;
    } else if (value is DateTime) {
      return formatDate(value);
    } else {
      errorPrint('unknown value type for filter name ${filter.property}');
      return value.toString();
    }
  }

  // Reset all filters
  void reset(BuildContext context) {
    state = [];
    _screenController.setFeatureScreenData(context);
  }
}
