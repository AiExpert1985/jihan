import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:search_choices/search_choices.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/database_backup.dart';
import 'package:tablets/src/common/functions/db_cache_inialization.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/background_color.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/providers/text_editing_controllers_provider.dart';
import 'package:tablets/src/common/providers/user_info_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/home_greetings.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/common/widgets/page_loading.dart';
import 'package:tablets/src/common/widgets/ristricted_access_widget.dart';
import 'package:tablets/src/features/authentication/model/user_account.dart';
import 'package:tablets/src/features/authentication/repository/accounts_repository.dart';
import 'package:tablets/src/features/customers/controllers/customer_report_controller.dart';
import 'package:tablets/src/features/customers/controllers/customer_screen_controller.dart';
import 'package:tablets/src/features/customers/model/customer.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/products/repository/product_db_cache_provider.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_report_controller.dart';
import 'package:tablets/src/features/salesmen/controllers/salesman_screen_controller.dart';
import 'package:tablets/src/features/salesmen/repository/salesman_db_cache_provider.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/repository/settings_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_navigator_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/view/transaction_show_form.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppScreenFrame(HomeScreenGreeting());
  }
}

class HomeScreenGreeting extends ConsumerStatefulWidget {
  const HomeScreenGreeting({super.key});

  @override
  ConsumerState<HomeScreenGreeting> createState() => _HomeScreenGreetingState();
}

class _HomeScreenGreetingState extends ConsumerState<HomeScreenGreeting> {
  @override
  void initState() {
    super.initState();
    // mainly user for Jihan supervisor at current time
    ref.read(userInfoProvider.notifier).loadUserInfo(ref);
    initializeAllDbCaches(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsDbCacheProvider);
    ref.watch(settingsFormDataProvider);
    ref.watch(userInfoProvider); // to update UI when user info finally loaded
    final settingsDbCache = ref.read(settingsDbCacheProvider.notifier);
    // since settings is the last doecument loaded from db, if it is being not empty means it finish loading
    Widget screenWidget = (settingsDbCache.data.isEmpty)
        ? const PageLoading()
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RistrictedAccessWidget(
                allowedPrivilages: const [],
                child: Container(
                  padding: const EdgeInsets.all(10),
                  width: 200,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomerFastAccessButtons(),
                      VendorFastAccessButtons(),
                      InternalFastAccessButtons(),
                    ],
                  ),
                ),
              ),
              const HomeGreeting(),
              const FastReports()
            ],
          );
    return Container(padding: const EdgeInsets.all(15), child: screenWidget);
  }
}

class CustomerFastAccessButtons extends ConsumerWidget {
  const CustomerFastAccessButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FastAccessButtonsContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FastAccessFormButton(
            TransactionType.customerInvoice.name,
            textColor: Colors.green[100],
          ),
          VerticalGap.l,
          FastAccessFormButton(
            TransactionType.customerReceipt.name,
            textColor: Colors.red[100],
          ),
          VerticalGap.l,
          FastAccessFormButton(
            TransactionType.customerReturn.name,
            textColor: Colors.grey[300],
          ),
          VerticalGap.l,
          FastAccessFormButton(
            TransactionType.gifts.name,
            textColor: Colors.orange[100],
          ),
        ],
      ),
    );
  }
}

class FastAccessButtonsContainer extends StatelessWidget {
  const FastAccessButtonsContainer({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: const BorderRadius.all(Radius.circular(8))),
        child: child);
  }
}

class VendorFastAccessButtons extends ConsumerWidget {
  const VendorFastAccessButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FastAccessButtonsContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FastAccessFormButton(
            TransactionType.vendorInvoice.name,
            textColor: Colors.green[100],
          ),
          VerticalGap.l,
          FastAccessFormButton(
            TransactionType.vendorReceipt.name,
            textColor: Colors.red[100],
          ),
          VerticalGap.l,
          FastAccessFormButton(
            TransactionType.vendorReturn.name,
            textColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}

class InternalFastAccessButtons extends ConsumerWidget {
  const InternalFastAccessButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FastAccessButtonsContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FastAccessFormButton(
            TransactionType.expenditures.name,
            textColor: Colors.green[100],
          ),
          VerticalGap.l,
          FastAccessFormButton(
            TransactionType.damagedItems.name,
            textColor: Colors.red[100],
          ),
        ],
      ),
    );
  }
}

class FastAccessFormButton extends ConsumerWidget {
  const FastAccessFormButton(this.formType, {this.textColor, super.key});
  final String formType;
  final Color? textColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String label = translateDbTextToScreenText(context, formType);
    final textEditingNotifier = ref.read(textFieldsControllerProvider.notifier);
    final imagePickerNotifier = ref.read(imagePickerProvider.notifier);
    final formDataNotifier = ref.read(transactionFormDataProvider.notifier);
    final backgroundColorNofifier = ref.read(backgroundColorProvider.notifier);
    final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
    final fromNavigator = ref.read(formNavigatorProvider);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onPressed: () async {
        fromNavigator.isReadOnly = false;
        // checkTransactionsTotals(ref);
        // first we set pageLoadingNotifier to true, to prevent any side bar button press
        // until initialization is completed
        final pageLoadingNotifier = ref.read(pageIsLoadingNotifier.notifier);
        if (pageLoadingNotifier.state) {
          // if pageLoadingNotifier.date = true, then it means another page is loading or data is initializing
          // so, we return and not proceed
          // this is done to fix the bug of pressing buttons multiple times at the very start of the app
          // when the app is loading databases into dBCaches
          failureUserMessage(context, "يرجى الانتظار حتى اكتمال تحميل بيانات البرنامج");
          return;
        }
        pageLoadingNotifier.state = true;
        await initializeAppData(context, ref);
        backgroundColorNofifier.state = normalColor!;
        if (context.mounted) {
          TransactionShowForm.showForm(
            context,
            ref,
            imagePickerNotifier,
            formDataNotifier,
            settingsDataNotifier,
            textEditingNotifier,
            formType: formType,
            transactionDbCache: transactionDbCache,
          );
          pageLoadingNotifier.state = false;
        }
      },
      child: Container(
        height: 60,
        width: 70,
        padding: const EdgeInsets.all(0),
        child: Center(
            child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15))),
      ),
    );
  }
}

Future<void> initializeAppData(BuildContext context, WidgetRef ref) async {
  // update user info, so if the user is blocked by admin, while he uses the app he will be blocked
  ref.read(userInfoProvider.notifier).loadUserInfo(ref);
  await autoDatabaseBackup(context, ref);
  if (context.mounted) {
    // make sure dbCaches and settings are initialized
    await initializeAllDbCaches(context, ref);
  }
  if (context.mounted) {
    initializeSettings(context, ref);
  }
}

class FastReports extends ConsumerWidget {
  const FastReports({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userInfoProvider);
    return RistrictedAccessWidget(
      allowedPrivilages: [UserPrivilage.guest.name],
      child: Container(
          padding: const EdgeInsets.all(20),
          width: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RistrictedAccessWidget(
                allowedPrivilages: const [],
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Column(
                    children: [
                      buildAllDebtButton(context, ref),
                      VerticalGap.xl,
                      buildSoldItemsButton(context, ref),
                      VerticalGap.xl,
                      buildCustomerMatchingButton(context, ref),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildSoldItemsButton(context, ref, isSupervisor: true),
                    VerticalGap.xl,
                    buildSalesmanCustomersButton(context, ref),
                    VerticalGap.xl,
                    buildSalesmanTasksButton(context, ref),
                    VerticalGap.xl,
                    const RistrictedAccessWidget(
                      allowedPrivilages: [],
                      child: HideProductCheckBox(),
                    ),
                  ],
                ),
              ),
              const ReloadDbCacheData(),
            ],
          )),
    );
  }
}

Widget buildCustomerMatchingButton(BuildContext context, WidgetRef ref,
    {bool isSupervisor = false}) {
  final customerDbCache = ref.read(customerDbCacheProvider.notifier);
  final customerScreenController = ref.read(customerScreenControllerProvider);
  final customerReportController = ref.read(customerReportControllerProvider);
  return FastAccessReportsButton(
    backgroundColor: Colors.red[100],
    S.of(context).customer_matching,
    () async {
      await initializeAppData(context, ref);
      if (context.mounted) {
        final nameAndDates = await selectionDialog(
            context, ref, customerDbCache.data, S.of(context).customers,
            includeDates: false);
        final customerData = nameAndDates[0];
        // salesman must be selected, otherwise we can't create report
        if (customerData == null) {
          return;
        }
        final customerTransactions =
            customerScreenController.getCustomerTransactions(customerData['dbRef']);
        final customer = Customer.fromMap(customerData);
        if (customer.initialCredit > 0) {
          final intialDebtTransaction = _createInitialDebtTransaction(customer);
          customerTransactions.add(intialDebtTransaction);
        }
        if (context.mounted) {
          final customerMatchingData =
              customerScreenController.customerMatching(context, customerTransactions);
          customerReportController.showCustomerMatchingReport(
              context, customerMatchingData, customerData['name']);
        }
      }
    },
  );
}

/// creates a temp transaction using customer initial debt, the transaction is used in the
/// calculation of customer debt
Map<String, dynamic> _createInitialDebtTransaction(Customer customer) {
  return Transaction(
    dbRef: 'na',
    name: customer.name,
    imageUrls: ['na'],
    number: 1000001,
    date: customer.initialDate,
    currency: 'na',
    transactionType: TransactionType.initialCredit.name,
    totalAmount: customer.initialCredit,
    transactionTotalProfit: 0,
    isPrinted: false,
  ).toMap();
}

Widget buildSalesmanCustomersButton(BuildContext context, WidgetRef ref) {
  final salesmanDbCache = ref.read(salesmanDbCacheProvider.notifier);
  final salesmanScreenController = ref.read(salesmanScreenControllerProvider);
  final salesmanReportController = ref.read(salesmanReportControllerProvider);
  final customersDbCache = ref.read(customerDbCacheProvider.notifier);
  final transactionsDbCache = ref.read(transactionDbCacheProvider.notifier);
  return FastAccessReportsButton(
    backgroundColor: Colors.orange[100],
    S.of(context).saleman_customers,
    () async {
      await initializeAppData(context, ref);
      if (context.mounted) {
        final nameAndDates = await selectionDialog(
            context, ref, salesmanDbCache.data, S.of(context).salesmen,
            includeDates: true);
        final salesmanData = nameAndDates[0];
        // dates can be null, which means to take all the duration
        final startDate = nameAndDates[1];
        final endDate = nameAndDates[2];
        // salesman must be selected, otherwise we can't create report
        if (salesmanData == null) {
          return;
        }
        final salesmanCustomerMaps = customersDbCache.data.where((customer) {
          return customer['salesmanDbRef'] == salesmanData['dbRef'];
        }).toList();
        final salesmanCustomers =
            salesmanCustomerMaps.map((customerMap) => Customer.fromMap(customerMap)).toList();
        final salesmanTransactionMaps = transactionsDbCache.data.where((transaction) {
          DateTime transactionDate =
              transaction['date'] is DateTime ? transaction['date'] : transaction['date'].toDate();
          // I need to subtract one day for start date to make the searched date included
          bool isAfterStartDate = startDate == null || !transactionDate.isBefore(startDate);
          // I need to add one day to the end date to make the searched date included
          bool isBeforeEndDate =
              endDate == null || !transactionDate.isAfter(endDate.add(const Duration(days: 1)));
          return transaction['salesmanDbRef'] == salesmanData['dbRef'] &&
              isAfterStartDate &&
              isBeforeEndDate;
        }).toList();
        final salesmanTransactions = salesmanTransactionMaps
            .map((transactionMap) => Transaction.fromMap(transactionMap))
            .toList();
        final customersInfo = salesmanScreenController.getCustomersInfo(
            salesmanCustomers, salesmanTransactions,
            isSuperVisor: true, ref: ref);
        final customersBasicData = customersInfo['customersData'] as List<List<dynamic>>;
        final startDateAsString = startDate == null ? '' : 'من ${formatDate(startDate)}';
        final endDataeAsString = endDate == null ? '' : 'الى ${formatDate(endDate)}';
        final reportTitle = '${salesmanData['name']} \n $startDateAsString $endDataeAsString';
        if (context.mounted) {
          salesmanReportController.showCustomers(context, customersBasicData, reportTitle);
        }
      }
    },
  );
}

Widget buildSalesmanTasksButton(BuildContext context, WidgetRef ref) {
  return FastAccessReportsButton(
    backgroundColor: Colors.red[100],
    'زيارات المندوبين',
    () async {
      await initializeAppData(context, ref);
      if (context.mounted) {
        context.pushNamed('tasks');
      }
    },
  );
}

Widget buildAllDebtButton(BuildContext context, WidgetRef ref) {
  final customerReportController = ref.read(customerReportControllerProvider);
  return FastAccessReportsButton(
    backgroundColor: Colors.orange[100],
    S.of(context).salesmen_debt_report,
    () async {
      await initializeAppData(context, ref);
      if (context.mounted) {
        customerReportController.showAllCustomersDebt(context, ref);
      }
    },
  );
}

/// supervisor report differs in two things, (1) button name, (2) last two columns are empty in supervisor report
Widget buildSoldItemsButton(BuildContext context, WidgetRef ref, {bool isSupervisor = false}) {
  final salesmanReportController = ref.read(salesmanReportControllerProvider);
  final salesmanScreenController = ref.read(salesmanScreenControllerProvider);
  final salesmanDbCache = ref.read(salesmanDbCacheProvider.notifier);
  // productDbCache is used for hidding items not be shown for the supervisore
  final productDbCache = ref.read(productDbCacheProvider.notifier);
  return FastAccessReportsButton(
    // name depends whether the report is for supervisor
    S.of(context).salesmen_sellings,
    backgroundColor: Colors.green[100],
    () async {
      await initializeAppData(context, ref);
      if (context.mounted) {
        final nameAndDates = await selectionDialog(
            context, ref, salesmanDbCache.data, S.of(context).salesman_selection);
        final salesmanData = nameAndDates[0];
        // salesman must be selected, otherwise we can't create report
        if (salesmanData == null) {
          return;
        }
        // dates can be null, which means to take all the duration
        final startDate = nameAndDates[1];
        final endDate = nameAndDates[2];
        String reportTitle = '';
        if (context.mounted) {
          reportTitle =
              '${S.of(context).salesman_selling_report} \n ${salesmanData['name']} \n ${S.of(context).for_the_duration} ${formatDate(startDate ?? DateTime.parse("2024-12-01T14:30:00"))} - ${formatDate(endDate ?? DateTime.now())}';
        }
        List<List<dynamic>> soldItemsList = salesmanScreenController.salesmanItemsSold(
            salesmanData['dbRef'], startDate, endDate, ref);
        if (isSupervisor) {
          // filter items not to show for the supervisor
          soldItemsList = soldItemsList.where((item) {
            final dbItem = productDbCache.getItemByProperty('name', item[0]);
            // only keep products that are not hidden from special reports
            return dbItem['isHiddenInSpecialReports'] == null ||
                !dbItem['isHiddenInSpecialReports'];
          }).toList();
        }
        // sort by product name
        soldItemsList.sort((a, b) {
          return a[0].compareTo(b[0]);
        });
        if (context.mounted) {
          salesmanReportController.showSoldItemsReport(
              context, soldItemsList, reportTitle, isSupervisor);
        }
      }
    },
  );
}

class FastAccessReportsButton extends ConsumerWidget {
  const FastAccessReportsButton(this.label, this.onPressFn,
      {this.textColor, this.backgroundColor, super.key});
  final String label;
  final Color? textColor;
  final Color? backgroundColor;
  final void Function() onPressFn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onPressed: onPressFn,
      child: Container(
        height: 60,
        width: 70,
        padding: const EdgeInsets.all(0),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: textColor),
          ),
        ),
      ),
    );
  }
}

/// returns selected value from drop down list (with search) and dates (from - to)
/// it could return null dates (but not null selected values)
Future<List<dynamic>> selectionDialog(BuildContext context, WidgetRef ref,
    List<Map<String, dynamic>>? selectionValues, String? selectionLabel,
    {bool includeDates = true}) async {
  DateTime? startDate;
  DateTime? endDate;
  Map<String, dynamic>? selectedValue;

  // Show the dialog
  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        // title: Text(selectionLabel ?? ''),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectionValues != null)
                SearchChoices.single(
                  fieldDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4), // Rounded corners
                      border: Border.all(color: Colors.grey)),
                  items: selectionValues
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item['name']),
                        ),
                      )
                      .toList(),
                  value: selectedValue,
                  hint: Text(
                    selectionLabel ?? '',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  searchHint: Text(
                    selectionLabel ?? '',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  onChanged: (value) {
                    selectedValue = value;
                  },

                  isExpanded: true,
                  // padding is the only way I found to reduce the width of the search dialog
                  dropDownDialogPadding: const EdgeInsets.symmetric(
                    vertical: 120,
                    horizontal: 600,
                  ),
                  closeButton: const SizedBox.shrink(),
                ),
              VerticalGap.l,
              if (includeDates)
                Container(
                  width: 265,
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    children: [
                      Expanded(
                        child: FormBuilderDateTimePicker(
                          textAlign: TextAlign.center,
                          name: 'startDate',
                          decoration: InputDecoration(
                            labelStyle: const TextStyle(color: Colors.red, fontSize: 17),
                            labelText: S.of(context).from_date,
                            border: const OutlineInputBorder(),
                          ),
                          // initialValue: toDate ?? DateTime.now(),
                          inputType: InputType.date,
                          format: DateFormat('dd-MM-yyyy'),
                          onChanged: (picked) {
                            startDate = picked;
                          },
                        ),
                      ),
                      HorizontalGap.xl,
                      Expanded(
                        child: FormBuilderDateTimePicker(
                          textAlign: TextAlign.center,
                          name: 'endDate',
                          decoration: InputDecoration(
                            labelStyle: const TextStyle(color: Colors.red, fontSize: 17),
                            labelText: S.of(context).to_date,
                            border: const OutlineInputBorder(),
                          ),
                          // initialValue: toDate ?? DateTime.now(),
                          inputType: InputType.date,
                          format: DateFormat('dd-MM-yyyy'),
                          onChanged: (picked) {
                            endDate = picked;
                          },
                        ),
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
        actions: <Widget>[
          Center(
            child: IconButton(
                onPressed: () {
                  if (selectedValue != null) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const ApproveIcon()),
          )
        ],
      );
    },
  );

  // Return the selected dates
  return [selectedValue, startDate, endDate];
}

// below is done by AI
class HideProductCheckBox extends ConsumerWidget {
  const HideProductCheckBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userInfoProvider);
    final supervisorAsyncValue = ref.watch(accountsStreamProvider);

    return Container(
      padding: const EdgeInsets.all(0),
      child: supervisorAsyncValue.when(
        data: (supervisors) {
          // Filter to find the first supervisor with the specified email
          final supervisor = supervisors.firstWhere(
            (supervisor) => supervisor['email'] == 'jihansupervisor@gmail.com',
            orElse: () => {}, // Provide a default value if not found
          );

          // Check if the supervisor was found
          final hassAccess = supervisor.isNotEmpty ? supervisor['hasAccess'] ?? false : false;

          return Checkbox(
            value: hassAccess,
            onChanged: (value) {
              // Update the user info and notify the state
              ref.read(accountsRepositoryProvider).updateItem(
                    UserAccount(
                      supervisor['name'],
                      supervisor['dbRef'],
                      supervisor['email'],
                      supervisor['privilage'],
                      value!,
                    ),
                  );
            },
          );
        },
        loading: () => const CircularProgressIndicator(), // Show loading indicator
        error: (error, stack) => Text('Error: $error'), // Handle errors
      ),
    );
  }
}

// re-load all dbcaches to get fresh copy of data
// this is needed mainly for jihan supervisor
class ReloadDbCacheData extends ConsumerStatefulWidget {
  const ReloadDbCacheData({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyStatefulConsumerWidgetState createState() => _MyStatefulConsumerWidgetState();
}

class _MyStatefulConsumerWidgetState extends ConsumerState<ReloadDbCacheData> {
  bool reload = false; // Example state variable

  void setLoadingStatus(bool loadingStatus) {
    setState(() {
      reload = loadingStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      reload
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator())
          : IconButton(
              onPressed: () async {
                setLoadingStatus(true);
                await resetDbCaches(context, ref);
                setLoadingStatus(false);
              },
              icon: const Icon(Icons.refresh),
            ),
      const Text(' مزامنة البيانات')
    ]);
  }
}
