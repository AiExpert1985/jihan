import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/features/customers/model/customer.dart';
import 'package:tablets/src/features/customers/repository/customer_db_cache_provider.dart';
import 'package:tablets/src/features/customers/repository/customer_repository_provider.dart';
import 'package:tablets/src/features/home/view/home_screen.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/model/settings.dart';
import 'package:tablets/src/features/settings/repository/settings_db_cache_provider.dart';
import 'package:tablets/src/features/settings/repository/settings_repository_provider.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';
import 'package:tablets/src/features/counters/services/counter_migration_service.dart';

final paymentValues = [PaymentType.credit.name, PaymentType.cash.name];
final currencyValues = [Currency.dinar.name, Currency.dollar.name];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsFormDataProvider);
    final settingDataNotifier = ref.read(settingsFormDataProvider.notifier);
    if (settingDataNotifier.data.isEmpty) {
      return const HomeScreen();
    }
    return const AppScreenFrame(SettingsParameters());
  }
}

class SettingsParameters extends ConsumerWidget {
  const SettingsParameters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(settingsRepositoryProvider);
    final settingDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final dbCache = ref.read(settingsDbCacheProvider.notifier);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 15),
        child: Column(
          children: [
            Container(
              height: 550,
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 50),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FirstColumn(),
                  VerticalDivider(),
                  SecondColumn(),
                  VerticalDivider(),
                  ThirdColumn(),
                ],
              ),
            ),
            const Spacer(),

            // button only saves changes to Db, in case user didn't save, then his changes
            // will be only available in the current settings
            Center(
              child: IconButton(
                onPressed: () async {
                  final settingsData = settingDataNotifier.data;
                  repository.updateItem(Settings.fromMap(settingsData));

                  // success(context, S.of(context).db_success_updaging_doc);
                  // finally we update the dbCache to mirror the change in db
                  dbCache.update(settingsData, DbCacheOperationTypes.edit);
                },
                icon: const SaveIcon(),
              ),
            ),
            VerticalGap.xl,
            const Text('version 0.80', style: TextStyle(fontSize: 8)),
          ],
        ),
      ),
    );
  }
}

class FirstColumn extends ConsumerWidget {
  const FirstColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SwitchButton(S.of(context).hide_amount_as_text, hideTransactionAmountAsTextKey),
        VerticalGap.xl,
        SwitchButton(S.of(context).hide_totals_row, hideMainScreenColumnTotalsKey),
        VerticalGap.xl,
        SwitchButton(S.of(context).hide_product_buying_price, hideProductBuyingPriceKey),
        VerticalGap.xl,
        SwitchButton(S.of(context).hide_customer_profit, hideCustomerProfitKey),
        VerticalGap.xl,
        SwitchButton(S.of(context).hide_product_profit, hideProductProfitKey),
        VerticalGap.xl,
        SwitchButton(S.of(context).hide_salesman_profit, hideSalesmanProfitKey),
        VerticalGap.xl,
        SwitchButton(S.of(context).show_barcode_when_printing, hideCompanyUrlBarCodeKey),
      ],
    );
  }
}

class SecondColumn extends ConsumerWidget {
  const SecondColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        RadioButtons(S.of(context).transaction_payment_type, settingsPaymentTypeKey, paymentValues),
        VerticalGap.xl,
        RadioButtons(S.of(context).settings_currency, settingsCurrencyKey, currencyValues),
        VerticalGap.xl,
        SettingsInputField(S.of(context).max_debt_duration_allowed, settingsMaxDebtDurationKey,
            FieldDataType.num.name),
        // SliderButton(
        //     S.of(context).max_debt_duration_allowed, settingsMaxDebtDurationKey, 0, 60, 30),
        VerticalGap.xl,
        SliderButton(S.of(context).num_printed_invoices, printedCustomerInvoicesKey, 0, 10, 5),
        VerticalGap.xl,
        SliderButton(S.of(context).num_printed_receipts, printedCustomerReceiptsKey, 0, 10, 5),
        VerticalGap.xxl,
      ],
    );
  }
}

class ThirdColumn extends ConsumerWidget {
  const ThirdColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SettingsInputField(S.of(context).max_debt_amount_allowed, settingsMaxDebtAmountKey,
            FieldDataType.num.name),
        VerticalGap.xl,
        SettingsInputField(
            S.of(context).settings_company_url, companyUrlKey, FieldDataType.text.name),
        VerticalGap.xl,
        SettingsInputField(S.of(context).settings_main_page_greeting, mainPageGreetingTextKey,
            FieldDataType.text.name),
        VerticalGap.xl,
        // Counter initialization button for multi-user setup
        ElevatedButton(
          onPressed: () async {
            try {
              final migrationService = ref.read(counterMigrationServiceProvider);
              await migrationService.initializeAllCounters(context, ref);
              if (context.mounted) {
                successUserMessage(context, 'تم تثبيت ارقام القوائم بنجاح');
              }
            } catch (e) {
              if (context.mounted) {
                failureUserMessage(context, 'خطأ في تثبيت الارقام: $e');
              }
            }
          },
          child: const Text('تثبيت ارقام القوائم القادمة'),
        ),
      ],
    );
  }
}

class SettingLabel extends ConsumerWidget {
  const SettingLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 160,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}

class SliderButton extends ConsumerWidget {
  const SliderButton(this.label, this.propertyName, this.minNumber, this.maxNumber, this.intervals,
      {super.key});

  final String label;
  final String propertyName;
  final double minNumber;
  final double maxNumber;
  final double intervals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final currentValue = settingsDataNotifier.getProperty(propertyName);
    ref.watch(settingsFormDataProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SettingLabel(label),
        HorizontalGap.l,
        SfSlider(
          min: minNumber,
          max: maxNumber,
          value: currentValue,
          interval: intervals,
          // showTicks: true,
          showLabels: true,
          enableTooltip: true,
          // minorTicksPerInterval: 1,
          onChanged: (dynamic value) {
            settingsDataNotifier.updateProperties({propertyName: value.round()});
          },
        ),
      ],
    );
  }
}

class RadioButtons extends ConsumerWidget {
  const RadioButtons(this.label, this.propertyName, this.values, {super.key});
  final List<String> values;
  final String label;
  final String propertyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final currentValue = settingsDataNotifier.getProperty(propertyName);
    ref.watch(settingsFormDataProvider);
    return Row(
      children: [
        SettingLabel(label),
        ...values.map(
          (buttonValue) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(translateDbTextToScreenText(context, buttonValue)),
                  VerticalGap.s,
                  Radio(
                    value: buttonValue,
                    groupValue: currentValue,
                    onChanged: (value) {
                      settingsDataNotifier.updateProperties({propertyName: value});
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class SwitchButton extends ConsumerWidget {
  const SwitchButton(this.label, this.propertyName, {super.key});
  final String label;
  final String propertyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final currentValue = settingsDataNotifier.getProperty(propertyName);
    ref.watch(settingsFormDataProvider);
    return Row(
      children: [
        SettingLabel(label),
        HorizontalGap.xl,
        Switch(
          value: currentValue,
          onChanged: (value) {
            settingsDataNotifier.updateProperties({propertyName: value});
          },
        ),
      ],
    );
  }
}

class SettingsInputField extends ConsumerStatefulWidget {
  const SettingsInputField(this.label, this.propertyName, this.dataType, {super.key});

  final String label;
  final String propertyName;
  final String dataType;

  @override
  ConsumerState<SettingsInputField> createState() => _SettingsInputFieldState();
}

class _SettingsInputFieldState extends ConsumerState<SettingsInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final settingsDataNotifier = ref.read(settingsFormDataProvider.notifier);
    dynamic currentValue = settingsDataNotifier.getProperty(widget.propertyName);
    if (widget.dataType == FieldDataType.num.name) {
      currentValue = currentValue.toString();
    }
    _controller = TextEditingController(text: currentValue);
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the controller
    super.dispose();
  }

  // when the date duration is update, we update that for all current clients
// that was the request of Jihan - Shamil
  void _updateDurationForAllClients(WidgetRef ref, double value) async {
    final customersDbCache = ref.watch(customerDbCacheProvider);
    final customerRepo = ref.watch(customerRepositoryProvider);
    infoUserMessage(context, "الرجاء الانتظار عدة دقائق حتى اكتمال التحديث");
    _updateSettings(value);
    for (var customerMap in customersDbCache) {
      customerMap['paymentDurationLimit'] = value;
      await customerRepo.updateItem(Customer.fromMap(customerMap));
    }
    if (mounted) {
      successUserMessage(context, 'تم تحديث مدة الدين لجميع الزبائن');
    }
  }

  // this function updates the settings itself (the new value of debtDuration is saved in firebase)
  void _updateSettings(double value) {
    final repository = ref.read(settingsRepositoryProvider);
    final settingDataNotifier = ref.read(settingsFormDataProvider.notifier);
    final dbCache = ref.read(settingsDbCacheProvider.notifier);
    final settingsData = settingDataNotifier.data;
    settingsData['maxDebtDuration'] = value;
    repository.updateItem(Settings.fromMap(settingsData));

    // success(context, S.of(context).db_success_updaging_doc);
    // finally we update the dbCache to mirror the change in db
    dbCache.update(settingsData, DbCacheOperationTypes.edit);
  }

  @override
  Widget build(BuildContext context) {
    final settingsDataNotifier = ref.watch(settingsFormDataProvider.notifier);

    return Row(
      children: [
        SettingLabel(widget.label),
        HorizontalGap.xl,
        SizedBox(
          width: 200,
          child: FormBuilderTextField(
            name: widget.propertyName,
            textAlign: TextAlign.center,
            onSubmitted: (value) {
              // this filed is only for changing the values of debtDuration
              // doesn't used for any other filed
              if (widget.propertyName == settingsMaxDebtDurationKey) {
                double duration = double.tryParse(value ?? '21') ?? 21;
                _updateDurationForAllClients(ref, duration);
              }
            },
            onChanged: (value) {
              if (widget.propertyName == settingsMaxDebtDurationKey) {
                // if this is the debt duration, return. because it is handled
                // by the onSubmitted function
                return;
              }
              if (value == null) return; // Check for null
              dynamic newValue;
              if (widget.dataType == FieldDataType.num.name) {
                try {
                  newValue = double.parse(value);
                } catch (e) {
                  errorPrint('value is not a number');
                  return; // Exit if parsing fails
                }
              } else {
                newValue = value;
              }
              // Update the controller text only if it's different
              if (_controller.text != newValue.toString()) {
                _controller.text = newValue.toString();
              }
              settingsDataNotifier.updateProperties({widget.propertyName: newValue});
            },
            decoration: formFieldDecoration(),
            controller: _controller,
          ),
        )
      ],
    );
  }
}
