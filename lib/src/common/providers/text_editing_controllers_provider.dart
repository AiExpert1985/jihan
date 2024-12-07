import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/utils.dart';

class TextControllerNotifier extends StateNotifier<Map<String, dynamic>> {
  TextControllerNotifier() : super({});

  void updateControllers(Map<String, dynamic> properties) {
    final newState = {...state};
    properties.forEach((key, value) {
      String? text = value is! String ? doubleToIntString(value) : value;
      if (newState[key] != null) {
        newState[key].text = text;
      } else {
        newState[key] = TextEditingController(text: text);
      }
    });
    state = {...newState};
  }

  // TODO not working properly needs testing
  /// remove a complete row of subControllers
  void removeSubControllers(String property, int index) {
    Map<String, dynamic> newState = Map.from(state);
    if (!isValidController(property) || newState[property] is! List) return;
    newState[property][index].forEach((subProperty, controller) {
      if (!isValidSubController(property, index, subProperty)) return;
      removeSubController(property, index, subProperty);
    });
    // finally, remove the map
    newState[property].removeAt(index);
    state = {...newState};
  }

  void removeSubController(String property, int index, String subProperty) {
    if (!isValidSubController(property, index, subProperty)) return;
    final list = state[property];
    TextEditingController controller = list[index][subProperty]!;
    list.removeAt(index);
    controller.dispose();
    state = {
      ...state,
      property: list,
    };
  }

  dynamic getSubController(String property, int index, String subProperty) {
    if (!isValidSubController(property, index, subProperty)) return;
    return state[property][index][subProperty];
  }

  dynamic getController(String property) {
    if (!isValidController(property)) return;
    return state[property];
  }

  bool isValidController(String property) {
    if (!state.containsKey(property)) {
      errorPrint('Invalid controller: state[$property] does not exist');
      return false;
    }
    return true;
  }

  bool isValidSubController(String property, int index, String subProperty) {
    if (!state.containsKey(property)) {
      errorPrint('Invalid subController: state[$property] does not exist');
      return false;
    }
    if (state[property] is! List) {
      errorPrint('Invalid subController: state[$property] is not a List');
      return false;
    }
    if (index < 0 || index >= state[property].length) {
      errorPrint('Invalid subController: state[$property][$index] is invalid');
      return false;
    }
    if (state[property][index][subProperty] is! TextEditingController) {
      errorPrint(
          'Invalid subController: state[$property][$index][$subProperty] is not a TextEditingController');
      return false;
    }
    return true;
  }

  // if no index is provided, Map of controllers will created or appended to the end of the list
  void updateSubControllers(String property, Map<String, dynamic> subProperties, {int? index}) {
    final newState = {...state};
    Map<String, TextEditingController> subControllers = {};
    subProperties.forEach((key, value) {
      String? text = value is! String ? value?.toString() : value;
      subControllers[key] = TextEditingController(text: text);
    });
    if (!newState.containsKey(property)) {
      newState[property] = [subControllers];
      state = {...newState};
      return;
    }
    final list = newState[property];
    if (list is! List) {
      errorPrint('Property "$property" is not of type List');
      return;
    }
    if (index == null) {
      list.add(subControllers);
      newState[property] = list;
      state = {...newState};
      return;
    }
    if (index >= 0 && index < list.length) {
      subProperties.forEach((key, value) {
        String? text = value is! String ? doubleToIntString(value) : value;
        list[index][key].text = text;
      });
      newState[property] = list;
      state = {...newState};
      return;
    }
    errorPrint('subproperty $subProperties were not added to property "$property" at index $index');
  }

  // this method is very important, and should be called when every you finish
  // your work with TextEditingControllers otherwise they will keep their values
  // and that causes bugs in the code
  void disposeControllers() {
    state.forEach((property, value) {
      if (value is TextEditingController) {
        value.dispose();
      } else if (value is List<Map<String, TextEditingController>>) {
        for (var item in value) {
          item.forEach((subProperty, controller) => controller.dispose());
        }
      }
    });
    state = {};
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  Map<String, dynamic> get data => state;
}

final textFieldsControllerProvider =
    StateNotifierProvider<TextControllerNotifier, Map<String, dynamic>>((ref) {
  return TextControllerNotifier();
});
