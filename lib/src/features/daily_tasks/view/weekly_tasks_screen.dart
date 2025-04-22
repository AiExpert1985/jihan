import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/user_info_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/daily_tasks/model/point.dart';
import 'package:tablets/src/features/daily_tasks/model/weekly_tasks.dart';
import 'package:tablets/src/features/daily_tasks/repo/weekly_tasks_repo.dart';
import 'package:tablets/src/features/regions/repository/region_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';

/// Provider holding the index of the selected weekday (0-6, or null if none selected).
final selectedWeekdayIndexProvider = StateProvider<int>((ref) => 1);

class DayPicker extends ConsumerWidget {
  const DayPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SimpleWeekdaySelector(
      onWeekdayTap: (index) {
        ref.read(selectedWeekdayIndexProvider.notifier).state = index;
      },
    );
  }
}

class WeeklyTasksScreen extends ConsumerWidget {
  const WeeklyTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyTasksAsyncValue = ref.watch(weeklyTasksStreamProvider);
    final selectedDayIndex = ref.watch(selectedWeekdayIndexProvider);
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const DayPicker(),
            Expanded(
              child: dailyTasksAsyncValue.when(
                data: (dailyTasks) {
                  late Map<String, dynamic> dayTasks;
                  if (dailyTasks.isEmpty) {
                    dayTasks = {
                      'weekDay': selectedDayIndex,
                      'tasks': [],
                      'dbRef': generateRandomString(len: 8),
                      'name': generateRandomString(len: 8),
                      'imageUrls': []
                    };
                    ref.read(weeklyTasksRepositoryProvider).addItem(WeeklyTask.fromMap(dayTasks));
                  } else {
                    dayTasks = dailyTasks.first;
                  }
                  return SalesPoints(dayTasks);
                },
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
  const SalesPoints(this.dailyTasks, {super.key});
  final Map<String, dynamic> dailyTasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isReadOnly = true;
    final salesPoints = dailyTasks['tasks'];
    final userInfo = ref.watch(userInfoProvider); // to update UI when user info finally loaded
    if (userInfo != null && userInfo.privilage != 'guest') {
      isReadOnly = false;
    }
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
      // Sort the list by the 'visitDate' property, handling nulls
      // Sort customers by the 'region' property
      tasks.sort((a, b) {
        // --- Primary Sort: visitDate (DateTime?, nulls last) ---
        final DateTime? visitDateA = a['visitDate']?.toDate(); // Get visitDate or null
        final DateTime? visitDateB = b['visitDate']?.toDate(); // Get visitDate or null

        int dateComparison;
        if (visitDateA == null && visitDateB == null) {
          // If both dates are null, they are considered equal for the primary sort.
          dateComparison = 0;
        } else if (visitDateA == null) {
          // Null visitDateA is considered greater (comes after non-null dateB)
          dateComparison = 1;
        } else if (visitDateB == null) {
          // Non-null visitDateA comes before null dateB
          dateComparison = -1;
        } else {
          // Both dates are non-null, compare them chronologically (earlier date first)
          dateComparison = visitDateA.compareTo(visitDateB);
        }

        // If the dates are different, return the result of the date comparison.
        if (dateComparison != 0) {
          return dateComparison;
        }

        // --- Secondary Sort: region (using original logic, nulls last) ---
        // This code only runs if the visitDates were equal (or both null).
        final regionA = a['region'];
        final regionB = b['region'];

        // Use the exact null-handling logic from your original snippet for 'region'
        if (regionA == null && regionB == null) return 0; // Both are null, equal
        if (regionA == null) return 1; // Null regionA is considered greater
        if (regionB == null) return -1; // Non-null regionA comes before null regionB

        // Assuming non-null regions are Comparable (like String)
        // Use compareTo as in the original snippet
        // Add type check/cast if necessary for safety, e.g., (regionA as String).compareTo(regionB as String)
        return (regionA as Comparable).compareTo(regionB as Comparable);
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
                          DateTime.now(),
                          false,
                          false,
                          generateRandomString(len: 8),
                          [defaultImageUrl],
                          generateRandomString(len: 8),
                          customer['x'],
                          customer['y'],
                          null,
                          null,
                        );
                        final newSalesPointMap = newSalesPoint.toMap();
                        newSalesPointMap['date'] = Timestamp.fromDate(newSalesPointMap['date']);
                        dailyTasks['tasks'].add(newSalesPointMap);
                        final dailyTasksObject = WeeklyTask.fromMap(dailyTasks);
                        ref.read(weeklyTasksRepositoryProvider).updateItem(dailyTasksObject);
                      }
                    },
                  ),
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
              children: tasks.map((task) {
                return Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 80,
                      padding: const EdgeInsets.only(top: 20, bottom: 10, left: 10, right: 10),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        color: Colors.blueGrey[100],
                      ),
                      child: Column(
                        children: [
                          Text(
                            task['customerName'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
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
                              const mapEquality = MapEquality<String, dynamic>();
                              dailyTasks['tasks']
                                  .removeWhere((item) => mapEquality.equals(item, task));
                              ref
                                  .read(weeklyTasksRepositoryProvider)
                                  .updateItem(WeeklyTask.fromMap(dailyTasks));
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

class SimpleWeekdaySelector extends ConsumerWidget {
  // The callback function that receives the index (0-6) when a day is tapped.
  final Function(int index) onWeekdayTap;

  // Define the weekday labels (0 = Monday, 6 = Sunday)
  final List<String> weekdays = const [
    'الاثنين',
    'الثلاثاء',
    'الاربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الاحد',
  ];

  const SimpleWeekdaySelector({
    super.key,
    required this.onWeekdayTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedWeekdayIndexProvider);

    return Row(
      // Distribute space nicely between the boxes
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(weekdays.length, (index) {
        Color? bgColor = selectedIndex == (index + 1) ? Colors.orange[300] : Colors.orange[100];
        return InkWell(
          // The function to call when tapped, passing the current index
          onTap: () => onWeekdayTap(index + 1),
          // Optional: Makes the ripple effect match the box shape
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            width: 110,
            height: 85,
            margin: const EdgeInsets.all(5),
            // Internal padding for the box content
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              // A simple background color for the box
              color: bgColor,
              // Rounded corners for a nicer look
              borderRadius: BorderRadius.circular(8.0),
              // Optional: Add a subtle border
              // border: Border.all(color: Colors.blueGrey[200]!),
            ),
            child: Center(
              child: Text(
                weekdays[index], // Display the weekday abbreviation
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black87, // Text color
                  // fontWeight: FontWeight.bold, // Optional: Make text bold
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
