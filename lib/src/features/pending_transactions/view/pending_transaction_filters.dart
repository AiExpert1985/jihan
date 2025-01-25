import 'package:anydrawer/anydrawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/screen_data_filters.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/search_form.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_filter_controller.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_screen_controller.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_screen_data_notifier.dart';

class PendingTransactionSearchForm extends ConsumerWidget {
  const PendingTransactionSearchForm(this._drawerController, {super.key});

  final AnyDrawerController _drawerController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterController = ref.read(pendingTransactionFilterController);
    final screenDataController = ref.read(pendingTransactionScreenControllerProvider);
    final screenDataNotifier = ref.read(pendingTransactionScreenDataNotifier.notifier);
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
          filterController, 'typeContains', 'transactionType', S.of(context).transaction_type),
      VerticalGap.l,
      TextSearchField(filterController, 'nameContains', 'name', S.of(context).transaction_name),
      VerticalGap.l,
      TextSearchField(
          filterController, 'salesmanContains', 'salesman', S.of(context).transaction_salesman),
      VerticalGap.l,
      NumberMatchSearchField(
          filterController, 'numberEquals', 'number', S.of(context).transaction_number),
      VerticalGap.l,
      NumberRangeSearchField(filterController, 'amountMoreThanOrEqual', 'amountLessThanOrEqual',
          'totalAmount', S.of(context).transaction_amount),
      VerticalGap.l,
      TextSearchField(filterController, 'notesContains', 'notes', S.of(context).transaction_notes),
      VerticalGap.xl,
      DateRangeSearchField(filterController, 'dateAfter', 'dateBefore', 'date')
    ];
  }
}
