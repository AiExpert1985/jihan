import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/features/save_log/save_log_service.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

/// Provider that holds the loaded save log entries
final saveLogEntriesProvider =
    StateProvider<List<SaveLogEntry>>((ref) => []);

/// Provider that holds the filtered entries for display
final filteredSaveLogEntriesProvider =
    StateProvider<List<SaveLogEntry>>((ref) => []);

class SaveLogScreen extends ConsumerStatefulWidget {
  const SaveLogScreen({super.key});

  @override
  ConsumerState<SaveLogScreen> createState() => _SaveLogScreenState();
}

class _SaveLogScreenState extends ConsumerState<SaveLogScreen> {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedTransactionType;
  DateTime? _selectedSaveDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntries();
    });
  }

  void _loadEntries() {
    final service = ref.read(saveLogServiceProvider);
    final entries = service.loadAllEntries();
    // Sort newest first
    entries.sort((a, b) => b.saveTime.compareTo(a.saveTime));
    ref.read(saveLogEntriesProvider.notifier).state = entries;
    ref.read(filteredSaveLogEntriesProvider.notifier).state = entries;
  }

  void _applyFilters() {
    final allEntries = ref.read(saveLogEntriesProvider);
    var filtered = allEntries.toList();

    // Filter by transaction number
    final numberText = _numberController.text.trim();
    if (numberText.isNotEmpty) {
      final number = int.tryParse(numberText);
      if (number != null) {
        filtered = filtered.where((e) => e.number == number).toList();
      }
    }

    // Filter by customer name
    final nameText = _nameController.text.trim();
    if (nameText.isNotEmpty) {
      filtered = filtered
          .where((e) => e.name.contains(nameText))
          .toList();
    }

    // Filter by transaction type
    if (_selectedTransactionType != null &&
        _selectedTransactionType!.isNotEmpty) {
      filtered = filtered
          .where((e) => e.transactionType == _selectedTransactionType)
          .toList();
    }

    // Filter by save date
    if (_selectedSaveDate != null) {
      filtered = filtered.where((e) {
        return e.saveTime.year == _selectedSaveDate!.year &&
            e.saveTime.month == _selectedSaveDate!.month &&
            e.saveTime.day == _selectedSaveDate!.day;
      }).toList();
    }

    ref.read(filteredSaveLogEntriesProvider.notifier).state = filtered;
  }

  void _clearFilters() {
    _numberController.clear();
    _nameController.clear();
    setState(() {
      _selectedTransactionType = null;
      _selectedSaveDate = null;
    });
    ref.read(filteredSaveLogEntriesProvider.notifier).state =
        ref.read(saveLogEntriesProvider);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = ref.watch(filteredSaveLogEntriesProvider);
    final allEntries = ref.watch(saveLogEntriesProvider);
    final hasFilters = _numberController.text.isNotEmpty ||
        _nameController.text.isNotEmpty ||
        _selectedTransactionType != null ||
        _selectedSaveDate != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الحفظ'),
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
                      child: Text('لا توجد سجلات حفظ',
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
                                _buildTableRow(context, entry, index + 1),
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
                  child: Text('المبلغ',
                      style: headerStyle, textAlign: TextAlign.center)),
              const Expanded(
                  flex: 2,
                  child: Text('تاريخ الحفظ',
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
              // Total amount - no filter
              const Expanded(
                flex: 1,
                child: SizedBox(),
              ),
              // Save date filter
              Expanded(
                flex: 2,
                child: Padding(
                  padding: filterPadding,
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedSaveDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedSaveDate = date);
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
                        _selectedSaveDate != null
                            ? DateFormat('dd-MM-yyyy')
                                .format(_selectedSaveDate!)
                            : '...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
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
      BuildContext context, SaveLogEntry entry, int rowNumber) {
    final dateTimeFormat = DateFormat('dd-MM-yyyy HH:mm');

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
              translateDbTextToScreenText(context, entry.transactionType),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              entry.number.toString(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.name,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              entry.totalAmount.toStringAsFixed(0),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              dateTimeFormat.format(entry.saveTime),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
