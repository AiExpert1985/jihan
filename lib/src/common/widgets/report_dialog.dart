import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/show_transaction_dialog.dart';

void showReportDialog(
  BuildContext context,
  List<String> columnTitles,
  List<List<dynamic>> dataList, {
  String? title,
  int? dateIndex,
  int? dropdownIndex,
  List<String>? dropdownList,
  String? dropdownLabel,
  int? sumIndex,
  double width = 800,
  double height = 650,
  // if useOriginalTransaction is ture, it means first item is the orginal transaction
  // it will not be displayed in the rows of data, but used to show the orginal transaction
  // as a read only dialog when the row is pressed.
  bool useOriginalTransaction = false,
  // if isCount, means we take count, not sum
  bool isCount = false,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return _DateFilterDialog(
          title: title,
          width: width,
          height: height,
          titleList: columnTitles,
          dataList: dataList,
          dateIndex: dateIndex,
          dropdownIndex: dropdownIndex,
          dropdownList: dropdownList,
          dropdownLabel: dropdownLabel,
          sumIndex: sumIndex,
          useOriginalTransaction: useOriginalTransaction,
          isCount: isCount);
    },
  );
}

class _DateFilterDialog extends StatefulWidget {
  final double width;
  final double height;
  final List<String> titleList;
  final List<List<dynamic>> dataList;
  final String? title;
  final int? dateIndex;
  final int? dropdownIndex;
  final List<String>? dropdownList;
  final String? dropdownLabel;
  final int? sumIndex;
  final bool useOriginalTransaction;
  final bool isCount;
  final bool useAbsoluteNumbers;

  const _DateFilterDialog({
    required this.width,
    required this.height,
    required this.titleList,
    required this.dataList,
    this.title,
    this.dateIndex,
    this.dropdownIndex,
    this.dropdownList,
    this.dropdownLabel,
    this.sumIndex,
    required this.useOriginalTransaction,
    required this.isCount,
    // ignore: unused_element
    this.useAbsoluteNumbers = false,
  });

  @override
  __DateFilterDialogState createState() => __DateFilterDialogState();
}

class __DateFilterDialogState extends State<_DateFilterDialog> {
  DateTime? startDate;
  DateTime? endDate;
  List<String> selectedDropdownValues = [];
  List<List<dynamic>> filteredList = [];

  @override
  void initState() {
    if (widget.dateIndex != null) {
      sortListOfListsByDate(widget.dataList, widget.dateIndex!, isAscending: true);
    }
    super.initState();
    filteredList = List.from(widget.dataList);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.title != null) _buildTitle(),
            VerticalGap.xl,
            if (widget.dateIndex != null) _buildDateSelectionRow(),
            VerticalGap.l,
            if (widget.dropdownIndex != null && widget.dropdownList != null)
              _buildMultiSelectDropdown(),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildListTitles(),
            _buildDataList(),
            if (widget.sumIndex != null) _buildSumDisplay(),
            if (widget.isCount) _buildCountDisplay(),
          ],
        ),
      ),
      actions: _buildButtons(),
    );
  }

  void _filterData() {
    final newList = widget.dataList.where((list) {
      // Filter by date
      if (widget.dateIndex != null && list.length > widget.dateIndex!) {
        DateTime date;
        try {
          date = DateTime.parse(list[widget.dateIndex!].toString());
        } catch (e) {
          return false;
        }
        bool dateInRange =
            (startDate == null || date.isAfter(startDate!.subtract(const Duration(days: 1)))) &&
                (endDate == null || date.isBefore(endDate!.add(const Duration(days: 1))));

        // Filter by dropdown selection if applicable
        if (widget.dropdownIndex != null && widget.dropdownList != null) {
          String dropdownValue = list[widget.dropdownIndex!].toString();
          return dateInRange &&
              (selectedDropdownValues.isEmpty || selectedDropdownValues.contains(dropdownValue));
        }
        return dateInRange;
      }
      return false;
    }).toList();

    setState(() {
      filteredList = newList;
    });
  }

  Widget _buildDateSelectionRow() {
    return Row(
      children: [
        _buildCancelButton(startDate, () {
          setState(() {
            startDate = null;
          });
          _filterData();
        }),
        _buildDatePicker('start_date', startDate, S.of(context).from_date, (value) {
          setState(() {
            startDate = value;
          });
          _filterData();
        }),
        HorizontalGap.l,
        _buildCancelButton(endDate, () {
          setState(() {
            endDate = null;
          });
          _filterData();
        }),
        _buildDatePicker('end_date', endDate, S.of(context).to_date, (value) {
          setState(() {
            endDate = value;
          });
          _filterData();
        }),
      ],
    );
  }

  Widget _buildMultiSelectDropdown() {
    return MultiSelectDialogField(
      separateSelectedItems: false,
      dialogHeight: widget.dropdownList!.length * 60,
      dialogWidth: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey), // Border color
        borderRadius: BorderRadius.circular(4.0), // Rounded corners
      ),
      confirmText: Text(S.of(context).select),
      cancelText: Text(S.of(context).cancel),
      items: widget.dropdownList!
          .map((String value) => MultiSelectItem<String>(value, value))
          .toList(),
      title: Text(widget.dropdownLabel ?? ''),
      buttonText: Text(
        widget.dropdownLabel ?? '',
        style: const TextStyle(color: Colors.black26, fontSize: 15),
      ),
      onConfirm: (List<String> values) {
        setState(() {
          selectedDropdownValues = values;
        });
        _filterData();
      },
      initialValue: selectedDropdownValues,
      searchable: true,
    );
  }

  Widget _buildDatePicker(
      String name, DateTime? initialValue, String labelText, ValueChanged<DateTime?> onChanged) {
    return Expanded(
      child: FormBuilderDateTimePicker(
        textAlign: TextAlign.center,
        name: name,
        decoration: InputDecoration(
          labelStyle: const TextStyle(color: Colors.black26, fontSize: 15),
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        initialValue: initialValue,
        inputType: InputType.date,
        format: DateFormat('dd-MM-yyyy'),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCancelButton(DateTime? date, VoidCallback onPressed) {
    return Visibility(
      visible: date != null,
      child: IconButton(
        icon: const Icon(Icons.clear, size: 15, color: Colors.red),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildListTitles() {
    return _buildRowContrainer(
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: widget.titleList.map((item) {
          return SizedBox(
            width: widget.width / widget.titleList.length,
            child: Text(item,
                style:
                    const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDataList() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      width: widget.width,
      height: widget.height * 0.3, // Set a fixed height for the list
      child: ListView.builder(
        itemCount: filteredList.length,
        // separatorBuilder: (context, index) => const Divider(thickness: 0.5, color: Colors.grey),
        itemBuilder: (context, index) {
          final data = filteredList[index];
          Widget displayedWidget = widget.useOriginalTransaction
              ? InkWell(
                  child: _buildDataRow(data),
                  onTap: () {
                    if (widget.useOriginalTransaction) {
                      // if useOriginalTransaction the, first item is alway the orginal transaction
                      showReadOnlyTransaction(context, data[0]);
                    }
                  },
                )
              : _buildDataRow(data);
          return displayedWidget;
        },
      ),
    );
  }

  Widget _buildDataRow(List<dynamic> data) {
    // if useOriginalTransaction is true, it means first item is Transaction
    // we don't want to display it, we want to used it as a button that show
    // a read only transaction dialog
    final itemsToDisplay = widget.useOriginalTransaction
        ? data.sublist(1, data.length) // Exclude the last item
        : data;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: itemsToDisplay.map((item) {
        if (item is DateTime) item = formatDate(item);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(border: Border.all(width: 0.2)),
          width: widget.width / widget.titleList.length,
          child: Text(
              item is String
                  ? item
                  : doubleToStringWithComma(item, isAbsoluteValue: widget.useAbsoluteNumbers),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        );
      }).toList(),
    );
  }

  Widget _buildTitle() {
    return Text(widget.title!, style: const TextStyle(fontSize: 20));
  }

  Widget _buildSumDisplay() {
    double sum = 0;
    for (var item in filteredList) {
      if (item.length > widget.sumIndex!) {
        sum += item[widget.sumIndex!]?.toDouble() ?? 0;
      }
    }
    return _buildRowContrainer(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 70.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context).total,
                style: const TextStyle(
                    fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
            Text(doubleToStringWithComma(sum),
                style:
                    const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }

  Widget _buildCountDisplay() {
    int count = filteredList.length;

    return _buildRowContrainer(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 70.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context).count,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(doubleToStringWithComma(count.toDouble()),
                style:
                    const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18))
          ],
        ),
      ),
    );
  }

  List<Widget> _buildButtons() {
    return <Widget>[
      Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const PrintIcon(),
              onPressed: () {
                // TODO: Implement print functionality
              },
            ),
            HorizontalGap.m,
            IconButton(
              icon: const ShareIcon(),
              onPressed: () {
                // TODO: Implement share functionality
              },
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildRowContrainer(Widget childWidget) {
    return Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 227, 240, 247),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300)),
        child: childWidget);
  }
}
