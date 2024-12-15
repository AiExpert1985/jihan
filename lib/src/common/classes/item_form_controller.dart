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

  void saveItemToDb(BuildContext context, BaseItem item, bool isEditMode,
      {bool keepDialogOpen = false}) async {
    isEditMode ? _repository.updateItem(item) : _repository.addItem(item);
    if (!keepDialogOpen) {
      _closeForm(context);
    }
  }

  void deleteItemFromDb(BuildContext context, BaseItem item, {bool keepDialogOpen = false}) async {
    _repository.deleteItem(item);
    if (!keepDialogOpen) {
      _closeForm(context);
    }
  }

  void _closeForm(BuildContext context) {
    Navigator.of(context).pop();
  }
}
