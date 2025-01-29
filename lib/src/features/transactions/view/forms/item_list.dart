import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/classes/db_repository.dart';
import 'package:tablets/src/common/classes/item_form_data.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/providers/text_editing_controllers_provider.dart';
import 'package:tablets/src/common/values/constants.dart' as constants;
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/features_keys.dart';
import 'package:tablets/src/common/values/form_dimenssions.dart';
import 'package:tablets/src/common/widgets/dialog_delete_confirmation.dart';
import 'package:tablets/src/common/widgets/form_fields/drop_down_with_search.dart';
import 'package:tablets/src/common/widgets/form_fields/edit_box.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/deleted_transactions/controllers/deleted_transaction_screen_controller.dart';
import 'package:tablets/src/features/products/controllers/product_screen_controller.dart';
import 'package:tablets/src/features/products/repository/product_db_cache_provider.dart';
import 'package:tablets/src/features/products/repository/product_repository_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_navigator_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_utils_controller.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/view/transaction_form.dart';

const double codeColumnWidth = customerInvoiceFormWidth * 0.075;
const double sequenceColumnWidth = customerInvoiceFormWidth * 0.06;
const double nameColumnWidth = customerInvoiceFormWidth * 0.4;
const double priceColumnWidth = customerInvoiceFormWidth * 0.145;
const double soldQuantityColumnWidth = customerInvoiceFormWidth * 0.15;
const double stockColumnWidth = customerInvoiceFormWidth * 0.15;
const double giftQuantityColumnWidth = customerInvoiceFormWidth * 0.15;
const double soldTotalAmountColumnWidth = customerInvoiceFormWidth * 0.15;

class ItemsList extends ConsumerWidget {
  const ItemsList(this.hideGifts, this.hidePrice, this.transactionType, {super.key});

  final bool hideGifts;
  final bool hidePrice;
  final String transactionType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final productRepository = ref.read(productRepositoryProvider);
    final textEditingNotifier = ref.read(textFieldsControllerProvider.notifier);
    final productDbCache = ref.read(productDbCacheProvider.notifier);
    final productScreenController = ref.read(productScreenControllerProvider);
    return Container(
      height: 350,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black38, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildItemsTitles(context, formDataNotifier, textEditingNotifier, hideGifts, hidePrice),
            ..._buildDataRows(formDataNotifier, textEditingNotifier, productRepository, hideGifts,
                hidePrice, transactionType, productDbCache, productScreenController, context, ref),
          ],
        ),
      ),
    );
  }
}

num _calculateProductStock(BuildContext context, WidgetRef ref, String productDbRef) {
  final productDbCache = ref.read(productDbCacheProvider.notifier);
  final productData = productDbCache.getItemByDbRef(productDbRef);
  final productScreenController = ref.read(productScreenControllerProvider);
  final prodcutScreenData = productScreenController.getItemScreenData(context, productData);
  return prodcutScreenData[productQuantityKey];
}

List<Widget> _buildDataRows(
  ItemFormData formDataNotifier,
  TextControllerNotifier textEditingNotifier,
  DbRepository productRepository,
  bool hideGifts,
  bool hidePrice,
  String transactionType,
  DbCache productDbCache,
  ProductScreenController productScreenController,
  BuildContext context,
  WidgetRef ref,
) {
  final formNavigator = ref.read(formNavigatorProvider);
  if (!formDataNotifier.data.containsKey(itemsKey) || formDataNotifier.data[itemsKey] is! List) {
    return const [];
  }
  final items = formDataNotifier.data[itemsKey] as List<Map<String, dynamic>>;
  return List.generate(items.length, (index) {
    if (!textEditingNotifier.data.containsKey(itemsKey) ||
        textEditingNotifier.data[itemsKey]!.length <= index) {
      errorPrint('Warning: Missing TextEditingController for item index: $index');
      return const SizedBox.shrink(); // Return an empty widget if the controller is missing
    }
    return Container(
      color: (index + 1) % 2 == 0 ? Colors.grey[300] : null,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CodeFormInputField(
                index, codeColumnWidth, itemsKey, itemCodeKey, transactionType, items.length,
                isReadOnly: formNavigator.isReadOnly,
                isDisabled: formNavigator.isReadOnly,
                isFirst: true),
            _buildDropDownWithSearch(ref, formDataNotifier, textEditingNotifier, index,
                nameColumnWidth, productDbCache, productScreenController, context, items.length,
                isReadOnly: formNavigator.isReadOnly),
            TransactionFormInputField(
                index, soldQuantityColumnWidth, itemsKey, itemSoldQuantityKey, transactionType,
                isReadOnly: formNavigator.isReadOnly, isDisabled: formNavigator.isReadOnly),
            if (!hideGifts)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red, // Set the border color to red
                    width: 0.5, // Set the border width
                  ),
                  borderRadius: BorderRadius.circular(3.0), // Optional: Set border radius
                ),
                child: TransactionFormInputField(
                    index, giftQuantityColumnWidth, itemsKey, itemGiftQuantityKey, transactionType,
                    isReadOnly: formNavigator.isReadOnly, isDisabled: formNavigator.isReadOnly),
              ),
            if (!hidePrice)
              TransactionFormInputField(
                  index, priceColumnWidth, itemsKey, itemSellingPriceKey, transactionType,
                  isReadOnly: formNavigator.isReadOnly, isDisabled: formNavigator.isReadOnly),
            if (!hidePrice)
              TransactionFormInputField(
                  index, soldTotalAmountColumnWidth, itemsKey, itemTotalAmountKey, transactionType,
                  // textEditingNotifier: textEditingNotifier,
                  isLast: false,
                  isReadOnly: true,
                  isDisabled: formNavigator.isReadOnly),
            buildDataCell(
              stockColumnWidth,
              // if we are loading item, then we calculate its current stock
              // note that this is only activated when we are loading previous form, because if we have new form and select
              // product, then its calculated in the on change function inside the drop down selection
              Text(
                doubleToIntString(
                    formDataNotifier.getSubProperty(itemsKey, index, itemStockQuantityKey) ??
                        _calculateProductStock(context, ref, items[index]['dbRef'])),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: formNavigator.isReadOnly ? Colors.grey : null),
              ),
            ),
            // don't add delete button to last row because it will be always empty
            index < items.length - 1 && !formNavigator.isReadOnly
                ? _buildDeleteItemButton(
                    context,
                    ref,
                    formDataNotifier,
                    textEditingNotifier,
                    index,
                    sequenceColumnWidth,
                    transactionType,
                  )
                : buildDataCell(sequenceColumnWidth, const Text(''), isLast: true),
          ]),
    );
  });
}

void addNewRow(ItemFormData formDataNotifier, TextControllerNotifier textEditingNotifier) {
  formDataNotifier.updateSubProperties(itemsKey, {
    itemCodeKey: null,
    itemNameKey: '',
    itemSellingPriceKey: 0,
    itemWeightKey: 0,
    itemSoldQuantityKey: 0,
    itemGiftQuantityKey: 0,
    itemTotalAmountKey: 0,
    itemTotalWeightKey: 0,
    itemStockQuantityKey: 0,
    itemTotalProfitKey: 0,
    itemSalesmanTotalCommissionKey: 0,
  });
  textEditingNotifier.updateSubControllers(itemsKey, {
    itemCodeKey: null,
    itemSellingPriceKey: 0,
    itemSoldQuantityKey: 0,
    itemGiftQuantityKey: 0,
    itemTotalAmountKey: 0,
    itemTotalWeightKey: 0
  });
}

// note that we don't allow deleting last row, the delete button is not activated for it
// so, we don't need to check if the row is last row
Widget _buildDeleteItemButton(
  BuildContext context,
  WidgetRef ref,
  ItemFormData formDataNotifier,
  TextControllerNotifier textEditingNotifier,
  int index,
  double width,
  String transactionType,
) {
  return buildDataCell(
      width,
      IconButton(
        onPressed: () async {
          // show confirmation dialog before deleting
          final confirmation = await showDeleteConfirmationDialog(
              context: context,
              messagePart1: S.of(context).alert_before_delete,
              messagePart2: formDataNotifier.data[itemsKey][index][itemNameKey]);
          if (confirmation == null) return;

          final items = formDataNotifier.getProperty(itemsKey) as List<Map<String, dynamic>>;
          final deletedItem = {...items[index]};
          formDataNotifier.removeSubProperties(itemsKey, index);
          // update all transaction totals due to item removal

          final subTotalAmount = _getTotal(formDataNotifier, itemsKey, itemTotalAmountKey);
          final discount = formDataNotifier.getProperty(discountKey);
          // for gifts we don't charget customer
          final totalAmount =
              transactionType == TransactionType.gifts.name ? 0 : subTotalAmount - discount;
          final totalWeight = _getTotal(formDataNotifier, itemsKey, itemTotalWeightKey);
          double totalSalesmanCommission =
              formDataNotifier.getProperty(salesmanTransactionComssionKey);
          final itemSalesmanCommission = deletedItem[itemSalesmanTotalCommissionKey];
          totalSalesmanCommission -= itemSalesmanCommission;
          double itemsTotalProfit = formDataNotifier.getProperty(itemsTotalProfitKey);
          final itemProfit = deletedItem[itemTotalProfitKey];
          itemsTotalProfit -= itemProfit;
          final transactionTotalProfit = itemsTotalProfit - discount;
          formDataNotifier.updateProperties({
            subTotalAmountKey: subTotalAmount,
            totalAmountKey: totalAmount,
            totalWeightKey: totalWeight,
            salesmanTransactionComssionKey: totalSalesmanCommission,
            itemsTotalProfitKey: itemsTotalProfit,
            transactionTotalProfitKey: transactionTotalProfit,
          });
          final formImagesNotifier = ref.read(imagePickerProvider.notifier);
          final formNavigation = ref.read(formNavigatorProvider);
          // I am loading same transaction, but with one row removed
          if (context.mounted) {
            TransactionForm.onNavigationPressed(
                formDataNotifier, context, ref, formImagesNotifier, formNavigation,
                targetTransactionData: formDataNotifier.data);
          }
        },
        icon: const Icon(Icons.remove, color: Colors.red),
      ),
      isLast: true);
}

Widget _buildItemsTitles(BuildContext context, ItemFormData formDataNotifier,
    TextControllerNotifier textEditingNotifier, bool hideGifts, bool hidePrice) {
  final titles = [
    // _buildAddItemButton(formDataNotifier, textEditingNotifier), // not needed, row auto added
    Text(S.of(context).code, style: const TextStyle(color: Colors.white, fontSize: 14)),
    Text(S.of(context).item_name, style: const TextStyle(color: Colors.white, fontSize: 14)),
    Text(S.of(context).item_sold_quantity,
        style: const TextStyle(color: Colors.white, fontSize: 14)),
    if (!hideGifts)
      Text(S.of(context).item_gifts_quantity,
          style: const TextStyle(color: Colors.white, fontSize: 14)),
    if (!hidePrice)
      Text(S.of(context).item_price, style: const TextStyle(color: Colors.white, fontSize: 14)),
    if (!hidePrice)
      Text(S.of(context).item_total_price,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    Text(S.of(context).stock, style: const TextStyle(color: Colors.white, fontSize: 16)),
    const SizedBox(),
  ];

  final widths = [
    codeColumnWidth,
    nameColumnWidth,
    soldQuantityColumnWidth,
    if (!hideGifts) giftQuantityColumnWidth,
    if (!hidePrice) priceColumnWidth,
    if (!hidePrice) soldTotalAmountColumnWidth,
    soldQuantityColumnWidth,
    sequenceColumnWidth,
  ];

  return Container(
    color: Colors.blueGrey,
    child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...List.generate(titles.length, (index) {
            return buildDataCell(
              widths[index],
              titles[index],
              isTitle: true,
              isFirst: index == 0,
              isLast: index == titles.length - 1,
            );
          })
        ]),
  );
}

dynamic _getTotal(ItemFormData formDataNotifier, String property, String subProperty) {
  dynamic total = 0;
  if (!formDataNotifier.isValidProperty(property) ||
      formDataNotifier.getProperty(property) is! List<Map<String, dynamic>>) {
    errorPrint('form property provided is invalid');
    return total;
  }
  final items = formDataNotifier.getProperty(property);
  for (var i = 0; i < items.length; i++) {
    if (!items[i].containsKey(subProperty)) {
      errorPrint('formData[$property][$i][$subProperty] is invalid');
      continue;
    }
    final value = items[i][subProperty];
    if (value is! double && value is! int) {
      errorPrint('$subProperty[$subProperty] is not a nummber');
      continue;
    }
    total += value;
  }
  return total;
}

Widget _buildDropDownWithSearch(
    WidgetRef ref,
    ItemFormData formDataNotifier,
    TextControllerNotifier textEditingNotifier,
    int index,
    double width,
    DbCache productDbCache,
    ProductScreenController productScreenController,
    BuildContext context,
    int numRows,
    {bool isReadOnly = false}) {
  return buildDataCell(
    width,
    DropDownWithSearchFormField(
      isReadOnly: isReadOnly,
      initialValue: formDataNotifier.getSubProperty(itemsKey, index, itemNameKey),
      hideBorders: true,
      dbCache: productDbCache,
      isRequired: false,
      onChangedFn: (item) {
        // notify if previous item entered has zero quantity
        final items = formDataNotifier.getProperty(itemsKey);
        if (index > 1 && items[index - 1][itemSoldQuantityKey] == 0) {
          failureUserMessage(context, S.of(context).previous_item_quantity_is_zero);
        }
        // calculate the quantity of the product
        final productQuantity = _calculateProductStock(context, ref, item['dbRef']);
        if (productQuantity < 1) {
          failureUserMessage(context, S.of(context).product_out_of_stock);
        }
        // updates related fields using the item selected (of type Map<String, dynamic>)
        // and triger the on changed function in price field using its controller
        final subProperties = {
          itemCodeKey: item['code'],
          itemNameKey: item['name'],
          itemDbRefKey: item['dbRef'],
          itemSellingPriceKey: _getItemPrice(context, formDataNotifier, item),
          itemWeightKey: item['packageWeight'],
          itemBuyingPriceKey: getBuyingPrice(ref, productQuantity, item['dbRef']),
          itemSalesmanCommissionKey: item['salesmanCommission'],
          itemStockQuantityKey: productQuantity,
        };
        formDataNotifier.updateSubProperties(itemsKey, subProperties, index: index);
        final price = formDataNotifier.getSubProperty(itemsKey, index, itemSellingPriceKey);
        textEditingNotifier.updateSubControllers(
            itemsKey, {itemSellingPriceKey: price, itemCodeKey: item['code']},
            index: index);
        // add new empty row if current row is last one, (always keep one empty row)
        if (index == numRows - 1) {
          addNewRow(formDataNotifier, textEditingNotifier);
        }
      },
    ),
  );
}

class TransactionFormInputField extends ConsumerWidget {
  const TransactionFormInputField(
      this.index, this.width, this.property, this.subProperty, this.transactionType,
      {this.isLast = false,
      this.isReadOnly = false,
      this.isFirst = false,
      this.isDisabled = false,
      super.key});

  final int index;
  final double width;
  final String property;
  final String subProperty;
  final String transactionType;
  final bool isLast;
  final bool isFirst;
  final bool isReadOnly;
  final bool isDisabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final textEditingNotifier = ref.read(textFieldsControllerProvider.notifier);
    final transactionUtils = ref.read(transactionUtilsControllerProvider);
    return buildDataCell(
      width,
      FormInputField(
        initialValue: formDataNotifier.getSubProperty(property, index, subProperty),
        controller: textEditingNotifier.getSubController(property, index, subProperty),
        hideBorders: true,
        isRequired: false,
        isDisabled: isDisabled,
        isReadOnly: isReadOnly,
        dataType: constants.FieldDataType.num,
        name: subProperty,
        onChangedFn: (value) {
          // this method is executed throught two ways, first when the field is updated by the user
          // and the second is automatic when user selects and item through adjacent product selection dropdown
          formDataNotifier.updateSubProperties(property, {subProperty: value}, index: index);
          final sellingPrice =
              formDataNotifier.getSubProperty(property, index, itemSellingPriceKey);
          final weight = formDataNotifier.getSubProperty(property, index, itemWeightKey);
          final soldQuantity =
              formDataNotifier.getSubProperty(property, index, itemSoldQuantityKey);
          if (soldQuantity == null || sellingPrice == null) {
            return;
          }
          final updatedSubProperties = {
            itemTotalAmountKey: soldQuantity * sellingPrice,
            itemTotalWeightKey: soldQuantity * weight
          };
          formDataNotifier.updateSubProperties(property, updatedSubProperties, index: index);
          textEditingNotifier.updateSubControllers(property, updatedSubProperties, index: index);
          final subTotalAmount = _getTotal(formDataNotifier, property, itemTotalAmountKey);
          formDataNotifier.updateProperties({subTotalAmountKey: subTotalAmount});
          final itemsTotalWeight = _getTotal(formDataNotifier, property, itemTotalWeightKey);
          final discount = formDataNotifier.getProperty(discountKey);
          // for gifts we don't charget customer
          final totalAmount =
              transactionType == TransactionType.gifts.name ? 0 : subTotalAmount - discount;
          final updatedProperties = {totalAmountKey: totalAmount, totalWeightKey: itemsTotalWeight};
          formDataNotifier.updateProperties(updatedProperties);
          textEditingNotifier.updateControllers(updatedProperties);
          // calculate total profit & salesman commision on item
          final giftQuantity =
              formDataNotifier.getSubProperty(property, index, itemGiftQuantityKey);
          if (giftQuantity == null) return;
          final buyingPrice = formDataNotifier.getSubProperty(property, index, itemBuyingPriceKey);
          final salesmanCommission =
              formDataNotifier.getSubProperty(property, index, itemSalesmanCommissionKey);
          final salesmanTotalCommission = salesmanCommission * soldQuantity;
          final itemTotalProfit =
              ((sellingPrice - buyingPrice) * soldQuantity) - (giftQuantity * buyingPrice);

          formDataNotifier.updateSubProperties(
              property,
              {
                itemSalesmanTotalCommissionKey: salesmanTotalCommission,
                itemTotalProfitKey: itemTotalProfit
              },
              index: index);
          final itemsTotalProfit = _getTotal(formDataNotifier, property, itemTotalProfitKey);
          final salesmanTransactionComssion =
              _getTotal(formDataNotifier, property, itemSalesmanTotalCommissionKey);
          double transactionTotalProfit = transactionUtils.getTransactionProfit(formDataNotifier,
              transactionType, itemsTotalProfit, discount, salesmanTransactionComssion);
          formDataNotifier.updateProperties(
            {
              itemsTotalProfitKey: itemsTotalProfit,
              transactionTotalProfitKey: transactionTotalProfit,
              salesmanTransactionComssionKey: salesmanTransactionComssion
            },
          );
        },
      ),
      isLast: isLast,
      isFirst: isFirst,
    );
  }
}

class CodeFormInputField extends ConsumerWidget {
  const CodeFormInputField(
      this.index, this.width, this.property, this.subProperty, this.transactionType, this.numRows,
      {this.isLast = false,
      this.isReadOnly = false,
      this.isFirst = false,
      this.isDisabled = false,
      super.key});

  final int index;
  final double width;
  final String property;
  final String subProperty;
  final String transactionType;
  final int numRows;
  final bool isLast;
  final bool isFirst;
  final bool isReadOnly;
  final bool isDisabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final textEditingNotifier = ref.read(textFieldsControllerProvider.notifier);
    final productDbCache = ref.read(productDbCacheProvider.notifier);
    final productScreenController = ref.read(productScreenControllerProvider);
    return buildDataCell(
      width,
      FormInputField(
          initialValue: formDataNotifier.getSubProperty(property, index, subProperty),
          controller: textEditingNotifier.getSubController(property, index, subProperty),
          hideBorders: true,
          isRequired: false,
          isDisabled: isDisabled,
          isReadOnly: isReadOnly,
          dataType: constants.FieldDataType.num,
          name: subProperty,
          isOnSubmit: true,
          onChangedFn: (value) {
            // calculate the quantity of the product
            final productData = productDbCache.getItemByProperty('code', value);
            final prodcutScreenData =
                productScreenController.getItemScreenData(context, productData);
            final productQuantity = prodcutScreenData[productQuantityKey];
            // updates related fields using the item selected (of type Map<String, dynamic>)
            // and triger the on changed function in price field using its controller
            final subProperties = {
              itemCodeKey: productData['code'],
              itemNameKey: productData['name'],
              itemDbRefKey: productData['dbRef'],
              itemSellingPriceKey: _getItemPrice(context, formDataNotifier, productData),
              itemWeightKey: productData['packageWeight'],
              itemBuyingPriceKey: getBuyingPrice(ref, productQuantity, productData['dbRef']),
              itemSalesmanCommissionKey: productData['salesmanCommission'],
              itemStockQuantityKey: productQuantity,
            };
            formDataNotifier.updateSubProperties(itemsKey, subProperties, index: index);
            final price = formDataNotifier.getSubProperty(itemsKey, index, itemSellingPriceKey);
            textEditingNotifier.updateSubControllers(
                itemsKey, {itemSellingPriceKey: price, itemCodeKey: productData['code']},
                index: index);
            // add new empty row if current row is last one, (always keep one empty row)
            if (index == numRows - 1) {
              addNewRow(formDataNotifier, textEditingNotifier);
            }
          }),
      isLast: isLast,
      isFirst: isFirst,
    );
  }
}

Widget buildDataCell(double width, Widget cell,
    {height = 45, isTitle = false, isFirst = false, isLast = false}) {
  return Container(
      decoration: BoxDecoration(
        border: Border(
          left: !isLast ? const BorderSide(color: Colors.black12, width: 1.0) : BorderSide.none,
          right: !isFirst ? const BorderSide(color: Colors.black12, width: 1.0) : BorderSide.none,
          bottom: const BorderSide(color: Colors.black12, width: 0.5),
        ),
      ),
      width: width,
      height: height is double ? height : height.toDouble(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          cell,
        ],
      ));
}

// item price is not the same for all customers, it depends on selling type to the customer,
// if customer is not selected yet then default is salewhole type
double _getItemPrice(
    BuildContext context, ItemFormData formDataNotifier, Map<String, dynamic> item) {
  final transactionType = formDataNotifier.getProperty(transTypeKey);
  if (transactionType == TransactionType.expenditures.name ||
      transactionType == TransactionType.customerReceipt.name ||
      transactionType == TransactionType.vendorReceipt.name) {
    errorPrint('Wrong form type');
    return 0;
  }
  // for vendor we use buying price
  if (transactionType == TransactionType.vendorInvoice.name ||
      transactionType == TransactionType.vendorReturn.name) {
    return item['buyingPrice'];
  }

  String? customerSellType = formDataNotifier.getProperty(sellingPriceTypeKey);
  if (customerSellType == null) return item['sellRetailPrice'];
  customerSellType = translateScreenTextToDbText(context, customerSellType);
  final price = customerSellType == SellPriceType.retail.name
      ? item['sellRetailPrice']
      : item['sellWholePrice'];
  return price;
}

// the idea is to create a stack for vendor invoices where top invoice is the newest, and compare the remaining
// amount with top invoice if the quanity is bigger, then pop the invoice from the stack and reduce its amount
// from the quanitity, and repeat until quanitity is <= zero. in that way we get the proper buying price for the item
// we return the default price if there is no price detected in customer invoice (which is the price in product form)
double getBuyingPrice(WidgetRef ref, num currentQuantity, String productDbRef) {
  final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
  final transactions = transactionDbCache.data;
  List<Map<String, dynamic>> boughtItems = [];
  for (var trans in transactions) {
    if (trans[transactionTypeKey] == TransactionType.vendorInvoice.name && trans['items'] is List) {
      for (var item in trans['items']) {
        if (item['dbRef'] == productDbRef) {
          boughtItems.add(item);
        }
      }
    }
  }
  sortMapsByProperty(boughtItems, 'date');
  for (var item in boughtItems) {
    if (item[itemSoldQuantityKey] > currentQuantity) {
      return item[itemSellingPriceKey];
    }
    currentQuantity = item[itemSoldQuantityKey];
  }
  // if no item transaction found, return the default price (or initial quanity price)
  final productDbCache = ref.read(productDbCacheProvider.notifier);
  final productData = productDbCache.getItemByProperty('dbRef', productDbRef);
  return productData['buyingPrice'];
}
