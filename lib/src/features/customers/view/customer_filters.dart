import 'package:anydrawer/anydrawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/screen_data_filters.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/search_form.dart';
import 'package:tablets/src/features/customers/controllers/customer_filter_controller.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_controller.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_data_notifier.dart';

class CustomerSearchForm extends ConsumerWidget {
  const CustomerSearchForm(this._drawerController, {super.key});

  final AnyDrawerController _drawerController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterController = ref.read(customerFilterController);
    final screenDataController = ref.read(customerScreenControllerProvider);
    final screenDataNotifier = ref.read(customerScreenDataNotifier.notifier);
    final bodyWidgets = _buildBodyWidgets(filterController, context);
    final title = S.of(context).customer_search;
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
      TextSearchField(filterController, 'nameContains', customerNameKey, S.of(context).customer),
      VerticalGap.l,
      TextSearchField(filterController, 'salesmanContains', customerSalesmanKey,
          S.of(context).salesman_selection),
      VerticalGap.l,
      NumberRangeSearchField(filterController, 'totalDebtMoreThanOrEqual',
          'totalDebtLessThanOrEqual', totalDebtKey, S.of(context).current_debt),
      VerticalGap.l,
      NumberRangeSearchField(filterController, 'openInvoicesMoreThanOrEqual',
          'openInvoicesLessThanOrEqual', openInvoicesKey, S.of(context).open_invoices),
      VerticalGap.l,
      NumberRangeSearchField(filterController, 'dueDebtMoreThanOrEqual', 'dueDebtLessThanOrEqual',
          dueDebtKey, S.of(context).due_debt_amount),
      VerticalGap.l,
      NumberRangeSearchField(filterController, 'closingDaysMoreThanOrEqual',
          'closingDaysLessThanOrEqual', avgClosingDaysKey, S.of(context).invoice_close_duration),
      VerticalGap.l,
      NumberRangeSearchField(filterController, 'profitMoreThanOrEqual', 'pofitLessThanOrEqual',
          invoicesProfitKey, S.of(context).invoice_profit),
      VerticalGap.l,
      NumberRangeSearchField(filterController, 'giftsMoreThanOrEqual', 'giftsLessThanOrEqual',
          giftsKey, S.of(context).customer_gifts_and_discounts),
      VerticalGap.l,
    ];
  }
}
