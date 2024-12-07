import 'package:anydrawer/anydrawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/screen_data_filters.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/search_form.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_filter_controller.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_screen_controller.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_screen_data_notifier.dart';

class SalesmanSearchForm extends ConsumerWidget {
  const SalesmanSearchForm(this._drawerController, {super.key});

  final AnyDrawerController _drawerController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterController = ref.read(salesmanFilterController);
    final screenDataController = ref.read(salesmanScreenControllerProvider);
    final screenDataNotifier = ref.read(salesmanScreenDataNotifier.notifier);
    final bodyWidgets = _buildBodyWidgets(filterController, context);
    final title = S.of(context).salesman_search;
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
          filterController, 'nameContains', salesmanNameKey, S.of(context).salesman_name),
      VerticalGap.m,
      NumberRangeSearchField(filterController, 'commissionMoreThanOrEqual',
          'commissionLessThanOrEqual', commissionKey, S.of(context).commission),
      VerticalGap.m,
      NumberRangeSearchField(filterController, 'customersMoreThanOrEqual',
          'customersLessThanOrEqual', customersKey, S.of(context).customers),
      VerticalGap.m,
      NumberRangeSearchField(filterController, 'totalDebtsMoreThanOrEqual',
          'totalDebtsLessThanOrEqual', totalDebtsKey, S.of(context).current_debt),
      VerticalGap.m,
      NumberRangeSearchField(filterController, 'openInvoicesMoreThanOrEqual',
          'openInvoicesLessThanOrEqual', openInvoicesKey, S.of(context).open_invoices),
      VerticalGap.m,
      NumberRangeSearchField(filterController, 'receiptsMoreThanOrEqual', 'receiptsLessThanOrEqual',
          numReceiptsKey, S.of(context).receipts_number),
      VerticalGap.m,
      NumberRangeSearchField(filterController, 'receiptsAmountMoreThanOrEqual',
          'receiptsAmountLessThanOrEqual', receiptsAmountKey, S.of(context).receipt_amount),
      VerticalGap.m,
      NumberRangeSearchField(filterController, 'invoicesMoreThanOrEqual', 'invoicesLessThanOrEqual',
          numInvoicesKey, S.of(context).invoices_number),
      VerticalGap.m,
      NumberRangeSearchField(filterController, 'invoicesAmountMoreThanOrEqual',
          'invoicesAmountLessThanOrEqual', invoicesAmountKey, S.of(context).invoices_amount),
      VerticalGap.m,
      NumberRangeSearchField(filterController, 'returnsMoreThanOrEqual', 'returnsLessThanOrEqual',
          numReturnsKey, S.of(context).returns_number),
      VerticalGap.l,
      NumberRangeSearchField(filterController, 'returnsAmountMoreThanOrEqual',
          'returnsAmountLessThanOrEqual', returnsAmountKey, S.of(context).returns_amount),
      VerticalGap.m,
      NumberRangeSearchField(filterController, 'profitMoreThanOrEqual',
          'profitAmountLessThanOrEqual', profitKey, S.of(context).profits),
      VerticalGap.m,
    ];
  }
}
