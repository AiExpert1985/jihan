import 'package:anydrawer/anydrawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/screen_data_filters.dart';
import 'package:tablets/src/common/widgets/search_form.dart';
import 'package:tablets/src/features/categories/controllers/category_filter_controller.dart';
import 'package:tablets/src/features/categories/controllers/category_screen_controller.dart';
import 'package:tablets/src/features/categories/controllers/category_screen_data_notifier.dart';

class CategorySearchForm extends ConsumerWidget {
  const CategorySearchForm(this._drawerController, {super.key});

  final AnyDrawerController _drawerController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterController = ref.read(categoryFilterController);
    final screenDataController = ref.read(categoryScreenControllerProvider);
    final screenDataNotifier = ref.read(categoryScreenDataNotifier.notifier);
    final bodyWidgets = _buildBodyWidgets(filterController, context);
    final title = S.of(context).category_search;
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
      TextSearchField(filterController, 'nameContains', categoryNameKey, S.of(context).category),
    ];
  }
}
