import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/widgets/empty_screen.dart';
import 'package:tablets/src/common/widgets/page_loading.dart';
import 'package:tablets/src/features/home/view/home_screen.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/widgets/image_titled.dart';
import 'package:tablets/src/features/regions/controllers/region_drawer_provider.dart';
import 'package:tablets/src/features/regions/controllers/region_form_controller.dart';
import 'package:tablets/src/features/regions/controllers/region_screen_controller.dart';
import 'package:tablets/src/features/regions/controllers/region_screen_data_notifier.dart';
import 'package:tablets/src/features/regions/model/region.dart';
import 'package:tablets/src/features/regions/repository/region_db_cache_provider.dart';
import 'package:tablets/src/features/regions/repository/region_repository_provider.dart';
import 'package:tablets/src/features/regions/view/region_form.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tablets/src/features/settings/repository/settings_db_cache_provider.dart';

class RegionsScreen extends ConsumerWidget {
  const RegionsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(regionScreenDataNotifier);
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
            buttonsWidget: RegionFloatingButtons(),
          );
    return screenWidget;
  }
}

class CategoriesGrid extends ConsumerWidget {
  const CategoriesGrid({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(regionScreenDataNotifier);
    ref.watch(pageIsLoadingNotifier);
    final dbCache = ref.read(regionDbCacheProvider.notifier);
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
    final screenDataNotifier = ref.read(regionScreenDataNotifier.notifier);
    final screenData = screenDataNotifier.data;
    ref.watch(regionScreenDataNotifier);
    return GridView.builder(
      itemCount: screenData.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (ctx, index) {
        final regionScreenData = screenData[index];
        final regionRef = regionScreenData[regionDbRefKey];
        final regionDbCache = ref.read(regionDbCacheProvider.notifier);
        final customerData = regionDbCache.getItemByDbRef(regionRef);
        final region = Region.fromMap(customerData);
        return InkWell(
          hoverColor: const Color.fromARGB(255, 173, 170, 170),
          onTap: () => _showEditRegionForm(ctx, ref, region),
          child: TitledImage(
            imageUrl: region.coverImageUrl,
            title: region.name,
          ),
        );
      },
    );
  }
}

void _showEditRegionForm(BuildContext context, WidgetRef ref, Region region) {
  ref.read(regionFormDataProvider.notifier).initialize(initialData: region.toMap());
  final imagePicker = ref.read(imagePickerProvider.notifier);
  imagePicker.initialize(urls: region.imageUrls);
  showDialog(
    context: context,
    builder: (BuildContext ctx) => const RegionForm(isEditMode: true),
  ).whenComplete(imagePicker.close);
}

class RegionFloatingButtons extends ConsumerWidget {
  const RegionFloatingButtons({super.key});

  void _showAddRegionForm(BuildContext context, WidgetRef ref) {
    ref.read(regionFormDataProvider.notifier).initialize();
    final imagePicker = ref.read(imagePickerProvider.notifier);
    imagePicker.initialize();
    showDialog(
      context: context,
      builder: (BuildContext ctx) => const RegionForm(),
    ).whenComplete(imagePicker.close);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerController = ref.watch(regionDrawerControllerProvider);
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
            final newData = await ref.read(regionRepositoryProvider).fetchItemListAsMaps();
            ref.read(regionDbCacheProvider.notifier).set(newData);
            if (context.mounted) {
              ref.read(regionScreenControllerProvider).setFeatureScreenData(context);
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
          onTap: () => _showAddRegionForm(context, ref),
        ),
      ],
    );
  }
}
