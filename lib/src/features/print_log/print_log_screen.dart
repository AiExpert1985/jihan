import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/show_transaction_dialog.dart';
import 'package:tablets/src/features/print_log/print_log_service.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/routers/go_router_provider.dart';
import 'package:tablets/src/common/widgets/main_drawer.dart';

/// Provider that holds the loaded print log entries
final printLogEntriesProvider =
    StateProvider<List<PrintLogEntry>>((ref) => []);

/// Provider that holds the filtered entries for display
final filteredPrintLogEntriesProvider =
    StateProvider<List<PrintLogEntry>>((ref) => []);

class PrintLogScreen extends ConsumerStatefulWidget {
  const PrintLogScreen({super.key});

  @override
  ConsumerState<PrintLogScreen> createState() => _PrintLogScreenState();
}

class _PrintLogScreenState extends ConsumerState<PrintLogScreen> {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedType;
  DateTime? _selectedDate;
  DateTime? _selectedPrintDate;
  String? _selectedPrintType;

  @override
  void initState() {
    super.initState();
    // Load entries after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntries();
    });
  }

  void _loadEntries() {
    final service = ref.read(printLogServiceProvider);
    final entries = service.loadAllEntries();
    // Sort newest first
    entries.sort((a, b) => b.printTime.compareTo(a.printTime));
    ref.read(printLogEntriesProvider.notifier).state = entries;
    ref.read(filteredPrintLogEntriesProvider.notifier).state = entries;
  }

  void _applyFilters() {
    final allEntries = ref.read(printLogEntriesProvider);
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
    if (_selectedType != null && _selectedType!.isNotEmpty) {
      filtered = filtered
          .where((e) => e.transaction['transactionType'] == _selectedType)
          .toList();
    }

    // Filter by transaction date
    if (_selectedDate != null) {
      filtered = filtered.where((e) {
        final entryDate = _parseTransactionDate(e.transaction['date']);
        if (entryDate == null) return false;
        return entryDate.year == _selectedDate!.year &&
            entryDate.month == _selectedDate!.month &&
            entryDate.day == _selectedDate!.day;
      }).toList();
    }

    // Filter by print date
    if (_selectedPrintDate != null) {
      filtered = filtered.where((e) {
        return e.printTime.year == _selectedPrintDate!.year &&
            e.printTime.month == _selectedPrintDate!.month &&
            e.printTime.day == _selectedPrintDate!.day;
      }).toList();
    }

    // Filter by print type
    if (_selectedPrintType != null && _selectedPrintType!.isNotEmpty) {
      filtered =
          filtered.where((e) => e.printType == _selectedPrintType).toList();
    }

    ref.read(filteredPrintLogEntriesProvider.notifier).state = filtered;
  }

  DateTime? _parseTransactionDate(dynamic date) {
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date);
    return null;
  }

  void _clearFilters() {
    _numberController.clear();
    _nameController.clear();
    setState(() {
      _selectedType = null;
      _selectedDate = null;
      _selectedPrintDate = null;
      _selectedPrintType = null;
    });
    ref.read(filteredPrintLogEntriesProvider.notifier).state =
        ref.read(printLogEntriesProvider);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = ref.watch(filteredPrintLogEntriesProvider);
    final allEntries = ref.watch(printLogEntriesProvider);
    final hasFilters = _numberController.text.isNotEmpty ||
        _nameController.text.isNotEmpty ||
        _selectedType != null ||
        _selectedDate != null ||
        _selectedPrintDate != null ||
        _selectedPrintType != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الطباعة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed(AppRoute.home.name),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Table header with filters
            _buildHeaderWithFilters(context, hasFilters),
            const Divider(thickness: 2),
            // Table data
            Expanded(
              child: allEntries.isEmpty
                  ? const Center(
                      child: Text('لا توجد سجلات طباعة',
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
                                  onTap: () => _showTransaction(context, entry),
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
            // Missing transactions detection button (moved from SettingsDialog)
            const MissingTransactionsDetectionButton(),
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
                  child: Text('تاريخ التعامل',
                      style: headerStyle, textAlign: TextAlign.center)),
              const Expanded(
                  flex: 2,
                  child: Text('تاريخ الطباعة',
                      style: headerStyle, textAlign: TextAlign.center)),
              const Expanded(
                  flex: 1,
                  child: Text('نوع الطباعة',
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
                    initialValue: _selectedType,
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
                      setState(() => _selectedType = value);
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
              // Transaction date filter
              Expanded(
                flex: 1,
                child: Padding(
                  padding: filterPadding,
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
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
                        _selectedDate != null
                            ? DateFormat('dd-MM-yyyy').format(_selectedDate!)
                            : '...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ),
              // Print date filter
              Expanded(
                flex: 2,
                child: Padding(
                  padding: filterPadding,
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedPrintDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedPrintDate = date);
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
                        _selectedPrintDate != null
                            ? DateFormat('dd-MM-yyyy')
                                .format(_selectedPrintDate!)
                            : '...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ),
              // Print type dropdown
              Expanded(
                flex: 1,
                child: Padding(
                  padding: filterPadding,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPrintType,
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
                          value: 'local',
                          child: Text('طباعة محلية',
                              style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(
                          value: 'warehouse',
                          child: Text('ارسال للمخزن',
                              style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPrintType = value);
                      _applyFilters();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
      BuildContext context, PrintLogEntry entry, int rowNumber) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final dateTimeFormat = DateFormat('dd-MM-yyyy HH:mm');

    // Parse transaction date
    String transactionDate = '';
    final dateValue = entry.transaction['date'];
    if (dateValue is String) {
      final parsed = DateTime.tryParse(dateValue);
      if (parsed != null) {
        transactionDate = dateFormat.format(parsed);
      } else {
        transactionDate = dateValue;
      }
    } else if (dateValue is DateTime) {
      transactionDate = dateFormat.format(dateValue);
    }

    final printTypeText =
        entry.printType == 'local' ? 'طباعة محلية' : 'ارسال للمخزن';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
              transactionDate,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              dateTimeFormat.format(entry.printTime),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              printTypeText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showTransaction(BuildContext context, PrintLogEntry entry) {
    try {
      final transactionData = Map<String, dynamic>.from(entry.transaction);
      // Provide default for imageUrls - older log entries may not have it
      transactionData['imageUrls'] ??= <String>[];
      // Convert date from ISO string to DateTime if needed
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
