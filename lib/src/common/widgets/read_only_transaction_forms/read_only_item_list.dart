import 'package:flutter/material.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/values/form_dimenssions.dart';
import 'package:tablets/src/common/values/transactions_common_values.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';

const double sequenceColumnWidth = customerInvoiceFormWidth * 0.055;
const double nameColumnWidth = customerInvoiceFormWidth * 0.345;
const double priceColumnWidth = customerInvoiceFormWidth * 0.16;
const double soldQuantityColumnWidth = customerInvoiceFormWidth * 0.1;
const double giftQuantityColumnWidth = customerInvoiceFormWidth * 0.1;
const double soldTotalAmountColumnWidth = customerInvoiceFormWidth * 0.17;

Widget buildReadOnlyItemList(
    BuildContext context, Transaction transaction, bool hideGifts, bool hidePrice) {
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
          _buildColumnTitles(context, hideGifts, hidePrice),
          ..._buildDataRows(transaction, hideGifts, hidePrice),
        ],
      ),
    ),
  );
}

List<Widget> _buildDataRows(Transaction transaction, bool hideGifts, bool hidePrice) {
  final items = transaction.items;
  if (items == null || items.isEmpty) return const [];
  return List.generate(items.length, (index) {
    final item = items[index];
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildDataCell(nameColumnWidth, Text(item[itemNameKey]), isFirst: true),
          if (!hidePrice) buildDataCell(priceColumnWidth, Text('${item[itemSellingPriceKey]}')),
          buildDataCell(soldQuantityColumnWidth, Text('${item[itemSoldQuantityKey]}')),
          if (!hideGifts)
            buildDataCell(giftQuantityColumnWidth, Text('${item[itemGiftQuantityKey]}')),
          if (!hidePrice)
            buildDataCell(soldTotalAmountColumnWidth, Text('${item[itemTotalAmountKey]}'),
                isLast: true),
        ]);
  });
}

Widget _buildColumnTitles(BuildContext context, bool hideGifts, bool hidePrice) {
  final titles = [
    Text(S.of(context).item_name),
    if (!hidePrice) Text(S.of(context).item_price),
    Text(S.of(context).item_sold_quantity),
    if (!hideGifts) Text(S.of(context).item_gifts_quantity),
    if (!hidePrice) Text(S.of(context).item_total_price),
  ];

  final widths = [
    nameColumnWidth,
    if (!hidePrice) priceColumnWidth,
    soldQuantityColumnWidth,
    if (!hideGifts) giftQuantityColumnWidth,
    if (!hidePrice) soldTotalAmountColumnWidth,
  ];

  return Container(
    color: const Color.fromARGB(255, 227, 240, 247),
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

Widget buildDataCell(
  double width,
  dynamic cell, {
  double height = 45,
  bool isTitle = false,
  bool isFirst = false,
  bool isLast = false,
}) {
  return Container(
      decoration: BoxDecoration(
        border: Border(
            left: !isLast
                ? const BorderSide(color: Color.fromARGB(31, 133, 132, 132), width: 1.0)
                : BorderSide.none,
            right: !isFirst
                ? const BorderSide(color: Color.fromARGB(31, 133, 132, 132), width: 1.0)
                : BorderSide.none,
            bottom: const BorderSide(color: Color.fromARGB(31, 133, 132, 132), width: 1.0)),
      ),
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          cell,
        ],
      ));
}
