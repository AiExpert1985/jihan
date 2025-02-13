import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/functions/utils.dart' as utils;
import 'package:tablets/src/common/functions/form_validation.dart' as validation;
import 'package:tablets/src/features/transactions/view/forms/item_list.dart';

class ProductsDropDown extends ConsumerWidget {
  const ProductsDropDown(
      {required this.onChangedFn,
      this.label,
      this.isRequired = true,
      this.hideBorders = false,
      required this.dbCache,
      this.initialValue,
      this.isReadOnly = false,
      super.key});

  final DbCache dbCache; // used to bring items (from database) shown in the list
  final String? initialValue; // must contains 'name' property
  final String? label; // label shown on the cell
  final bool hideBorders; // hide borders in decoration, used if the field in sub list
  final bool isRequired; // if isRequired = false, then the field will not be validated
  final bool isReadOnly;
  final void Function(Map<String, dynamic>) onChangedFn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: DropdownSearch<Map<String, dynamic>>(
        mode: Mode.form,
        enabled: !isReadOnly,
        decoratorProps: DropDownDecoratorProps(
          baseStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
          decoration: utils.formFieldDecoration(label: label, hideBorders: hideBorders),
        ),
        selectedItem: initialValue != null ? {'name': initialValue} : null,
        items: (filter, t) => dbCache.getSearchableList(filterKey: 'name', filterValue: filter),
        compareFn: (i, s) => i == s,
        popupProps: PopupProps.dialog(
          title: label != null
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    label!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
          dialogProps: DialogProps(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          fit: FlexFit.tight,
          showSearchBox: true,
          itemBuilder: (context, item, isDisabled, isSelected) {
            final itemStock = calculateProductStock(context, ref, item['dbRef']);
            String stringIemStock = utils.doubleToStringWithComma(itemStock);
            return popUpItem(context, item, isDisabled, isSelected, stringIemStock);
          },
          searchFieldProps: TextFieldProps(
            autofocus: true,
            textAlign: TextAlign.center,
            decoration: utils.formFieldDecoration(),
          ),
        ),
        validator: (item) => isRequired
            ? validation.validateTextField(
                item?['name'], S.of(context).input_validation_error_message_for_text)
            : null,
        itemAsString: (item) {
          return item['name'];
        },
        onChanged: (item) {
          if (item == null) return;
          onChangedFn(item);
        },
      ),
    );
  }
}

Widget popUpItem(BuildContext context, Map<String, dynamic> item, bool isDisabled, bool isSelected,
    String displayValue) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 8),
    decoration: !isSelected
        ? null
        : BoxDecoration(
            border: Border.all(color: Theme.of(context).primaryColor),
            borderRadius: BorderRadius.circular(5),
            color: Colors.white,
          ),
    child: Container(
      decoration: BoxDecoration(
          color: displayValue == '0' ? const Color.fromARGB(255, 252, 193, 189) : null,
          border: Border.all(width: 1, color: Colors.white)),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      child: ListTile(
        selected: isSelected,
        title: Row(
          children: [Text(item['name']), const Spacer(), Text(displayValue)],
        ), // Display name and the passed value
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          foregroundImage:
              CachedNetworkImageProvider(item['imageUrls'][item['imageUrls'].length - 1]),
        ),
      ),
    ),
  );
}
