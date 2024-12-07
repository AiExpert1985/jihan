import 'package:anydrawer/anydrawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/screen_data_filters.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/search_form.dart';
import 'package:tablets/src/features/vendors/controllers/vendor_filter_controller.dart';
import 'package:tablets/src/features/vendors/controllers/vendor_screen_controller.dart';
import 'package:tablets/src/features/vendors/controllers/vendor_screen_data_notifier.dart';

class VendorSearchForm extends ConsumerWidget {
  const VendorSearchForm(this._drawerController, {super.key});

  final AnyDrawerController _drawerController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterController = ref.read(vendorFilterController);
    final screenDataController = ref.read(vendorScreenControllerProvider);
    final screenDataNotifier = ref.read(vendorScreenDataNotifier.notifier);
    final bodyWidgets = _buildBodyWidgets(filterController, context);
    final title = S.of(context).vendor_search;
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
      TextSearchField(filterController, 'nameContains', vendorNameKey, S.of(context).name),
      VerticalGap.xl,
      TextSearchField(filterController, 'phoneContains', vendorPhoneKey, S.of(context).phone),
      VerticalGap.xl,
      NumberRangeSearchField(filterController, 'debtThanOrEqual', 'debtLessThanOrEqual',
          vendorTotalDebtKey, S.of(context).debts),
    ];
  }
}
