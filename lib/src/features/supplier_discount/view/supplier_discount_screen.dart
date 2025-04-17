import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/widgets/empty_screen.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tablets/src/common/widgets/main_screen_list_cells.dart';
import 'package:tablets/src/features/supplier_discount/controllers/supplier_discount_form_controller.dart';
import 'package:tablets/src/features/supplier_discount/model/supplier_discount.dart';
import 'package:tablets/src/features/supplier_discount/repository/supplier_discount_repository_provider.dart';
import 'package:tablets/src/features/supplier_discount/view/supplier_discount_form.dart';

class SupplierDiscountScreen extends ConsumerWidget {
  const SupplierDiscountScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplierDiscountAsyncValue = ref.watch(supplierDiscountStreamProvider);
    return AppScreenFrame(
      Container(
        padding: const EdgeInsets.all(0),
        child: supplierDiscountAsyncValue.when(
          data: (salespoints) => SupplierDiscountList(salespoints),
          loading: () => const CircularProgressIndicator(), // Show loading indicator
          error: (error, stack) => Text('Error: $error'), // Handle errors
        ),
      ),
      buttonsWidget: const SupplierDiscountFloatingButtons(),
    );
  }
}

class SupplierDiscountList extends ConsumerWidget {
  const SupplierDiscountList(this.discounts, {super.key});

  final List<Map<String, dynamic>> discounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget screenWidget = discounts.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const ListHeaders(),
                const Divider(),
                ListData(discounts),
              ],
            ),
          )
        : const EmptyPage();
    return screenWidget;
  }
}

class ListData extends ConsumerWidget {
  const ListData(this.discounts, {super.key});

  final List<Map<String, dynamic>> discounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: ListView.builder(
        itemCount: discounts.length,
        itemBuilder: (ctx, index) {
          final discountData = discounts[index];
          return Column(
            children: [
              DataRow(discountData, index + 1),
              const Divider(thickness: 0.2, color: Colors.grey),
            ],
          );
        },
      ),
    );
  }
}

class ListHeaders extends ConsumerWidget {
  const ListHeaders({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('تسلسل'),
        Text('المجهز'),
        Text('المادة'),
        Text('التاريخ'),
        Text('العدد'),
        Text('تخفيض القطعة'),
        Text('السعر الجديد'),
      ],
    );
  }
}

class DataRow extends ConsumerWidget {
  const DataRow(this.discountData, this.sequence, {super.key});
  final Map<String, dynamic> discountData;
  final int sequence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SupplierDiscount discount = SupplierDiscount.fromMap(discountData);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MainScreenNumberedEditButton(sequence, () {}),
          Text(discount.supplierName),
          Text(discount.productName),
          Text(formatDateTime(discount.date)),
          Text(doubleToStringWithComma(discount.quantity)),
          Text(doubleToStringWithComma(discount.discountAmount)),
          Text(doubleToStringWithComma(discount.newPrice)),
        ],
      ),
    );
  }
}

class SupplierDiscountFloatingButtons extends ConsumerWidget {
  const SupplierDiscountFloatingButtons({super.key});

  void showAddSupplierDiscountForm(BuildContext context, WidgetRef ref) {
    ref.read(supplierDiscountFormDataProvider.notifier).reset();
    showDialog(
      context: context,
      builder: (BuildContext ctx) => const SupplierDiscountForm(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const iconsColor = Color.fromARGB(255, 126, 106, 211);
    return SpeedDial(
      direction: SpeedDialDirection.up,
      switchLabelPosition: false,
      animatedIcon: AnimatedIcons.menu_close,
      spaceBetweenChildren: 10,
      animatedIconTheme: const IconThemeData(size: 28.0),
      visible: true,
      curve: Curves.bounceInOut,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.add, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () => showAddSupplierDiscountForm(context, ref),
        ),
      ],
    );
  }
}
