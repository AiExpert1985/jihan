import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/database_backup.dart';
import 'package:tablets/src/common/functions/db_cache_inialization.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/interfaces/screen_controller.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/providers/page_title_provider.dart';
import 'package:tablets/src/common/providers/screen_cache_service.dart';
import 'package:tablets/src/common/providers/user_info_provider.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/circled_container.dart';
import 'package:tablets/src/features/authentication/model/user_account.dart';
import 'package:tablets/src/features/categories/controllers/category_screen_controller.dart';
import 'package:tablets/src/features/customers/utils/bulk_reassign_customers.dart';
import 'package:tablets/src/features/daily_tasks/controllers/selected_date_provider.dart';
import 'package:tablets/src/features/deleted_transactions/controllers/deleted_transaction_screen_controller.dart';
import 'package:tablets/src/features/pending_transactions/controllers/pending_transaction_screen_controller.dart';
import 'package:tablets/src/features/pending_transactions/repository/pending_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/regions/controllers/region_screen_controller.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_screen_controller.dart';
import 'package:tablets/src/features/vendors/controllers/vendor_screen_controller.dart';
import 'package:tablets/src/routers/go_router_provider.dart';
import 'package:tablets/src/features/transactions/controllers/invoice_validation_controller.dart';
import 'package:tablets/src/features/transactions/controllers/missing_transactions_detector.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pendingTransactionDbCacheProvider);
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
                  TasksButton(),
                  VerticalGap.m,
                  WarehouseButton(),
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
void processAndMoveToTargetPage(
    BuildContext context,
    WidgetRef ref,
    ScreenDataController screenController,
    String route,
    String pageTitle) async {
  // update user info, so if the user is blocked by admin, while he uses the app he will be blocked
  ref.read(userInfoProvider.notifier).loadUserInfo(ref);
  final userInfo = ref.read(userInfoProvider);
  if (userInfo == null || !userInfo.hasAccess) {
    // user must have access
    return;
  }
  final pageLoadingNotifier = ref.read(pageIsLoadingNotifier.notifier);
  // page is loading used to show a loading spinner (better user experience)
  // before loading initializing dbCaches and settings we show loading spinner &
  // when done it is cleared using below pageLoadingNotifier.state = false;
  if (pageLoadingNotifier.state) {
    // if pageLoadingNotifier.date = true, then it means another page is loading or data is initializing
    // so, we return and not proceed
    // this is done to fix the bug of pressing buttons multiple times at the very start of the app
    // when the app is loading databases into dBCaches
    failureUserMessage(
        context, "يرجى الانتظار حتى اكتمال تحميل بيانات البرنامج");
    return;
  }
  final pageTitleNotifier = ref.read(pageTitleProvider.notifier);
  // Only admin users can trigger database backup
  if (userInfo.privilage == UserPrivilage.admin.name) {
    await autoDatabaseBackup(context, ref);
  }
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

/// Screen type enum for cached screens
enum CachedScreenType { customer, product, salesman }

/// Process and move to target page using cache service for main screens
/// This loads data from Firebase cache if available, otherwise calculates and saves to cache
void processAndMoveToTargetPageWithCache(BuildContext context, WidgetRef ref,
    CachedScreenType screenType, String route, String pageTitle) async {
  // update user info, so if the user is blocked by admin, while he uses the app he will be blocked
  ref.read(userInfoProvider.notifier).loadUserInfo(ref);
  final userInfo = ref.read(userInfoProvider);
  if (userInfo == null || !userInfo.hasAccess) {
    // user must have access
    return;
  }
  final pageLoadingNotifier = ref.read(pageIsLoadingNotifier.notifier);
  if (pageLoadingNotifier.state) {
    failureUserMessage(
        context, "يرجى الانتظار حتى اكتمال تحميل بيانات البرنامج");
    return;
  }
  final pageTitleNotifier = ref.read(pageTitleProvider.notifier);
  // Only admin users can trigger database backup
  if (userInfo.privilage == UserPrivilage.admin.name) {
    await autoDatabaseBackup(context, ref);
  }
  pageLoadingNotifier.state = true;
  // note that dbCaches are only used for mirroring the database
  if (context.mounted) {
    await initializeAllDbCaches(context, ref);
  }
  // we initialize settings
  if (context.mounted) {
    initializeSettings(context, ref);
  }
  // Load screen data from cache (or calculate if cache is empty)
  if (context.mounted) {
    final cacheService = ref.read(screenCacheServiceProvider);
    switch (screenType) {
      case CachedScreenType.customer:
        await cacheService.loadCustomerScreenData(context);
        break;
      case CachedScreenType.product:
        await cacheService.loadProductScreenData(context);
        break;
      case CachedScreenType.salesman:
        await cacheService.loadSalesmanScreenData(context);
        break;
    }
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
      final pageLoadingNotifier = ref.read(pageIsLoadingNotifier.notifier);
      // page is loading used to show a loading spinner (better user experience)
      // before loading initializing dbCaches and settings we show loading spinner &
      // when done it is cleared using below pageLoadingNotifier.state = false;
      if (pageLoadingNotifier.state) {
        // if pageLoadingNotifier.date = true, then it means another page is loading or data is initializing
        // so, we return and not proceed
        // this is done to fix the bug of pressing buttons multiple times at the very start of the app
        // when the app is loading databases into dBCaches
        failureUserMessage(
            context, "يرجى الانتظار حتى اكتمال تحميل بيانات البرنامج");
        return;
      }
      pageLoadingNotifier.state = true;
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
      pageLoadingNotifier.state = false;
    });
  }
}

class CustomersButton extends ConsumerWidget {
  const CustomersButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = AppRoute.customers.name;
    final pageTitle = S.of(context).customers;
    return MainDrawerButton(
        'customers',
        S.of(context).customers,
        () async => processAndMoveToTargetPageWithCache(
            context, ref, CachedScreenType.customer, route, pageTitle));
  }
}

class PendingsButton extends ConsumerWidget {
  const PendingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingTransactions = ref.watch(pendingTransactionDbCacheProvider);
    final pendingScreenController =
        ref.read(pendingTransactionScreenControllerProvider);

    final route = AppRoute.pendingTransactions.name;
    final pageTitle = S.of(context).pending_transactions;
    const iconName = 'pending_transactions';
    return ListTile(
      leading: Image.asset(
        'assets/icons/side_drawer/$iconName.png',
        width: 30,
        fit: BoxFit.scaleDown,
      ),
      title: Row(
        children: [
          Text(S.of(context).pending_transactions),
          if (pendingTransactions.isNotEmpty) ...[
            HorizontalGap.xl,
            CircledContainer(
                child: Text(pendingTransactions.length.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white)))
          ]
        ],
      ),
      onTap: () async => processAndMoveToTargetPage(
          context, ref, pendingScreenController, route, pageTitle),
    );
  }
}

class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(userInfoProvider);
    final isAccountant = userInfo?.privilage == UserPrivilage.accountant.name;

    if (isAccountant) {
      return const SizedBox.shrink();
    }

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
          showDialog(
              context: context,
              builder: (BuildContext ctx) => const SettingsDialog());
        }
      },
    );
  }
}

class SalesmenButton extends ConsumerWidget {
  const SalesmenButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = AppRoute.salesman.name;
    final pageTitle = S.of(context).salesmen;
    return MainDrawerButton(
        'salesman',
        S.of(context).salesmen,
        () async => processAndMoveToTargetPageWithCache(
            context, ref, CachedScreenType.salesman, route, pageTitle));
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
        () async => processAndMoveToTargetPage(
            context, ref, vendorScreenController, route, pageTitle));
  }
}

class TransactionsButton extends ConsumerWidget {
  const TransactionsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionScreenController =
        ref.read(transactionScreenControllerProvider);
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
    final route = AppRoute.products.name;
    final pageTitle = S.of(context).products;
    return MainDrawerButton('products', S.of(context).products, () async {
      processAndMoveToTargetPageWithCache(
          context, ref, CachedScreenType.product, route, pageTitle);
    });
  }
}

class TasksButton extends ConsumerWidget {
  const TasksButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = AppRoute.tasks.name;
    const pageTitle = 'زيارات المندوبين';
    return MainDrawerButton('tasks', 'زيارات المندوبين', () async {
      // update user info, so if the user is blocked by admin, while he uses the app he will be blocked
      ref.read(userInfoProvider.notifier).loadUserInfo(ref);
      final userInfo = ref.read(userInfoProvider);
      if (userInfo == null || !userInfo.hasAccess) {
        return;
      }
      final pageLoadingNotifier = ref.read(pageIsLoadingNotifier.notifier);
      // page is loading used to show a loading spinner (better user experience)
      // before loading initializing dbCaches and settings we show loading spinner &
      // when done it is cleared using below pageLoadingNotifier.state = false;
      if (pageLoadingNotifier.state) {
        // if pageLoadingNotifier.date = true, then it means another page is loading or data is initializing
        // so, we return and not proceed
        // this is done to fix the bug of pressing buttons multiple times at the very start of the app
        // when the app is loading databases into dBCaches
        failureUserMessage(
            context, "يرجى الانتظار حتى اكتمال تحميل بيانات البرنامج");
        return;
      }
      final pageTitleNotifier = ref.read(pageTitleProvider.notifier);
      // Only admin users can trigger database backup
      if (userInfo.privilage == UserPrivilage.admin.name) {
        await autoDatabaseBackup(context, ref);
      }
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
      // make datePicker equals today
      ref.read(selectedDateProvider.notifier).setDate(DateTime.now());
    });
  }
}

class WarehouseButton extends ConsumerWidget {
  const WarehouseButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(userInfoProvider);

    if (userInfo == null ||
        userInfo.privilage != UserPrivilage.warehouse.name) {
      return const SizedBox.shrink();
    }

    return MainDrawerButton('warehouse', 'طباعة المجهز', () async {
      final pageLoadingNotifier = ref.read(pageIsLoadingNotifier.notifier);
      final pageTitleNotifier = ref.read(pageTitleProvider.notifier);

      if (pageLoadingNotifier.state) {
        failureUserMessage(
            context, "يرجى الانتظار حتى اكتمال تحميل بيانات البرنامج");
        return;
      }

      pageLoadingNotifier.state = true;
      pageTitleNotifier.state = 'طباعة المجهز';

      if (context.mounted) {
        Navigator.of(context).pop();
        context.goNamed(AppRoute.warehouse.name);
      }

      pageLoadingNotifier.state = false;
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
                  Theme.of(context).colorScheme.primary,
                ],
              ),
            ),
            child: Column(children: [
              SizedBox(
                // margin: const EdgeInsets.all(10),
                width: double.infinity,
                height: 200, // here I used width intentionally
                child: Image.asset('assets/images/logo.png',
                    fit: BoxFit.scaleDown),
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
    const double itemWidth = 130;
    const double itemHeight = 87;

    return AlertDialog(
      alignment: Alignment.center,
      content: Container(
        padding: const EdgeInsets.all(15),
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section 1: Regions, Categories, Deleted Transactions
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: SettingChildButton(
                      S.of(context).regions, AppRoute.regions.name, Icons.map),
                ),
                SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: SettingChildButton(S.of(context).categories,
                      AppRoute.categories.name, Icons.category),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            // Section 2: Print Log, Edit Log
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: PrintLogButton()),
                const SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: EditLogButton()),
                Tooltip(
                  message: 'سلة المهملات لكل للتعاملات التي تم حدفها من البرنامج (من كافة الاجهزة)',
                  child: SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: SettingChildButton(S.of(context).deleted_transactions,
                        AppRoute.deletedTransactions.name, Icons.delete_outline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            // Section 3: Utility Tools
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Tooltip(
                  message: 'تخفيض اسعار المواد التي تم شرائها من المجهز حيث يتم تغيير الاسعار في القوائم و كتابة ملاحظات',
                  child: SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: SettingChildButton('تخفيضات المجهز',
                        AppRoute.supplierDiscount.name, Icons.discount),
                  ),
                ),
                const SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: BackupButton()),
                const SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: BulkCustomerReassignmentButton()),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            // Section 4: Detection Tools
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: DuplicateTransactionsButton()),
                SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: InvoiceValidationButton()),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            // Section 5: Settings
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: SettingChildButton(S.of(context).settings,
                      AppRoute.settings.name, Icons.settings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingChildButton extends ConsumerWidget {
  const SettingChildButton(this.name, this.route, this.icon, {super.key});

  final String name;
  final String route;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageTitleNotifier = ref.read(pageTitleProvider.notifier);
    final categoryScreenController = ref.read(categoryScreenControllerProvider);
    final regionScreenController = ref.read(regionScreenControllerProvider);
    final deletedTransactionScreenController =
        ref.read(deletedTransactionScreenControllerProvider);

    return InkWell(
      onTap: () {
        categoryScreenController.setFeatureScreenData(context);
        regionScreenController.setFeatureScreenData(context);
        deletedTransactionScreenController.setFeatureScreenData(context);

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class BackupButton extends ConsumerWidget {
  const BackupButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'عمل نسخة احتياطية من قاعدة البيانات',
      child: InkWell(
        onTap: () async {
          await backupDataBase(context, ref);
        },
        child: Card(
          elevation: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.backup,
                  size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                S.of(context).save_data_backup,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvoiceValidationButton extends ConsumerStatefulWidget {
  const InvoiceValidationButton({super.key});

  @override
  ConsumerState<InvoiceValidationButton> createState() =>
      _InvoiceValidationButtonState();
}

class _InvoiceValidationButtonState
    extends ConsumerState<InvoiceValidationButton> {
  bool _isValidating = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'مطابقة مبالغ المواد داخل القائمة مع المبلغ الكلي للقائمة لكشف الاختلافات ان وجدت',
      child: InkWell(
        onTap: _isValidating
            ? null
            : () async {
                setState(() {
                  _isValidating = true;
                });

                try {
                  final mismatches = await validateCustomerInvoices(ref);

                  if (mounted) {
                    setState(() {
                      _isValidating = false;
                    });

                    ref.read(invoiceValidationResultsProvider.notifier).state =
                        mismatches;

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      context.goNamed(AppRoute.invoiceValidationResults.name);
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _isValidating = false;
                    });
                    if (context.mounted) {
                      failureUserMessage(context, 'خطأ في المطابقة: $e');
                    }
                  }
                }
              },
        child: Card(
          elevation: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isValidating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.fact_check,
                      size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 4),
              const Text(
                'مطابقة مبالغ القوائم',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrintLogButton extends ConsumerWidget {
  const PrintLogButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'سجل لكل التعاملات التي تمت طباعتها المرسلة الى المخزن للتجهيز و تخص هذا الجهاز فقط',
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          context.goNamed(AppRoute.printLog.name);
        },
        child: Card(
          elevation: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.print,
                  size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 4),
              const Text(
                'سجل الطباعة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditLogButton extends ConsumerWidget {
  const EditLogButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'سجل جميع التعاملات التي تم تعديلها على هذا الجهاز',
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          context.goNamed(AppRoute.editLog.name);
        },
        child: Card(
          elevation: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_note,
                  size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 4),
              const Text(
                'سجل التعديلات',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DuplicateTransactionsButton extends ConsumerWidget {
  const DuplicateTransactionsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'كشف التعاملات المتكررة بنفس الرقم المرجعي فقط',
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          context.goNamed(AppRoute.duplicateTransactions.name);
        },
        child: Card(
          elevation: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.copy_all,
                  size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 4),
              const Text(
                'التعاملات المكررة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MissingTransactionsDetectionButton extends ConsumerStatefulWidget {
  const MissingTransactionsDetectionButton({super.key});

  @override
  ConsumerState<MissingTransactionsDetectionButton> createState() =>
      _MissingTransactionsDetectionButtonState();
}

class _MissingTransactionsDetectionButtonState
    extends ConsumerState<MissingTransactionsDetectionButton> {
  bool _isDetecting = false;
  bool _shouldCancel = false;
  int _currentFile = 0;
  int _totalFiles = 0;
  String _currentFilename = '';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 125,
      child: InkWell(
        onTap: _isDetecting ? null : _startDetection,
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(16),
          child: SizedBox(
            height: 40,
            child: Center(
              child: _isDetecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'البحث عن القوائم المفقودة',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getBackupFiles() {
    try {
      final executablePath = Platform.resolvedExecutable;
      final appFolderPath = Directory(executablePath).parent.path;
      final backupDir = Directory('$appFolderPath/database_backup');
      if (!backupDir.existsSync()) return [];
      final files = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip'))
          .toList();
      // Sort by name descending (YYYYMMDD format = chronological)
      files.sort((a, b) => b.path.compareTo(a.path));
      // Take most recent 364 files
      final limited = files.take(364).toList();
      // Reverse to process oldest first (same as original alphabetical sort)
      return limited.reversed.map((f) => f.path).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _startDetection() async {
    // Auto-load backup files from the known backup folder
    final filePaths = _getBackupFiles();
    if (filePaths.isEmpty) {
      if (mounted) {
        failureUserMessage(context, 'لا توجد ملفات نسخ احتياطية');
      }
      return;
    }

    setState(() {
      _isDetecting = true;
      _shouldCancel = false;
      _currentFile = 0;
      _totalFiles = filePaths.length;
      _currentFilename = '';
    });

    // Show cancellable progress dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('معالجة الملف $_currentFile من $_totalFiles'),
              const SizedBox(height: 8),
              Text(
                _currentFilename,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _shouldCancel = true;
                Navigator.of(dialogContext).pop();
              },
              child: const Text('إلغاء'),
            ),
          ],
        ),
      );
    }

    try {
      final success = await detectMissingTransactionsMultiple(
        context,
        ref,
        filePaths,
        (currentFile, totalFiles, currentFilename) {
          if (mounted) {
            setState(() {
              _currentFile = currentFile;
              _totalFiles = totalFiles;
              _currentFilename = currentFilename;
            });
          }
        },
        () => _shouldCancel,
      );

      if (mounted && context.mounted) {
        // Close progress dialog
        Navigator.of(context).pop();

        setState(() {
          _isDetecting = false;
        });

        if (success) {
          // Phase 2: detect missing from print log and merge results
          final printLogMissing = detectMissingFromPrintLog(ref);
          if (printLogMissing.isNotEmpty) {
            final currentResults = ref.read(missingTransactionsProvider);
            // Avoid duplicates: only add print-log entries not already found in backup
            final existingDbRefs = <String>{};
            for (final m in currentResults) {
              final dbRef = m.fullTransactionData['dbRef']?.toString();
              if (dbRef != null) existingDbRefs.add(dbRef);
            }
            final newFromLog = printLogMissing.where((m) {
              final dbRef = m.fullTransactionData['dbRef']?.toString();
              return dbRef != null && !existingDbRefs.contains(dbRef);
            }).toList();
            ref.read(missingTransactionsProvider.notifier).state = [
              ...currentResults,
              ...newFromLog
            ];
          }
          // Navigate to results screen
          context.goNamed(AppRoute.missingTransactionsResults.name);
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        setState(() {
          _isDetecting = false;
        });
        failureUserMessage(context, 'خطأ في الفحص: $e');
      }
    }
  }
}

// /// initialize all dbCaches and settings, and move on the the target page
// void processAndMoveToPendingsPage(BuildContext context, WidgetRef ref,
//     ScreenDataController screenController, String route, String pageTitle) async {
//   await autoDatabaseBackup(context, ref);
//   final pageTitleNotifier = ref.read(pageTitleProvider.notifier);
//   final pageLoadingNotifier = ref.read(pageIsLoadingNotifier.notifier);
//   // page is loading only used to show a loading spinner (better user experience)
//   // before loading initializing dbCaches and settings we show loading spinner &
//   // when done it is cleared using below pageLoadingNotifier.state = false;
//   pageLoadingNotifier.state = true;
//   // note that dbCaches are only used for mirroring the database, all the data used in the
//   // app in the screenData, which is a processed version of dbCache
//   final productDbCache = ref.read(pendingTransactionDbCacheProvider.notifier);
//   final productData = await ref.read(pendingTransactionRepositoryProvider).fetchItemListAsMaps();
//   productDbCache.set(productData);
//   // we inialize settings
//   if (context.mounted) {
//     initializeSettings(context, ref);
//   }
//   // load dbCache data into screenData, which will be used later for show data in the
//   // page main screen, and also for search
//   if (context.mounted) {
//     screenController.setFeatureScreenData(context);
//   }
//   if (context.mounted) {
//     pageTitleNotifier.state = pageTitle;
//   }
//   // after loading and processing data, we turn off the loading spinner
//   pageLoadingNotifier.state = false;
//   // close side drawer and move to the target page
//   if (context.mounted) {
//     Navigator.of(context).pop();
//     context.goNamed(route);
//   }
// }
