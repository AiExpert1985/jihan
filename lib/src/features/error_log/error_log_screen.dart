import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/show_transaction_dialog.dart';
import 'package:tablets/src/features/error_log/error_log_service.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

/// Provider that holds the loaded error log entries
final errorLogEntriesProvider =
    StateProvider<List<ErrorLogEntry>>((ref) => []);

/// Provider that holds the filtered entries for display
final filteredErrorLogEntriesProvider =
    StateProvider<List<ErrorLogEntry>>((ref) => []);

class ErrorLogScreen extends ConsumerStatefulWidget {
  const ErrorLogScreen({super.key});

  @override
  ConsumerState<ErrorLogScreen> createState() => _ErrorLogScreenState();
}

class _ErrorLogScreenState extends ConsumerState<ErrorLogScreen> {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedTransactionType;
  String? _selectedErrorType;
  String? _selectedOperationType;
  DateTime? _selectedErrorDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntries();
    });
  }

  void _loadEntries() {
    final service = ref.read(errorLogServiceProvider);
    final entries = service.loadAllEntries();
    // Sort newest first
    entries.sort((a, b) => b.errorTime.compareTo(a.errorTime));
    ref.read(errorLogEntriesProvider.notifier).state = entries;
    ref.read(filteredErrorLogEntriesProvider.notifier).state = entries;
  }

  void _applyFilters() {
    final allEntries = ref.read(errorLogEntriesProvider);
    var filtered = allEntries.toList();

    // Filter by transaction number
    final numberText = _numberController.text.trim();
    if (numberText.isNotEmpty) {
      final number = int.tryParse(numberText);
      if (number != null) {
        filtered = filtered
            .where((e) => e.transaction['number'] == number)
            .toList();
      }
    }

    // Filter by customer name
    final nameText = _nameController.text.trim();
    if (nameText.isNotEmpty) {
      filtered = filtered
          .where((e) =>
              (e.transaction['name'] ?? '').toString().contains(nameText))
          .toList();
    }

    // Filter by transaction type
    if (_selectedTransactionType != null &&
        _selectedTransactionType!.isNotEmpty) {
      filtered = filtered
          .where((e) =>
              e.transaction['transactionType'] == _selectedTransactionType)
          .toList();
    }

    // Filter by error type
    if (_selectedErrorType != null && _selectedErrorType!.isNotEmpty) {
      filtered =
          filtered.where((e) => e.errorType == _selectedErrorType).toList();
    }

    // Filter by operation type
    if (_selectedOperationType != null && _selectedOperationType!.isNotEmpty) {
      filtered = filtered
          .where((e) => e.operationType == _selectedOperationType)
          .toList();
    }

    // Filter by error date
    if (_selectedErrorDate != null) {
      filtered = filtered.where((e) {
        return e.errorTime.year == _selectedErrorDate!.year &&
            e.errorTime.month == _selectedErrorDate!.month &&
            e.errorTime.day == _selectedErrorDate!.day;
      }).toList();
    }

    ref.read(filteredErrorLogEntriesProvider.notifier).state = filtered;
  }

  void _clearFilters() {
    _numberController.clear();
    _nameController.clear();
    setState(() {
      _selectedTransactionType = null;
      _selectedErrorType = null;
      _selectedOperationType = null;
      _selectedErrorDate = null;
    });
    ref.read(filteredErrorLogEntriesProvider.notifier).state =
        ref.read(errorLogEntriesProvider);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = ref.watch(filteredErrorLogEntriesProvider);
    final allEntries = ref.watch(errorLogEntriesProvider);
    final hasFilters = _numberController.text.isNotEmpty ||
        _nameController.text.isNotEmpty ||
        _selectedTransactionType != null ||
        _selectedErrorType != null ||
        _selectedOperationType != null ||
        _selectedErrorDate != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الاخطاء'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed(AppRoute.home.name),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderWithFilters(context, hasFilters),
            const Divider(thickness: 2),
            Expanded(
              child: allEntries.isEmpty
                  ? const Center(
                      child: Text('لا توجد سجلات اخطاء',
                          style: TextStyle(fontSize: 18)))
                  : filteredEntries.isEmpty
                      ? const Center(
                          child: Text('لا توجد نتائج مطابقة',
                              style: TextStyle(fontSize: 16)))
                      : ListView.builder(
                          itemCount: filteredEntries.length,
                          itemBuilder: (context, index) {
                            final entry = filteredEntries[index];
                            return Column(
                              children: [
                                InkWell(
                                  onTap: () =>
                                      _showTransaction(context, entry),
                                  child: _buildTableRow(
                                      context, entry, index + 1),
                                ),
                                const Divider(thickness: 0.5),
                              ],
                            );
                          },
                        ),
            ),
            VerticalGap.l,
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderWithFilters(BuildContext context, bool hasFilters) {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold);
    const filterPadding = EdgeInsets.symmetric(horizontal: 4);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      color: Colors.grey[200],
      child: Column(
        children: [
          // Header labels
          Row(
            children: [
              SizedBox(
                  width: 40,
                  child: hasFilters
                      ? IconButton(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.cancel_outlined,
                              color: Colors.red, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      : const Text('#',
                          style: headerStyle, textAlign: TextAlign.center)),
              const Expanded(
                  flex: 2,
                  child: Text('نوع التعامل',
                      style: headerStyle, textAlign: TextAlign.center)),
              const Expanded(
                  flex: 1,
                  child: Text('الرقم',
                      style: headerStyle, textAlign: TextAlign.center)),
              const Expanded(
                  flex: 2,
                  child: Text('اسم الزبون',
                      style: headerStyle, textAlign: TextAlign.center)),
              const Expanded(
                  flex: 1,
                  child: Text('نوع العملية',
                      style: headerStyle, textAlign: TextAlign.center)),
              const Expanded(
                  flex: 1,
                  child: Text('نوع الخطأ',
                      style: headerStyle, textAlign: TextAlign.center)),
              const Expanded(
                  flex: 2,
                  child: Text('تاريخ الخطأ',
                      style: headerStyle, textAlign: TextAlign.center)),
              const Expanded(
                  flex: 3,
                  child: Text('رسالة الخطأ',
                      style: headerStyle, textAlign: TextAlign.center)),
            ],
          ),
          const SizedBox(height: 8),
          // Filter row
          Row(
            children: [
              const SizedBox(width: 40),
              // Transaction type dropdown
              Expanded(
                flex: 2,
                child: Padding(
                  padding: filterPadding,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTransactionType,
                    hint: const Text('الكل', style: TextStyle(fontSize: 12)),
                    isExpanded: true,
                    isDense: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    ),
                    items: [
                      'customerInvoice',
                      'customerReceipt',
                      'customerReturn',
                      'vendorInvoice',
                      'vendorReceipt',
                      'vendorReturn',
                      'expenditures',
                      'gifts',
                      'damagedItems',
                    ]
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                  translateDbTextToScreenText(context, type),
                                  style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedTransactionType = value);
                      _applyFilters();
                    },
                  ),
                ),
              ),
              // Number filter
              Expanded(
                flex: 1,
                child: Padding(
                  padding: filterPadding,
                  child: TextField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                      hintText: '...',
                      hintStyle: TextStyle(fontSize: 12),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
              ),
              // Customer name filter
              Expanded(
                flex: 2,
                child: Padding(
                  padding: filterPadding,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: '...',
                      hintStyle: TextStyle(fontSize: 12),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
              ),
              // Operation type dropdown
              Expanded(
                flex: 1,
                child: Padding(
                  padding: filterPadding,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedOperationType,
                    hint: const Text('الكل', style: TextStyle(fontSize: 12)),
                    isExpanded: true,
                    isDense: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'add',
                          child: Text('اضافة',
                              style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(
                          value: 'edit',
                          child: Text('تعديل',
                              style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(
                          value: 'delete',
                          child: Text('حذف',
                              style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedOperationType = value);
                      _applyFilters();
                    },
                  ),
                ),
              ),
              // Error type dropdown
              Expanded(
                flex: 1,
                child: Padding(
                  padding: filterPadding,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedErrorType,
                    hint: const Text('الكل', style: TextStyle(fontSize: 12)),
                    isExpanded: true,
                    isDense: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'save_failed',
                          child: Text('فشل الحفظ',
                              style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(
                          value: 'delete_failed',
                          child: Text('فشل الحذف',
                              style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(
                          value: 'cache_update_failed',
                          child: Text('فشل التحديث',
                              style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedErrorType = value);
                      _applyFilters();
                    },
                  ),
                ),
              ),
              // Error date filter
              Expanded(
                flex: 2,
                child: Padding(
                  padding: filterPadding,
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedErrorDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedErrorDate = date);
                        _applyFilters();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      ),
                      child: Text(
                        _selectedErrorDate != null
                            ? DateFormat('dd-MM-yyyy')
                                .format(_selectedErrorDate!)
                            : '...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ),
              // Error message placeholder (no filter)
              const Expanded(
                flex: 3,
                child: SizedBox(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
      BuildContext context, ErrorLogEntry entry, int rowNumber) {
    final dateTimeFormat = DateFormat('dd-MM-yyyy HH:mm');

    final operationText = switch (entry.operationType) {
      'add' => 'اضافة',
      'edit' => 'تعديل',
      'delete' => 'حذف',
      _ => entry.operationType,
    };

    final errorTypeText = switch (entry.errorType) {
      'save_failed' => 'فشل الحفظ',
      'delete_failed' => 'فشل الحذف',
      'cache_update_failed' => 'فشل التحديث',
      _ => entry.errorType,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      color: Colors.red[50],
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(rowNumber.toString(), textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text(
              translateDbTextToScreenText(
                  context, entry.transaction['transactionType'] ?? ''),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              (entry.transaction['number'] ?? '').toString(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.transaction['name'] ?? '',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              operationText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              errorTypeText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              dateTimeFormat.format(entry.errorTime),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              entry.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransaction(BuildContext context, ErrorLogEntry entry) {
    try {
      final transactionData = Map<String, dynamic>.from(entry.transaction);
      transactionData['imageUrls'] ??= <String>[];
      if (transactionData['date'] is String) {
        final parsed = DateTime.tryParse(transactionData['date']);
        if (parsed != null) {
          transactionData['date'] = parsed;
        }
      }
      final transaction = Transaction.fromMap(transactionData);
      showReadOnlyTransaction(context, transaction);
    } catch (e) {
      // silently ignore if transaction data is corrupted
    }
  }
}
