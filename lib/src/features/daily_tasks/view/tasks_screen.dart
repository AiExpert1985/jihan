import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/user_info_provider.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/daily_tasks/controllers/selected_date_provider.dart';
import 'package:tablets/src/features/daily_tasks/model/point.dart';
import 'package:tablets/src/features/daily_tasks/printing/tasks_pdf.dart';
import 'package:tablets/src/features/daily_tasks/repo/tasks_repository_provider.dart';
import 'package:tablets/src/features/regions/repository/region_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';

class DatePickerWidget extends ConsumerWidget {
  const DatePickerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 200,
      child: FormBuilderDateTimePicker(
        name: 'date',
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
            labelStyle: TextStyle(color: Colors.red, fontSize: 15),
            border: OutlineInputBorder(),
            label: Text('اختيار اليوم')),
        inputType: InputType.date,
        format: DateFormat('dd-MM-yyyy'),
        onChanged: (value) {
          ref.read(selectedDateProvider.notifier).setDate(value);
        },
      ),
    );
  }
}

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesPointsAsyncValue = ref.watch(tasksStreamProvider);
    ref.watch(selectedDateProvider);
    return AppScreenFrame(
      Container(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            const DatePickerWidget(),
            Expanded(
              child: salesPointsAsyncValue.when(
                data: (salespoints) => SalesPoints(salespoints),
                loading: () => const CircularProgressIndicator(), // Show loading indicator
                error: (error, stack) => Text('Error: $error'), // Handle errors
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SalesPoints extends ConsumerWidget {
  const SalesPoints(this.salesPoints, {super.key});
  final List<Map<String, dynamic>> salesPoints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isReadOnly = true;
    final userInfo = ref.watch(userInfoProvider); // to update UI when user info finally loaded
    if (userInfo != null && userInfo.privilage != 'guest') {
      isReadOnly = false;
    }
    final selectedDate = ref.watch(selectedDateProvider);
    // Create list of unique salesman names found in firebase for that date
    Set<String> uniqueSalesmanNames = {};
    for (var salesPoint in salesPoints) {
      String salesmanName = salesPoint['salesmanName'] as String;
      uniqueSalesmanNames.add(salesmanName);
    }
    // Then add the salesmen not found in that day
    final salesmenDbCache = ref.read(salesmanDbCacheProvider.notifier).data;
    final allSalemenNames = salesmenDbCache.map((salesman) => salesman['name']).toList();
    for (var salesmanName in allSalemenNames) {
      uniqueSalesmanNames.add(salesmanName);
    }

    Map<String, List<Map<String, dynamic>>> salesmenTasks = {};
    for (var name in uniqueSalesmanNames) {
      salesmenTasks[name] = []; // Initialize each key with an empty list
    }
    for (var salesPoint in salesPoints) {
      String salesmanName = salesPoint['salesmanName'] as String;
      salesmenTasks[salesmanName]?.add(salesPoint);
    }

    // Convert the map to a list of widgets
    List<Widget> widgetList = [];
    salesmenTasks.forEach((salesmanName, tasks) {
      // Sort customers by the 'region' property
      // Sort the list by the 'age' property, handling nulls

      tasks.sort((a, b) {
        // Handle null values: consider nulls as greater than any number
        final regionA = a['region'];
        final regionB = b['region'];
        if (regionA == null && regionB == null) return 0; // Both are null
        if (regionA == null) return 1; // Nulls are considered greater
        if (regionB == null) return -1; // Nulls are considered greater
        return regionA.compareTo(regionB); // Compare non-null ages
      });
      List<String> tasksCustomerNames =
          tasks.map((task) => task['customerName'] as String).toList();
      widgetList.add(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VerticalGap.xl,
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!isReadOnly)
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: Colors.green,
                    ),
                    onPressed: () async {
                      final salesman = ref
                          .read(salesmanDbCacheProvider.notifier)
                          .getItemByProperty('name', salesmanName);
                      final selectedCustomerNames =
                          await _showMultiSelectDialog(context, ref, salesmanName) ?? [];
                      for (var customerName in selectedCustomerNames) {
                        if (tasksCustomerNames.contains(customerName)) {
                          // if name already exists (it is surely same dates no need to check it), pass it
                          continue;
                        }
                        final customer = ref
                            .read(customerDbCacheProvider.notifier)
                            .getItemByProperty('name', customerName);
                        final newSalesPoint = SalesPoint(
                          salesmanName,
                          salesman['dbRef'],
                          customerName,
                          customer['dbRef'],
                          selectedDate ?? DateTime.now(),
                          false,
                          false,
                          generateRandomString(len: 8),
                          [],
                          generateRandomString(len: 8),
                          customer['x'],
                          customer['y'],
                        );
                        //TODO to prevent adding new salespoint if it already exists
                        ref.read(tasksRepositoryProvider).addItem(newSalesPoint);
                      }
                    },
                  ),
                HorizontalGap.s,
                IconButton(
                    onPressed: () {
                      printReport(tasks);
                    },
                    icon: const Icon(Icons.print)),
                HorizontalGap.l,
                Container(
                  width: 150,
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    salesmanName, // The name as title
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (tasks.isEmpty)
                  Image.asset(
                    'assets/images/empty.png',
                    fit: BoxFit.scaleDown,
                    width: 60,
                  ),
              ],
            ),
            VerticalGap.l,
            // Use Wrap instead of Row for customers
            Wrap(
              spacing: 8.0, // Space between items
              runSpacing: 8.0, // Space between rows
              children: tasks.map((item) {
                final bgColor = !item['isVisited']
                    ? Colors.red
                    : item['hasTransaction']
                        ? Colors.green
                        : Colors.amber;
                final fontColor = item['isVisited'] ? Colors.black : Colors.white;
                return Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 80,
                      padding: const EdgeInsets.only(top: 20, bottom: 5, left: 10, right: 10),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        color: bgColor,
                      ),
                      child: Text(item['customerName'],
                          textAlign: TextAlign.center, style: TextStyle(color: fontColor)),
                    ),
                    if (!isReadOnly)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: TextButton(
                            onPressed: () {
                              ref
                                  .read(tasksRepositoryProvider)
                                  .deleteItem(SalesPoint.fromMap(item));
                            },
                            child: const Text(
                              'x',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      );
    });

    return ListView(
      children: widgetList,
    );
  }
}

Future<List<String>?> _showMultiSelectDialog(
    BuildContext context, WidgetRef ref, String salesmanName) async {
  final customerDbCache = ref.read(customerDbCacheProvider.notifier).data;
  List<String> customerNames =
      customerDbCache.map((customer) => customer['name'] as String).toList();

  final regionDbCache = ref.read(regionDbCacheProvider.notifier).data;
  List<String> regionNames = regionDbCache.map((region) => region['name'] as String).toList();

  final selectedValues = showDialog<List<String>?>(
    context: context,
    builder: (BuildContext context) {
      List<String> selectedCustomerNames = []; // to store customers selection from both dropdowns
      List<String> selectedRegions = [];
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 400,
          height: 800,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Use min size to avoid unnecessary height

              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 40, left: 25.0, right: 25.0),
                  child: Text(
                    salesmanName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                // First MultiSelectDialogField

                MultiSelectDialogField(
                  dialogWidth: 400,
                  dialogHeight: 700,
                  initialValue: selectedCustomerNames,
                  confirmText: Text(S.of(context).select),
                  cancelText: Text(S.of(context).cancel),
                  title: const Text('اختيار الزبائن'),
                  buttonText: const Text(
                    'اختيار الزبائن',
                    style: TextStyle(color: Colors.black26, fontSize: 15),
                  ),
                  items: customerNames
                      .map((String value) => MultiSelectItem<String>(value, value))
                      .toList(),
                  onConfirm: (List<String> newCustomerNames) {
                    for (var newName in newCustomerNames) {
                      if (!selectedCustomerNames.contains(newName)) {
                        selectedCustomerNames.add(newName);
                      }
                    }
                  },
                  searchable: true,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),

                const SizedBox(height: 16), // Add some spacing

                // Second MultiSelectDialogField

                MultiSelectDialogField(
                  dialogWidth: 400,
                  dialogHeight: 700,
                  initialValue: selectedRegions,
                  confirmText: Text(S.of(context).select),
                  cancelText: Text(S.of(context).cancel),
                  title: const Text('اختيار المناطق'),
                  buttonText: const Text(
                    'اختيار المناطق',
                    style: TextStyle(color: Colors.black26, fontSize: 15),
                  ),
                  items: regionNames
                      .map((String value) => MultiSelectItem<String>(value, value))
                      .toList(),
                  onConfirm: (List<String> selectedRegionNames) {
                    selectedRegions = selectedRegionNames; // to reflect selected regions
                    // convert regions to customer names, and then add it to selected names
                    // note that selected names is for both regions and customers
                    for (var regionName in selectedRegionNames) {
                      final regionCustomers = customerDbCache
                          .where((customer) => customer['region'] == regionName)
                          .toList();
                      final regionCustomerNames =
                          regionCustomers.map((customer) => customer['name'] as String).toList();
                      for (var customerName in regionCustomerNames) {
                        // to avoid duplicate customer names
                        if (!selectedCustomerNames.contains(customerName)) {
                          selectedCustomerNames.add(customerName);
                        }
                      }
                    }
                  },
                  searchable: true,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),

                const SizedBox(height: 16), // Add some spacing

                // Confirm button to return selected values

                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop(selectedCustomerNames); // Return both selected values
                  },
                  icon: const ApproveIcon(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  return selectedValues; // Return the selected values to the calling function
}

Future<void> printReport(List<Map<String, dynamic>> salesPointMaps) async {
  try {
    List<SalesPoint> salesPoints = [];
    for (var map in salesPointMaps) {
      salesPoints.add(SalesPoint.fromMap(map));
    }
    // 1. Generate the PDF bytes
    final Uint8List pdfBytes =
        await SalesPointPdfGenerator.generatePdf(salesPoints); // Use your actual list here

    // 2. Use the printing package to preview and print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name:
          'Sales_Report_${salesPoints.first.salesmanName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf', // Optional: set default file name
    );
  } catch (e) {
    errorPrint('Error generating or printing PDF for tasks: $e');
  }
}
