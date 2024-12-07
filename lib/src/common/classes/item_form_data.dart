import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/utils.dart';

class ItemFormData extends StateNotifier<Map<String, dynamic>> {
  ItemFormData(super.state);

  void initialize({Map<String, dynamic>? initialData}) {
    state = initialData ?? {'dbRef': generateRandomString(len: 8)};
  }

  void updateProperties(Map<String, dynamic> properties) {
    state = {...state, ...properties};
  }

  /// if no index is passed, subProperties will be appended to the list
  /// if an index is provided, the data will be updated at the given index
  void updateSubProperties(String property, Map<String, dynamic> subProperties, {int? index}) {
    final newState = {...state};
    // I did below map creation to solve issue I faced with LinkedMap<String, dynamic>
    //or Map<dynamic, dynamic> types
    // I wanted to ensure I always have Map<String, dynamic> type
    Map<String, dynamic> typeAdjustedSubProperties = {};
    subProperties.forEach((key, value) {
      typeAdjustedSubProperties[key] = value;
    });
    if (!newState.containsKey(property)) {
      newState[property] = [typeAdjustedSubProperties];
      state = {...newState};
      return;
    }
    final list = newState[property];
    if (list is! List<Map<String, dynamic>>) {
      errorPrint('Property "$property" is not of type List');
      return;
    }
    if (index == null) {
      list.add(typeAdjustedSubProperties);
      newState[property] = list;
      state = {...newState};
      return;
    }
    if (index >= 0 && index < list.length) {
      subProperties.forEach((key, value) {
        list[index][key] = value;
      });
      newState[property] = list;
      state = {...newState};
      return;
    }
    errorPrint('subproperty $subProperties were not added to property "$property" at index $index');
  }

  /// checks whether state contains the mentioned property
  bool isValidProperty(String property) {
    if (!state.containsKey(property)) {
      errorPrint('Invalid formData: state[$property] does not exist');
      return false;
    }
    return true;
  }

  /// checks whether state contains the mentioned subProperty
  bool isValidSubProperty(String property, int index, String subProperty) {
    if (!state.containsKey(property)) {
      errorPrint('Invalid formData: state[$property] does not exist');
      return false;
    }
    if (state[property] is! List<Map<String, dynamic>>) {
      errorPrint('Invalid formData: state[$property] is not a List');
      return false;
    }
    if (index < 0 || index >= state[property].length) {
      errorPrint('Invalid formData: state[$property][$index] is invalid');
      return false;
    }
    return true;
  }

  // usually this is used for initialValue for form fields, which takes either a value or null
  dynamic getProperty(String property) {
    if (!state.containsKey(property)) return;
    return state[property];
  }

  // usually this is used for initialValue for form fields, which takes either a value or null
  dynamic getSubProperty(String property, int index, String subProperty) {
    if (!isValidSubProperty(property, index, subProperty)) return;
    return state[property][index][subProperty];
  }

  void removeSubProperties(String property, int index) {
    if (!isValidProperty(property)) return;
    if (state[property] is! List<Map<String, dynamic>>) {
      errorPrint('Invalid formData state[$property] is not a list');
      return;
    }
    if (index < 0 || index >= state[property].length) {
      errorPrint('Invalid formData state[$property][$index] is invalid');
      return;
    }
    Map<String, dynamic> newState = Map.from(state);
    newState[property].removeAt(index);
    state = {...newState};
  }

  /// using notifier to get current state, used to get state instead of using the provider
  /// I used this way because I faced some issues when using the provider to get the updated state
  Map<String, dynamic> get data => state;

// used for debuggin purpose
  String getFormDataTypes() {
    final StringBuffer dataTypesBuffer = StringBuffer('{');
    state.forEach((key, value) {
      if (value is! List<Map<String, dynamic>>) {
        dataTypesBuffer.write("'$key': ${value.runtimeType}, ");
      } else {
        dataTypesBuffer.write('$key: [');
        dataTypesBuffer.write(value.map((item) {
          return '{${item.entries.map((entry) {
            return "'${entry.key}': ${entry.value.runtimeType}";
          }).join(', ')}}';
        }).join(', '));
        dataTypesBuffer.write('], ');
      }
    });

    dataTypesBuffer.write('}');
    return dataTypesBuffer.toString();
  }

  void reset() {
    state = {};
  }
}
