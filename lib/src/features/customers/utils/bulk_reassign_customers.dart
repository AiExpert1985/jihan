import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:tablets/src/common/classes/db_repository.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/customers/repository/customer_repository_provider.dart';
import 'package:tablets/src/features/customers/model/customer.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_repository_provider.dart';

class BulkCustomerReassignmentButton extends ConsumerStatefulWidget {
  const BulkCustomerReassignmentButton({super.key});

  @override
  ConsumerState<BulkCustomerReassignmentButton> createState() =>
      _BulkCustomerReassignmentButtonState();
}

class _BulkCustomerReassignmentButtonState extends ConsumerState<BulkCustomerReassignmentButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showReassignmentDialog(context),
      icon: const Icon(Icons.people_alt),
      label: const Text('تعيين مندوبين'),
    );
  }

  void _showReassignmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ReassignmentDialog(),
    );
  }
}

class ReassignmentDialog extends ConsumerStatefulWidget {
  const ReassignmentDialog({super.key});

  @override
  ConsumerState<ReassignmentDialog> createState() => _ReassignmentDialogState();
}

class _ReassignmentDialogState extends ConsumerState<ReassignmentDialog> {
  String? selectedSalesmanDbRef;
  String? selectedSalesmanName;
  List<String> selectedRegionDbRefs = [];
  List<String> selectedRegionNames = [];
  bool isLoading = false;

  // Use existing providers - import them or reference them directly
  // For salesmen, use the existing provider: salesmanRepositoryProvider
  // For regions, create or import the regions provider
  static final regionsRepositoryProvider = Provider<DbRepository>((ref) {
    return DbRepository('regions');
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تخصيص منطقة لمندوب'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   'قم بأختيار المنطقة',
            //   style: TextStyle(fontSize: 14),
            // ),
            const SizedBox(height: 20),

            // Region Multi-Select with Search
            const Text('المناطق:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: ref.read(regionsRepositoryProvider).watchItemListAsMaps(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    height: 56,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(child: Text('لا يوجد مناطق')),
                  );
                }

                final regions = snapshot.data!;
                final items = regions
                    .map((region) => MultiSelectItem<String>(
                        region['dbRef'], region['name'] ?? 'منطقة غير معروفة'))
                    .toList();

                return MultiSelectDialogField<String>(
                  items: items,
                  title: const Text("اختيار المناطق"),
                  selectedColor: Colors.blue,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.all(Radius.circular(40)),
                    border: Border.all(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                  buttonIcon: const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                  ),
                  buttonText: Text(
                    "اختيار المناطق",
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 16,
                    ),
                  ),
                  searchable: true,
                  searchHint: "البحث عن منطقة...",
                  confirmText: const Text("تأكيد"),
                  cancelText: const Text("إلغاء"),
                  onConfirm: (results) {
                    setState(() {
                      selectedRegionDbRefs = results.cast<String>();
                      selectedRegionNames = results
                          .cast<String>()
                          .map((dbRef) =>
                              regions.firstWhere((region) => region['dbRef'] == dbRef)['name'] ??
                              'منطقة غير معروفة')
                          .toList() as List<String>;
                    });
                  },
                  chipDisplay: MultiSelectChipDisplay(
                    onTap: (value) {
                      setState(() {
                        selectedRegionDbRefs.remove(value);
                        final regionName =
                            regions.firstWhere((region) => region['dbRef'] == value)['name'] ??
                                'منطقة غير معروفة';
                        selectedRegionNames.remove(regionName);
                      });
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Salesman Dropdown
            const Text('المندوب:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: ref.read(salesmanRepositoryProvider).watchItemListAsMaps(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    height: 56,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(child: Text('لا يوجد مندوبين')),
                  );
                }

                final salesmen = snapshot.data!;
                return DropdownButtonFormField<String>(
                  value: selectedSalesmanDbRef,
                  hint: const Text('اختيار مندوب'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: salesmen.map((salesman) {
                    return DropdownMenuItem<String>(
                      value: salesman['dbRef'],
                      child: Text(salesman['name'] ?? 'مندوب غير معروف'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSalesmanDbRef = value;
                      selectedSalesmanName =
                          salesmen.firstWhere((salesman) => salesman['dbRef'] == value)['name'];
                    });
                  },
                );
              },
            ),

            if (selectedRegionNames.isNotEmpty && selectedSalesmanName != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'جميع الزبائين في المناطق: "${selectedRegionNames.join('، ')}" سوف يتم تحويلهم الى المندوب "$selectedSalesmanName"',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // TextButton(
        //   onPressed: isLoading ? null : () => Navigator.of(context).pop(),
        //   child: const Text('عدم تغيير'),
        // ),
        ElevatedButton(
          onPressed:
              (selectedSalesmanDbRef != null && selectedRegionDbRefs.isNotEmpty && !isLoading)
                  ? _performReassignment
                  : null,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('تغيير'),
        ),
      ],
    );
  }

  Future<void> _performReassignment() async {
    if (selectedSalesmanDbRef == null || selectedRegionDbRefs.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final customersRepo = ref.read(customerRepositoryProvider);

      int totalSuccessCount = 0;
      int totalFailCount = 0;

      // Process each selected region
      for (final regionDbRef in selectedRegionDbRefs) {
        // Fetch all customers in the current region
        final customers = await customersRepo.fetchItemListAsMaps(
          filterKey: 'regionDbRef',
          filterValue: regionDbRef,
        );

        // Update each customer with the new salesman
        for (final customerData in customers) {
          try {
            // Create updated customer object
            final updatedCustomerData = Map<String, dynamic>.from(customerData);
            updatedCustomerData['salesmanDbRef'] = selectedSalesmanDbRef;
            updatedCustomerData['salesman'] = selectedSalesmanName;

            // Convert to Customer object for update
            final customer = Customer.fromMap(updatedCustomerData);
            await customersRepo.updateItem(customer);
            totalSuccessCount++;
            // update salesman db cache
            final salesmanDbCache = ref.read(salesmanDbCacheProvider.notifier);
            final salesmanData = await ref.read(salesmanRepositoryProvider).fetchItemListAsMaps();
            salesmanDbCache.set(salesmanData);

            // update customers db cache
            final customerDbCache = ref.read(customerDbCacheProvider.notifier);
            final customerDataMaps =
                await ref.read(customerRepositoryProvider).fetchItemListAsMaps();
            customerDbCache.set(customerDataMaps);
          } catch (e) {
            totalFailCount++;
            debugPrint('Failed to update customer ${customerData['name']}: $e');
          }
        }
      }

      if (totalSuccessCount == 0 && totalFailCount == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'No customers found in selected regions: "${selectedRegionNames.join('، ')}"'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.of(context).pop();

        // Show result message
        final message = totalFailCount == 0
            ? 'تم بنجاح اعادة تعيين $totalSuccessCount زبائن الى "$selectedSalesmanName"'
            : 'اعادة تعيين $totalSuccessCount زبائن, $totalFailCount فشلت';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: totalFailCount == 0 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reassign customers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
