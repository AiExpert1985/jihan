import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/database_backup.dart';
import 'package:tablets/src/common/functions/db_cache_inialization.dart';
import 'package:tablets/src/common/interfaces/screen_controller.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/providers/page_title_provider.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/features/categories/controllers/category_screen_controller.dart';
import 'package:tablets/src/features/categories/controllers/category_screen_data_notifier.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_controller.dart';
import 'package:tablets/src/features/products/controllers/product_screen_controller.dart';
import 'package:tablets/src/features/regions/controllers/region_screen_controller.dart';
import 'package:tablets/src/features/regions/controllers/region_screen_data_notifier.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_screen_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/src/features/vendors/controllers/vendor_screen_controller.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Drawer(
      width: 250,
      child: Column(
        children: [
          MainDrawerHeader(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  HomeButton(),
                  VerticalGap.m,
                  TransactionsButton(),
                  VerticalGap.m,
                  CustomersButton(),
                  VerticalGap.m,
                  VendorsButton(),
                  VerticalGap.m,
                  SalesmenButton(),
                  VerticalGap.m,
                  ProductsButton(),
                  VerticalGap.m,
                  SettingsButton(),
                  Spacer(),
                  PendingsButton(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

/// initialize all dbCaches and settings, and move on the the target page
void processAndMoveToTargetPage(BuildContext context, WidgetRef ref,
    ScreenDataController screenController, String route, String pageTitle) async {
  await autoDatabaseBackup(context, ref);
  final pageTitleNotifier = ref.read(pageTitleProvider.notifier);
  final pageLoadingNotifier = ref.read(pageIsLoadingNotifier.notifier);
  // page is loading only used to show a loading spinner (better user experience)
  // before loading initializing dbCaches and settings we show loading spinner &
  // when done it is cleared using below pageLoadingNotifier.state = false;
  pageLoadingNotifier.state = true;
  // note that dbCaches are only used for mirroring the database, all the data used in the
  // app in the screenData, which is a processed version of dbCache
  if (context.mounted) {
    await initializeAllDbCaches(context, ref);
  }
  // we inialize settings
  if (context.mounted) {
    initializeSettings(context, ref);
  }
  // load dbCache data into screenData, which will be used later for show data in the
  // page main screen, and also for search
  if (context.mounted) {
    screenController.setFeatureScreenData(context);
  }
  if (context.mounted) {
    pageTitleNotifier.state = pageTitle;
  }
  // after loading and processing data, we turn off the loading spinner
  pageLoadingNotifier.state = false;
  // close side drawer and move to the target page
  if (context.mounted) {
    Navigator.of(context).pop();
    context.goNamed(route);
  }
}

class HomeButton extends ConsumerWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageTitleNotifier = ref.read(pageTitleProvider.notifier);
    return MainDrawerButton('home', S.of(context).home_page, () async {
      await initializeAllDbCaches(context, ref);
      pageTitleNotifier.state = '';
      if (context.mounted) {
        context.goNamed(AppRoute.home.name);
      }
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      // uploadDefaultSettings(ref);
      // importCustomerExcel(ref);
      // importProductExcel(ref);
    });
  }
}

class CustomersButton extends ConsumerWidget {
  const CustomersButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerScreenController = ref.read(customerScreenControllerProvider);

    final route = AppRoute.customers.name;
    final pageTitle = S.of(context).customers;
    return MainDrawerButton(
        'customers',
        S.of(context).customers,
        () async =>
            processAndMoveToTargetPage(context, ref, customerScreenController, route, pageTitle));
  }
}

class PendingsButton extends ConsumerWidget {
  const PendingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageTitleNotifier = ref.read(pageTitleProvider.notifier);
    return MainDrawerButton(
      'pending_transactions',
      S.of(context).pending_transactions,
      () {
        if (context.mounted) {
          pageTitleNotifier.state = S.of(context).pending_transactions;
        }
        if (context.mounted) {
          context.goNamed(AppRoute.pendingTransactions.name);
        }
      },
    );
  }
}

class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MainDrawerButton(
      'settings',
      S.of(context).settings,
      () async {
        final pageLoadingNotifier = ref.read(pageIsLoadingNotifier.notifier);
        // page is loading only used to show a loading spinner (better user experience)
        // before loading initializing dbCaches and settings we show loading spinner &
        // when done it is cleared using below pageLoadingNotifier.state = false;
        pageLoadingNotifier.state = true;

        await initializeAllDbCaches(context, ref);
        if (context.mounted) {
          initializeSettings(context, ref);
        }
        pageLoadingNotifier.state = false;
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        if (context.mounted) {
          showDialog(context: context, builder: (BuildContext ctx) => const SettingsDialog());
        }
      },
    );
  }
}

class SalesmenButton extends ConsumerWidget {
  const SalesmenButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesmanScreenController = ref.read(salesmanScreenControllerProvider);
    final route = AppRoute.salesman.name;
    final pageTitle = S.of(context).salesmen;
    return MainDrawerButton(
        'salesman',
        S.of(context).salesmen,
        () async =>
            processAndMoveToTargetPage(context, ref, salesmanScreenController, route, pageTitle));
  }
}

class VendorsButton extends ConsumerWidget {
  const VendorsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorScreenController = ref.read(vendorScreenControllerProvider);
    final route = AppRoute.vendors.name;
    final pageTitle = S.of(context).vendors;
    return MainDrawerButton(
        'vendors',
        S.of(context).vendors,
        () async =>
            processAndMoveToTargetPage(context, ref, vendorScreenController, route, pageTitle));
  }
}

class TransactionsButton extends ConsumerWidget {
  const TransactionsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionScreenController = ref.read(transactionScreenControllerProvider);
    final route = AppRoute.transactions.name;
    final pageTitle = S.of(context).transactions;
    return MainDrawerButton(
        'transactions',
        S.of(context).transactions,
        () async => processAndMoveToTargetPage(
            context, ref, transactionScreenController, route, pageTitle));
  }
}

class ProductsButton extends ConsumerWidget {
  const ProductsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productScreenController = ref.read(productScreenControllerProvider);
    final route = AppRoute.products.name;
    final pageTitle = S.of(context).products;
    return MainDrawerButton('products', S.of(context).products, () async {
      processAndMoveToTargetPage(context, ref, productScreenController, route, pageTitle);
    });
  }
}

class MainDrawerHeader extends StatelessWidget {
  const MainDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 250,
        child: DrawerHeader(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(children: [
              SizedBox(
                // margin: const EdgeInsets.all(10),
                width: double.infinity,
                height: 200, // here I used width intentionally
                child: Image.asset('assets/images/logo.png', fit: BoxFit.scaleDown),
              ),
              Text(
                S.of(context).slogan,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ])));
  }
}

class MainDrawerButton extends ConsumerWidget {
  final String iconName;
  final String title;
  final VoidCallback onTap;

  const MainDrawerButton(
    this.iconName,
    this.title,
    this.onTap, {
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
        leading: Image.asset(
          'assets/icons/side_drawer/$iconName.png',
          width: 30,
          fit: BoxFit.scaleDown,
        ),
        title: Text(title),
        onTap: onTap);
  }
}

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> names = [
      S.of(context).categories,
      S.of(context).regions,
      S.of(context).settings,
    ];

    final List<String> routes = [
      AppRoute.categories.name,
      AppRoute.regions.name,
      AppRoute.settings.name,
    ];

    return AlertDialog(
      alignment: Alignment.center,
      scrollable: true,
      content: Container(
        padding: const EdgeInsets.all(25),
        width: 300,
        height: 650,
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1, // Number of columns
                  childAspectRatio: 1.7, // Aspect ratio of each card
                ),
                itemCount: names.length,
                itemBuilder: (context, index) {
                  return SettingChildButton(names[index], routes[index]);
                },
              ),
            ),
            const BackupButton(),
          ],
        ),
      ),
    );
  }
}

class SettingChildButton extends ConsumerWidget {
  const SettingChildButton(this.name, this.route, {super.key});

  final String name;
  final String route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageTitleNotifier = ref.read(pageTitleProvider.notifier);
    final categoryScreenController = ref.read(categoryScreenControllerProvider);
    final categoryScreenData = ref.read(categoryScreenDataNotifier.notifier);
    final regionScreenController = ref.read(regionScreenControllerProvider);
    final regionScreenData = ref.read(regionScreenDataNotifier.notifier);

    return InkWell(
      onTap: () {
        if (categoryScreenData.data.isEmpty) {
          categoryScreenController.setFeatureScreenData(context);
        }
        if (regionScreenData.data.isEmpty) {
          regionScreenController.setFeatureScreenData(context);
        }
        pageTitleNotifier.state = name;
        if (context.mounted) {
          context.goNamed(route);
        }
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        child: SizedBox(
          height: 40, // Reduced height for the card
          child: Center(
            child: Text(
              name, // Use the corresponding name
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class BackupButton extends ConsumerWidget {
  const BackupButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 150,
      child: InkWell(
        onTap: () async {
          await backupDataBase(context, ref);
        },
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(16),
          child: SizedBox(
            height: 40, // Reduced height for the card
            child: Center(
              child: Text(
                S.of(context).save_data_backup, // Use the corresponding name
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
