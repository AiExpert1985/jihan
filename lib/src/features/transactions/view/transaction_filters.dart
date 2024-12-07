import 'package:anydrawer/anydrawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/screen_data_filters.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/search_form.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_filter_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_data_notifier.dart';

class TransactionSearchForm extends ConsumerWidget {
  const TransactionSearchForm(this._drawerController, {super.key});

  final AnyDrawerController _drawerController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterController = ref.read(transactionFilterController);
    final screenDataController = ref.read(transactionScreenControllerProvider);
    final screenDataNotifier = ref.read(transactionScreenDataNotifier.notifier);
    final bodyWidgets = _buildBodyWidgets(filterController, context);
    final title = S.of(context).transaction_search;
    return SearchForm(
      title,
      _drawerController,
      filterController,
      screenDataController,
      screenDataNotifier,
      bodyWidgets,
    );
  }

  List<Widget> _buildBodyWidgets(ScreenDataFilters filterController, BuildContext context) {
    return [
      TextSearchField(
          filterController, 'typeContains', transactionTypeKey, S.of(context).transaction_type),
      VerticalGap.l,
      TextSearchField(
          filterController, 'nameContains', transactionNameKey, S.of(context).transaction_name),
      VerticalGap.l,
      TextSearchField(filterController, 'salesmanContains', transactionSalesmanKey,
          S.of(context).transaction_salesman),
      VerticalGap.l,
      NumberMatchSearchField(
          filterController, 'numberEquals', transactionNameKey, S.of(context).transaction_number),
      VerticalGap.l,
      NumberRangeSearchField(filterController, 'amountMoreThanOrEqual', 'amountLessThanOrEqual',
          transactionTotalAmountKey, S.of(context).transaction_amount),
      VerticalGap.l,
      TextSearchField(
          filterController, 'notesContains', transactionNotesKey, S.of(context).transaction_notes),
      VerticalGap.xl,
      DateRangeSearchField(filterController, 'dateAfter', 'dateBefore', transactionDateKey)
    ];
  }
}
