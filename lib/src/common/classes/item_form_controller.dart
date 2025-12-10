import 'package:flutter/material.dart';
import 'package:tablets/src/common/classes/db_repository.dart';
import 'package:tablets/src/common/interfaces/base_item.dart';

class ItemFormController {
  ItemFormController(
    this._repository,
  );
  final DbRepository _repository;
  // final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // bool validateData() => formKey.currentState!.validate();

  // void submitData() => formKey.currentState!.save();

  /// Saves item to database and returns true if successful, false if failed
  Future<bool> saveItemToDb(BuildContext context, BaseItem item, bool isEditMode,
      {bool keepDialogOpen = false}) async {
    final success = isEditMode
        ? await _repository.updateItem(item)
        : await _repository.addItem(item);
    if (!keepDialogOpen && context.mounted) {
      _closeForm(context);
    }
    return success;
  }

  /// Deletes item from database and returns true if successful, false if failed
  Future<bool> deleteItemFromDb(BuildContext context, BaseItem item,
      {bool keepDialogOpen = false}) async {
    final success = await _repository.deleteItem(item);
    if (!keepDialogOpen && context.mounted) {
      _closeForm(context);
    }
    return success;
  }

  void _closeForm(BuildContext context) {
    Navigator.of(context).pop();
  }
}
