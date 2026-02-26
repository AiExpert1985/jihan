import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/widgets/empty_screen.dart';
import 'package:tablets/src/common/widgets/page_loading.dart';
import 'package:tablets/src/features/categories/controllers/category_drawer_provider.dart';
import 'package:tablets/src/features/home/view/home_screen.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/widgets/image_titled.dart';
import 'package:tablets/src/features/categories/controllers/category_form_controller.dart';
import 'package:tablets/src/features/categories/controllers/category_screen_controller.dart';
import 'package:tablets/src/features/categories/controllers/category_screen_data_notifier.dart';
import 'package:tablets/src/features/categories/model/category.dart';
import 'package:tablets/src/features/categories/repository/category_db_cache_provider.dart';
import 'package:tablets/src/features/categories/repository/category_repository_provider.dart';
import 'package:tablets/src/features/categories/view/category_form.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tablets/src/features/settings/repository/settings_db_cache_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoryScreenDataNotifier);
    final settingsDataNotifier = ref.read(settingsDbCacheProvider.notifier);
    final settingsData = settingsDataNotifier.data;
    // if settings data is empty it means user has refresh the web page &
    // didn't reach the page through pressing the page button
    // in this case he didn't load required dbCaches so, I should hide buttons because
    // using them might cause bugs in the program
    Widget screenWidget = settingsData.isEmpty
        ? const HomeScreen()
        : const AppScreenFrame(
            CategoriesGrid(),
            buttonsWidget: CategoryFloatingButtons(),
          );
    return screenWidget;
  }
}

class CategoriesGrid extends ConsumerWidget {
  const CategoriesGrid({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoryScreenDataNotifier);
    ref.watch(pageIsLoadingNotifier);
    final dbCache = ref.read(categoryDbCacheProvider.notifier);
    final dbData = dbCache.data;
    final pageIsLoading = ref.read(pageIsLoadingNotifier);
    if (pageIsLoading) {
      return const PageLoading();
    }
    Widget screenWidget = dbData.isNotEmpty ? const GridData() : const EmptyPage();
    return screenWidget;
  }
}

class GridData extends ConsumerWidget {
  const GridData({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenDataNotifier = ref.read(categoryScreenDataNotifier.notifier);
    final screenData = screenDataNotifier.data;
    ref.watch(categoryScreenDataNotifier);
    return GridView.builder(
      itemCount: screenData.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (ctx, index) {
        final categoryScreenData = screenData[index];
        final categoryRef = categoryScreenData[categoryDbRefKey];
        final categoryDbCache = ref.read(categoryDbCacheProvider.notifier);
        final categoryData = categoryDbCache.getItemByDbRef(categoryRef);
        final category = ProductCategory.fromMap(categoryData);
        return InkWell(
          hoverColor: const Color.fromARGB(255, 173, 170, 170),
          onTap: () => _showEditCategoryForm(ctx, ref, category),
          child: TitledImage(
            imageUrl: category.coverImageUrl,
            title: category.name,
          ),
        );
      },
    );
  }
}

void _showEditCategoryForm(BuildContext context, WidgetRef ref, ProductCategory category) {
  ref.read(categoryFormDataProvider.notifier).initialize(initialData: category.toMap());
  final imagePicker = ref.read(imagePickerProvider.notifier);
  imagePicker.initialize(urls: category.imageUrls);
  showDialog(
    context: context,
    builder: (BuildContext ctx) => const CategoryForm(isEditMode: true),
  ).whenComplete(imagePicker.close);
}

class CategoryFloatingButtons extends ConsumerWidget {
  const CategoryFloatingButtons({super.key});

  void _showAddCategoryForm(BuildContext context, WidgetRef ref) {
    ref.read(categoryFormDataProvider.notifier).initialize();
    final imagePicker = ref.read(imagePickerProvider.notifier);
    imagePicker.initialize();
    showDialog(
      context: context,
      builder: (BuildContext ctx) => const CategoryForm(),
    ).whenComplete(imagePicker.close);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerController = ref.watch(categoryDrawerControllerProvider);
    const iconsColor = Color.fromARGB(255, 126, 106, 211);
    return SpeedDial(
      direction: SpeedDialDirection.up,
      switchLabelPosition: false,
      animatedIcon: AnimatedIcons.menu_close,
      spaceBetweenChildren: 10,
      animatedIconTheme: const IconThemeData(size: 28.0),
      visible: true,
      curve: Curves.bounceInOut,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.refresh, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () async {
            ref.read(pageIsLoadingNotifier.notifier).state = true;
            final newData = await ref.read(categoryRepositoryProvider).fetchItemListAsMaps();
            ref.read(categoryDbCacheProvider.notifier).set(newData);
            if (context.mounted) {
              ref.read(categoryScreenControllerProvider).setFeatureScreenData(context);
            }
            ref.read(pageIsLoadingNotifier.notifier).state = false;
          },
        ),
        // SpeedDialChild(
        //   child: const Icon(Icons.pie_chart, color: Colors.white),
        //   backgroundColor: iconsColor,
        //   onTap: () => drawerController.showReports(context),
        // ),
        SpeedDialChild(
          child: const Icon(Icons.search, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () => drawerController.showSearchForm(context),
        ),
        SpeedDialChild(
          child: const Icon(Icons.add, color: Colors.white),
          backgroundColor: iconsColor,
          onTap: () => _showAddCategoryForm(context, ref),
        ),
      ],
    );
  }
}
