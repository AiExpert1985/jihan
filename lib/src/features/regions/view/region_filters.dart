import 'package:anydrawer/anydrawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/screen_data_filters.dart';
import 'package:tablets/src/common/widgets/search_form.dart';
import 'package:tablets/src/features/regions/controllers/region_filter_controller.dart';
import 'package:tablets/src/features/regions/controllers/region_screen_controller.dart';
import 'package:tablets/src/features/regions/controllers/region_screen_data_notifier.dart';

class RegionSearchForm extends ConsumerWidget {
  const RegionSearchForm(this._drawerController, {super.key});

  final AnyDrawerController _drawerController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterController = ref.read(regionFilterController);
    final screenDataController = ref.read(regionScreenControllerProvider);
    final screenDataNotifier = ref.read(regionScreenDataNotifier.notifier);
    final bodyWidgets = _buildBodyWidgets(filterController, context);
    final title = S.of(context).region_search;
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
      TextSearchField(filterController, 'nameContains', regionNameKey, S.of(context).region),
    ];
  }
}
