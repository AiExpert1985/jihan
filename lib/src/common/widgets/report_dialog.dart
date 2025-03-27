import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/file_system_path.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/printing/print_document.dart';
import 'package:tablets/src/common/printing/print_report.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/show_transaction_dialog.dart';
import 'package:url_launcher/url_launcher_string.dart';

List<bool> isWideField = [];
const minStringLengthForLargeField = 20;
const double wideFieldWidth = 300;

void showReportDialog(
  BuildContext context,
  List<String> columnTitles,
  List<List<dynamic>> dataList, {
  String? title,
  int? dateIndex,
  int? dropdownIndex,
  String? dropdownLabel,
  List<int> summaryIndexes = const [],
  double targetedWidth = 1400,
  double targetedHeight = 1200,
  // if useOriginalTransaction is ture, it means first item is the orginal transaction
  // it will not be displayed in the rows of data, but used to show the orginal transaction
  // as a read only dialog when the row is pressed.
  bool useOriginalTransaction = false,
  int? dropdown2Index,
  String? dropdown2Label,
  int? dropdown3Index,
  String? dropdown3Label,
}) {
  showDialog(
    context: context,
    builder: (context) {
      final maxHeight = MediaQuery.of(context).size.height;
      final height = targetedHeight > maxHeight ? maxHeight : targetedHeight - 10;
      final maxWidth = MediaQuery.of(context).size.width;
      final width = targetedWidth > maxWidth ? maxWidth : targetedWidth - 10;
      return _DateFilterDialog(
        title: title,
        width: width,
        height: height,
        titleList: columnTitles,
        dataList: dataList,
        dateIndex: dateIndex,
        dropdownIndex: dropdownIndex,
        dropdownLabel: dropdownLabel,
        dropdown2Index: dropdown2Index,
        dropdown2Label: dropdown2Label,
        dropdown3Index: dropdown3Index,
        dropdown3Label: dropdown3Label,
        summaryIndexes: summaryIndexes,
        useOriginalTransaction: useOriginalTransaction,
      );
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
  final String? dropdownLabel;
  final int? dropdown2Index;
  final String? dropdown2Label;
  final int? dropdown3Index;
  final String? dropdown3Label;
  final List<int> summaryIndexes;
  final bool useOriginalTransaction;
  final bool useAbsoluteNumbers;

  const _DateFilterDialog({
    required this.width,
    required this.height,
    required this.titleList,
    required this.dataList,
    this.title,
    this.dateIndex,
    this.dropdownIndex,
    this.dropdownLabel,
    this.dropdown2Index,
    this.dropdown2Label,
    this.dropdown3Index,
    this.dropdown3Label,
    required this.summaryIndexes,
    required this.useOriginalTransaction,
    // ignore: unused_element_parameter
    this.useAbsoluteNumbers = false,
  });

  @override
  __DateFilterDialogState createState() => __DateFilterDialogState();
}

class __DateFilterDialogState extends State<_DateFilterDialog> {
  DateTime? startDate;
  DateTime? endDate;
  List<String> selectedDropdownValues = []; // items selected by user
  List<String> selectedDropdown2Values = []; // items selected by user
  List<String> selectedDropdown3Values = []; // items selected by user
  List<List<dynamic>> filteredList = [];
  List<String> dropdownValues = []; // items to be shown in the dropdown list (to select from)
  List<String> dropdown2Values = []; // items to be shown in the dropdown list (to select from)
  List<String> dropdown3Values = []; // items to be shown in the dropdown list (to select from)

// this function detects which fields needs more width, the remaining width will be evenly distributed among
// all other fields (except sequence which has fixed width)
  void _setFieldsSizes() {
    List<List<dynamic>> dataListCopy = [...widget.dataList];
    if (widget.useOriginalTransaction && dataListCopy.isNotEmpty) {
      dataListCopy = removeIndicesFromInnerLists(dataListCopy, [0]);
    }
    // first we need to clear previous values from other reports
    isWideField = [];
    // first we assume all cells are normal size
    for (var _ in widget.titleList) {
      isWideField.add(false);
    }

    for (List item in dataListCopy) {
      for (var i = 0; i < item.length; i++) {
        if (item[i] is String && item[i].length > minStringLengthForLargeField) {
          isWideField[i] = true;
        }
      }
    }
    // I don't want to increase the size of notes fields
    for (var i = 0; i < widget.titleList.length; i++) {
      if (widget.titleList[i].contains('ملاحظات') || widget.titleList[i].contains('notes')) {
        isWideField[i] = false;
      }
    }
  }

  @override
  void initState() {
    if (widget.dateIndex != null) {
      sortListOfListsByDate(widget.dataList, widget.dateIndex!, isAscending: true);
    }
    super.initState();
    if (widget.dropdownIndex != null) {
      dropdownValues = widget.dataList
          .map((item) => item[widget.dropdownIndex!].toString()) // Map to the value at index 1
          .toSet() // Convert to a Set to ensure uniqueness
          .toList(); // Convert back to a List<String>
    }
    if (widget.dropdown2Index != null) {
      dropdown2Values = widget.dataList
          .map((item) => item[widget.dropdown2Index!].toString()) // Map to the value at index 1
          .toSet() // Convert to a Set to ensure uniqueness
          .toList(); // Convert back to a List<String>
    }
    if (widget.dropdown3Index != null) {
      dropdown3Values = widget.dataList
          .map((item) => item[widget.dropdown3Index!].toString()) // Map to the value at index 1
          .toSet() // Convert to a Set to ensure uniqueness
          .toList(); // Convert back to a List<String>
    }

    filteredList = List.from(widget.dataList);
    // give approperiate width for the fields
    _setFieldsSizes();
  }

  @override
  Widget build(BuildContext context) {
    // calculate the totals for each required colomn
    final summaryList = getSummaryList();
    return AlertDialog(
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.title != null) _buildTitle(),
            VerticalGap.xl,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (widget.dateIndex != null) Expanded(child: _buildDateSelectionRow()),
                if (widget.dropdownIndex != null) HorizontalGap.xl,
                if (widget.dropdownIndex != null) Expanded(child: _buildMultiSelectDropdown()),
                if (widget.dropdown2Index != null) HorizontalGap.xl,
                if (widget.dropdown2Index != null) Expanded(child: _buildMultiSelectDropdown2()),
                if (widget.dropdown3Index != null) HorizontalGap.xl,
                if (widget.dropdown3Index != null) Expanded(child: _buildMultiSelectDropdown3()),
              ],
            )
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildListTitles(),
            _buildDataList(context),
            _buildSummary(summaryList),
          ],
        ),
      ),
      actions: _buildButtons(
          filteredList, widget.title, widget.titleList, startDate, endDate, summaryList),
    );
  }

  void _filterData() {
    List<List<dynamic>> newList = widget.dataList;
    // first filter on data (if not null)
    if (widget.dateIndex != null) {
      newList = newList.where((list) {
        if (list.length > widget.dateIndex!) {
          DateTime date;
          try {
            date = DateTime.parse(list[widget.dateIndex!].toString());
          } catch (e) {
            return false;
          }
          bool dateInRange = (startDate == null || !date.isBefore(startDate!)) &&
              (endDate == null || !date.isAfter(endDate!.add(const Duration(days: 1))));
          return dateInRange;
        }
        return false;
      }).toList();
    }
    // filter the result of previous filter using first dropdown selection (if not null)
    if (widget.dropdownIndex != null) {
      newList = newList.where((list) {
        String cellValue = list[widget.dropdownIndex!].toString();
        bool test = selectedDropdownValues.isEmpty || selectedDropdownValues.contains(cellValue);
        return test;
      }).toList();
    }
    // filter the result of previous filter using first dropdown2 selection (if not null)
    if (widget.dropdown2Index != null) {
      newList = newList.where((list) {
        String cellValue = list[widget.dropdown2Index!].toString();
        bool test = selectedDropdown2Values.isEmpty || selectedDropdown2Values.contains(cellValue);
        return test;
      }).toList();
    }
    // filter the result of previous filter using first dropdown3 selection (if not null)
    if (widget.dropdown3Index != null) {
      newList = newList.where((list) {
        String cellValue = list[widget.dropdown3Index!].toString();
        bool test = selectedDropdown3Values.isEmpty || selectedDropdown3Values.contains(cellValue);
        return test;
      }).toList();
    }

    setState(() {
      filteredList = [...newList];
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
      dialogHeight: dropdownValues.length * 60,
      dialogWidth: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey), // Border color
        borderRadius: BorderRadius.circular(4.0), // Rounded corners
      ),
      confirmText: Text(S.of(context).select),
      cancelText: Text(S.of(context).cancel),
      items: dropdownValues.map((String value) => MultiSelectItem<String>(value, value)).toList(),
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

  Widget _buildMultiSelectDropdown2() {
    return MultiSelectDialogField(
      separateSelectedItems: false,
      dialogHeight: dropdown2Values.length * 60,
      dialogWidth: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey), // Border color
        borderRadius: BorderRadius.circular(4.0), // Rounded corners
      ),
      confirmText: Text(S.of(context).select),
      cancelText: Text(S.of(context).cancel),
      items: dropdown2Values.map((String value) => MultiSelectItem<String>(value, value)).toList(),
      title: Text(widget.dropdown2Label ?? ''),
      buttonText: Text(
        widget.dropdown2Label ?? '',
        style: const TextStyle(color: Colors.black26, fontSize: 15),
      ),
      onConfirm: (List<String> values) {
        setState(() {
          selectedDropdown2Values = values;
        });
        _filterData();
      },
      initialValue: selectedDropdown2Values,
      searchable: true,
    );
  }

  Widget _buildMultiSelectDropdown3() {
    return MultiSelectDialogField(
      separateSelectedItems: false,
      dialogHeight: dropdown3Values.length * 60,
      dialogWidth: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey), // Border color
        borderRadius: BorderRadius.circular(4.0), // Rounded corners
      ),
      confirmText: Text(S.of(context).select),
      cancelText: Text(S.of(context).cancel),
      items: dropdown3Values.map((String value) => MultiSelectItem<String>(value, value)).toList(),
      title: Text(widget.dropdown3Label ?? ''),
      buttonText: Text(
        widget.dropdown3Label ?? '',
        style: const TextStyle(color: Colors.black26, fontSize: 15),
      ),
      onConfirm: (List<String> values) {
        setState(() {
          selectedDropdown3Values = values;
        });
        _filterData();
      },
      initialValue: selectedDropdown3Values,
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
        format: DateFormat('dd-MM-yyyy', 'en_US'),
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
    List<Widget> listTitleWidgets = [];
    // place holder for sequence
    listTitleWidgets.add(const SizedBox(width: 40, child: Text('')));
    for (var i = 0; i < widget.titleList.length; i++) {
      late Widget summaryWidget;
      final item = widget.titleList[i];
      if (isWideField[i]) {
        summaryWidget = SizedBox(
          width: wideFieldWidth,
          child: Text(item,
              style:
                  const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center),
        );
      } else {
        summaryWidget = Expanded(
          child: Text(item,
              style:
                  const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center),
        );
      }
      listTitleWidgets.add(summaryWidget);
    }

    return _buildRowContrainer(
      Row(children: listTitleWidgets),
    );
  }

  Widget _buildDataList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      width: widget.width,
      height: widget.height * 0.5, // Set a fixed height for the list
      child: ListView.builder(
        itemCount: filteredList.length,
        // separatorBuilder: (context, index) => const Divider(thickness: 0.5, color: Colors.grey),
        itemBuilder: (context, index) {
          final data = filteredList[index];
          Widget displayedWidget = widget.useOriginalTransaction
              ? InkWell(
                  child: _buildDataRow(context, data, index),
                  onTap: () {
                    if (widget.useOriginalTransaction) {
                      // if useOriginalTransaction the, first item is alway the orginal transaction
                      showReadOnlyTransaction(context, data[0]);
                    }
                  },
                )
              : _buildDataRow(context, data, index);
          return displayedWidget;
        },
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, List<dynamic> data, int index) {
    // if useOriginalTransaction is true, it means first item is Transaction
    // we don't want to display it, we want to used it as a button that show
    // a read only transaction dialog
    final itemsToDisplay = widget.useOriginalTransaction
        ? data.sublist(1, data.length) // Exclude the last item
        : data;
    // I want to highlight rows that represent a receipt with red text color
    bool isHilighted = false;
    for (var cell in data) {
      if (cell is String &&
          (cell.contains(S.of(context).transaction_type_customer_receipt) ||
              cell.contains(S.of(context).transaction_type_customer_return))) {
        isHilighted = true;
        break;
      }
    }

    final itemWidgetList = [];
    for (var i = 0; i < itemsToDisplay.length; i++) {
      dynamic item = itemsToDisplay[i];
      late Widget itemWidget;
      if (item is DateTime) item = formatDate(item);
      if (isWideField[i]) {
        itemWidget = Container(
          decoration: BoxDecoration(border: Border.all(width: 0.2)),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          width: wideFieldWidth,
          child: Text(
              item is String
                  ? item
                  : doubleToStringWithComma(item, isAbsoluteValue: widget.useAbsoluteNumbers),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isHilighted ? Colors.red : Colors.black,
                  fontSize: 16)),
        );
      } else {
        itemWidget = Expanded(
          child: Container(
            decoration: BoxDecoration(border: Border.all(width: 0.2)),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Text(
                item is String
                    ? item
                    : doubleToStringWithComma(item, isAbsoluteValue: widget.useAbsoluteNumbers),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isHilighted ? Colors.red : Colors.black,
                    fontSize: 16)),
          ),
        );
      }
      itemWidgetList.add(itemWidget);
    }

    // sequence should be separated from data, because I want its width to be fixed and small
    Widget sequence = Container(
      decoration: BoxDecoration(border: Border.all(width: 0.2)),
      width: 45,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Text((index + 1).toString(),
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHilighted ? Colors.red : Colors.black,
              fontSize: 16)),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [sequence, ...itemWidgetList],
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
        padding: const EdgeInsets.all(2),
        width: 300,
        child:
            Text(textAlign: TextAlign.center, widget.title!, style: const TextStyle(fontSize: 20)));
  }

  List<String> getSummaryList() {
    // in case no items in the list, return empty list
    if (filteredList.isEmpty) return [];
    // we make sure to remove the transaction object if exists
    List<List<dynamic>> filteredListCopy = [...filteredList];
    if (widget.useOriginalTransaction) {
      filteredListCopy = removeIndicesFromInnerLists(filteredListCopy, [0]);
    }
    List<String> summaryList = List.generate(filteredListCopy[0].length, (_) => '');
    // if not index provided form sum, we will return the count
    if (widget.summaryIndexes.isEmpty) {
      summaryList[0] = S.of(context).count;
      final itemsCount = filteredListCopy.length.toString();
      summaryList[filteredListCopy[0].length - 1] = doubleToStringWithComma(itemsCount);
    } else {
      summaryList[0] = S.of(context).total;
      for (var index in widget.summaryIndexes) {
        num sum = 0;
        for (var dataRow in filteredListCopy) {
          if (index < 0 ||
              index >= dataRow.length ||
              (dataRow[index] is! int && dataRow[index] is! double && dataRow[index] is! num)) {
            errorPrint('index provided is not suitable for the data list');
            break;
          }
          sum += (dataRow[index] ?? 0) as num;
        }
        summaryList[index] = doubleToStringWithComma(sum);
      }
    }
    return summaryList;
  }

  Widget _buildSummary(List<String> summaryList) {
    List<Widget> summaryWidgets = [];
    // place holder for sequence
    summaryWidgets.add(const SizedBox(width: 40, child: Text('')));
    for (var i = 0; i < summaryList.length; i++) {
      late Widget summaryWidget;
      if (isWideField[i]) {
        summaryWidget = SizedBox(
          width: wideFieldWidth,
          child: Text(summaryList[i],
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        );
      } else {
        summaryWidget = Expanded(
          child: Text(summaryList[i],
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        );
      }
      summaryWidgets.add(summaryWidget);
    }
    return _buildRowContrainer(
      Row(children: summaryWidgets),
    );
  }

  List<Widget> _buildButtons(List<List<dynamic>> reportData, String? reportTitle,
      List<String> listTitles, DateTime? startDate, DateTime? endDate, List<String> summaryList) {
    final startDateString = startDate != null ? formatDate(startDate) : null;
    final endDateString = endDate != null ? formatDate(endDate) : null;
    return <Widget>[
      Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrintReportButton(
                reportData,
                reportTitle ?? '',
                listTitles,
                startDateString,
                endDateString,
                summaryList,
                widget.useOriginalTransaction,
                selectedDropdownValues.isEmpty
                    ? []
                    : [...selectedDropdownValues, '${widget.dropdownLabel}:'],
                selectedDropdown2Values.isEmpty
                    ? []
                    : [...selectedDropdown2Values, '${widget.dropdown2Label}:'],
                selectedDropdown3Values.isEmpty
                    ? []
                    : [...selectedDropdown3Values, '${widget.dropdown3Label}:']),
            HorizontalGap.m,
            WhatsappReportButton(
                reportData,
                reportTitle ?? '',
                listTitles,
                startDateString,
                endDateString,
                summaryList,
                widget.useOriginalTransaction,
                selectedDropdownValues.isEmpty
                    ? []
                    : [...selectedDropdownValues, '${widget.dropdownLabel}:'],
                selectedDropdown2Values.isEmpty
                    ? []
                    : [...selectedDropdown2Values, '${widget.dropdown2Label}:'],
                selectedDropdown3Values.isEmpty
                    ? []
                    : [...selectedDropdown3Values, '${widget.dropdown3Label}:']),
          ],
        ),
      ),
    ];
  }

  Widget _buildRowContrainer(Widget childWidget) {
    return Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 227, 240, 247),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300)),
        child: childWidget);
  }
}

void launchWhatsAppWeb() async {
  // Replace with the actual phone number (including country code, but without +)
  const String url = 'https://web.whatsapp.com/';

  try {
    // Launch WhatsApp Web with the specific chat
    await launchUrlString(url);
  } catch (e) {
    errorPrint('Error launching WhatsApp Web: $e');
  }
}

Future<void> createPdfWhatsapp(
  BuildContext context,
  WidgetRef ref,
  List<List<dynamic>> reportData,
  String title, // report tiltle
  List<String> listTitles,
  String? startDate,
  String? endDate,
  List<String> summaryList,
  List<String> filter1Values, // value selected in filter 1
  List<String> filter2Values, // value selected in filter 2
  List<String> filter3Values, // value selected in filter 3
) async {
  try {
    final image = await loadImage('assets/images/invoice_logo.PNG');
    final filePath = gePdfpath('test_file');
    if (context.mounted) {
      final pdf = await getReportPdf(
        context,
        ref,
        reportData,
        image,
        title,
        listTitles,
        startDate,
        endDate,
        summaryList,
        filter1Values,
        filter2Values,
        filter3Values,
      );
      if (filePath == null) return;
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      launchWhatsAppWeb();
    }
  } catch (e) {
    debugLog('Pdf creation failed - ($e)');
  }
}

class PrintReportButton extends ConsumerWidget {
  const PrintReportButton(
      this.reportData,
      this.reportTitle,
      this.listTitles,
      this.startDate,
      this.endDate,
      this.summaryList,
      this.useOriginalTransaction,
      this.filter1SelectedValues,
      this.filter2SelectedValues,
      this.filter3SelectedValues,
      {super.key});

  final List<List<dynamic>> reportData;
  final String reportTitle;
  final String? startDate;
  final String? endDate;
  final List<String> listTitles;
  final List<String> summaryList;
  final bool useOriginalTransaction;
  final List<String> filter1SelectedValues;
  final List<String> filter2SelectedValues;
  final List<String> filter3SelectedValues;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //if transaction is included, then we don't print it because it is only intended to show original transaction
    List<List<dynamic>> printingData = [...reportData];
    if (useOriginalTransaction) {
      printingData = removeIndicesFromInnerLists(reportData, [0]);
    }

    return IconButton(
      icon: const PrintIcon(),
      onPressed: () {
        printReport(context, ref, printingData, reportTitle, listTitles, startDate, endDate,
            summaryList, filter1SelectedValues, filter2SelectedValues, filter3SelectedValues);
      },
    );
  }
}

class WhatsappReportButton extends ConsumerWidget {
  const WhatsappReportButton(
      this.reportData,
      this.reportTitle,
      this.listTitles,
      this.startDate,
      this.endDate,
      this.summaryList,
      this.useOriginalTransaction,
      this.filter1SelectedValues,
      this.filter2SelectedValues,
      this.filter3SelectedValues,
      {super.key});

  final List<List<dynamic>> reportData;
  final String reportTitle;
  final String? startDate;
  final String? endDate;
  final List<String> listTitles;
  final List<String> summaryList;
  final bool useOriginalTransaction;
  final List<String> filter1SelectedValues;
  final List<String> filter2SelectedValues;
  final List<String> filter3SelectedValues;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //if transaction is included, then we don't print it because it is only intended to show original transaction
    List<List<dynamic>> printingData = [...reportData];
    if (useOriginalTransaction) {
      printingData = removeIndicesFromInnerLists(reportData, [0]);
    }

    return IconButton(
      icon: const ShareIcon(),
      onPressed: () {
        createPdfWhatsapp(context, ref, printingData, reportTitle, listTitles, startDate, endDate,
            summaryList, filter1SelectedValues, filter2SelectedValues, filter3SelectedValues);
      },
    );
  }
}
