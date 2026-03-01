import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/widgets/show_transaction_dialog.dart';
import 'package:tablets/src/features/edit_log/edit_log_service.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

final editLogEntriesProvider = StateProvider<List<EditLogEntry>>((ref) => []);

final filteredEditLogEntriesProvider =
    StateProvider<List<EditLogEntry>>((ref) => []);

class EditLogScreen extends ConsumerStatefulWidget {
  const EditLogScreen({super.key});

  @override
  ConsumerState<EditLogScreen> createState() => _EditLogScreenState();
}

class _EditLogScreenState extends ConsumerState<EditLogScreen> {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _salesmanController = TextEditingController();
  String? _selectedType;
  DateTime? _selectedEditDate;
  DateTime? _selectedTransactionDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntries();
    });
  }

  void _loadEntries() {
    final service = ref.read(editLogServiceProvider);
    final entries = service.loadAllEntries();
    entries.sort((a, b) => b.editTime.compareTo(a.editTime));
    ref.read(editLogEntriesProvider.notifier).state = entries;
    ref.read(filteredEditLogEntriesProvider.notifier).state = entries;
  }

  void _applyFilters() {
    final allEntries = ref.read(editLogEntriesProvider);
    var filtered = allEntries.toList();

    // Edit date filter - searches the edit timestamp only
    if (_selectedEditDate != null) {
      filtered = filtered.where((e) {
        return e.editTime.year == _selectedEditDate!.year &&
            e.editTime.month == _selectedEditDate!.month &&
            e.editTime.day == _selectedEditDate!.day;
      }).toList();
    }

    // Transaction type filter - searches both old and new
    if (_selectedType != null && _selectedType!.isNotEmpty) {
      filtered = filtered
          .where((e) =>
              e.oldTransaction['transactionType'] == _selectedType ||
              e.newTransaction['transactionType'] == _selectedType)
          .toList();
    }

    // Number filter - searches both old and new
    final numberText = _numberController.text.trim();
    if (numberText.isNotEmpty) {
      final number = int.tryParse(numberText);
      if (number != null) {
        filtered = filtered
            .where((e) =>
                e.oldTransaction['number'] == number ||
                e.newTransaction['number'] == number)
            .toList();
      }
    }

    // Customer name filter - searches both old and new
    final nameText = _nameController.text.trim();
    if (nameText.isNotEmpty) {
      filtered = filtered
          .where((e) =>
              (e.oldTransaction['name'] ?? '').toString().contains(nameText) ||
              (e.newTransaction['name'] ?? '').toString().contains(nameText))
          .toList();
    }

    // Salesman filter - searches both old and new
    final salesmanText = _salesmanController.text.trim();
    if (salesmanText.isNotEmpty) {
      filtered = filtered
          .where((e) =>
              (e.oldTransaction['salesman'] ?? '')
                  .toString()
                  .contains(salesmanText) ||
              (e.newTransaction['salesman'] ?? '')
                  .toString()
                  .contains(salesmanText))
          .toList();
    }

    // Transaction date filter - searches both old and new
    if (_selectedTransactionDate != null) {
      filtered = filtered.where((e) {
        final oldDate = _parseTransactionDate(e.oldTransaction['date']);
        final newDate = _parseTransactionDate(e.newTransaction['date']);
        return _isSameDay(oldDate, _selectedTransactionDate!) ||
            _isSameDay(newDate, _selectedTransactionDate!);
      }).toList();
    }

    ref.read(filteredEditLogEntriesProvider.notifier).state = filtered;
  }

  DateTime? _parseTransactionDate(dynamic date) {
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date);
    return null;
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _clearFilters() {
    _numberController.clear();
    _nameController.clear();
    _salesmanController.clear();
    setState(() {
      _selectedType = null;
      _selectedEditDate = null;
      _selectedTransactionDate = null;
    });
    ref.read(filteredEditLogEntriesProvider.notifier).state =
        ref.read(editLogEntriesProvider);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _salesmanController.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _numberController.text.isNotEmpty ||
      _nameController.text.isNotEmpty ||
      _salesmanController.text.isNotEmpty ||
      _selectedType != null ||
      _selectedEditDate != null ||
      _selectedTransactionDate != null;

  @override
  Widget build(BuildContext context) {
    final filteredEntries = ref.watch(filteredEditLogEntriesProvider);
    final allEntries = ref.watch(editLogEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التعديلات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed(AppRoute.home.name),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filters row above the table
            _buildFiltersRow(context),
            const SizedBox(height: 8),
            // Column headers
            _buildColumnHeaders(),
            const Divider(thickness: 2),
            // Table data
            Expanded(
              child: allEntries.isEmpty
                  ? const Center(
                      child: Text('لا توجد سجلات تعديل',
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
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow(BuildContext context) {
    const filterPadding = EdgeInsets.symmetric(horizontal: 4);
    const filterStyle = TextStyle(fontSize: 11);
    const hintStyle = TextStyle(fontSize: 11);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Clear filters button
          SizedBox(
            width: 36,
            child: _hasFilters
                ? IconButton(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.cancel_outlined,
                        color: Colors.red, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : const SizedBox(),
          ),
          const SizedBox(width: 4),
          // Edit date filter
          Expanded(
            child: Padding(
              padding: filterPadding,
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedEditDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedEditDate = date);
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
                    _selectedEditDate != null
                        ? DateFormat('dd-MM-yyyy').format(_selectedEditDate!)
                        : 'تاريخ التعديل',
                    textAlign: TextAlign.center,
                    style: filterStyle,
                  ),
                ),
              ),
            ),
          ),
          // Transaction type filter
          Expanded(
            child: Padding(
              padding: filterPadding,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedType,
                hint: const Text('نوع التعامل', style: hintStyle),
                isExpanded: true,
                isDense: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                              style: filterStyle),
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
            child: Padding(
              padding: filterPadding,
              child: TextField(
                controller: _numberController,
                decoration: const InputDecoration(
                  hintText: 'رقم القائمة',
                  hintStyle: hintStyle,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                ),
                textAlign: TextAlign.center,
                style: filterStyle,
                onChanged: (_) => _applyFilters(),
              ),
            ),
          ),
          // Customer name filter
          Expanded(
            child: Padding(
              padding: filterPadding,
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'اسم الزبون',
                  hintStyle: hintStyle,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                ),
                textAlign: TextAlign.center,
                style: filterStyle,
                onChanged: (_) => _applyFilters(),
              ),
            ),
          ),
          // Salesman name filter
          Expanded(
            child: Padding(
              padding: filterPadding,
              child: TextField(
                controller: _salesmanController,
                decoration: const InputDecoration(
                  hintText: 'اسم المندوب',
                  hintStyle: hintStyle,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                ),
                textAlign: TextAlign.center,
                style: filterStyle,
                onChanged: (_) => _applyFilters(),
              ),
            ),
          ),
          // Transaction date filter
          Expanded(
            child: Padding(
              padding: filterPadding,
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedTransactionDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedTransactionDate = date);
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
                    _selectedTransactionDate != null
                        ? DateFormat('dd-MM-yyyy')
                            .format(_selectedTransactionDate!)
                        : 'تاريخ التعامل',
                    textAlign: TextAlign.center,
                    style: filterStyle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders() {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      color: Colors.grey[200],
      child: const Row(
        children: [
          SizedBox(
              width: 40,
              child:
                  Text('#', style: headerStyle, textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('الوقت',
                  style: headerStyle, textAlign: TextAlign.center)),
          Expanded(
              flex: 3,
              child: Text('النسخة القديمة',
                  style: headerStyle, textAlign: TextAlign.center)),
          Expanded(
              flex: 3,
              child: Text('النسخة الجديدة',
                  style: headerStyle, textAlign: TextAlign.center)),
          Expanded(
              flex: 3,
              child: Text('التغييرات',
                  style: headerStyle, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildTableRow(
      BuildContext context, EditLogEntry entry, int rowNumber) {
    final dateTimeFormat = DateFormat('dd-MM-yyyy hh:mm a');

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
              dateTimeFormat.format(entry.editTime),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _showTransaction(context, entry.oldTransaction),
              child: _buildSummary(context, entry.oldTransaction),
            ),
          ),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _showTransaction(context, entry.newTransaction),
              child: _buildSummary(context, entry.newTransaction),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              entry.changedFields.join('، '),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, Map<String, dynamic> tx) {
    final type =
        translateDbTextToScreenText(context, tx['transactionType'] ?? '');
    final number = (tx['number'] as num?)?.toInt().toString() ?? '';
    final name = tx['name'] ?? '';
    final amount = (tx['totalAmount'] as num?)?.toInt().toString() ?? '';

    String dateStr = '';
    final dateValue = tx['date'];
    if (dateValue is String) {
      final parsed = DateTime.tryParse(dateValue);
      if (parsed != null) {
        dateStr = DateFormat('dd-MM-yyyy').format(parsed);
      }
    } else if (dateValue is DateTime) {
      dateStr = DateFormat('dd-MM-yyyy').format(dateValue);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$type | $number | $name | $amount | $dateStr',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showTransaction(BuildContext context, Map<String, dynamic> txData) {
    try {
      final transactionData = Map<String, dynamic>.from(txData);
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
