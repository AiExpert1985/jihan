import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/functions/db_cache_inialization.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/background_color.dart';
import 'package:tablets/src/common/providers/image_picker_provider.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/providers/text_editing_controllers_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/repository/settings_repository_provider.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';
import 'package:tablets/src/features/transactions/controllers/form_navigator_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_form_data_notifier.dart';
import 'package:tablets/src/features/transactions/repository/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/view/transaction_show_form.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // we watch pageIsLoadingNotifier for one reason, which is that when we are
    // in home page, and move to another page
    // a load spinner will be shown in home until we move to target page
    ref.watch(pageIsLoadingNotifier);
    final pageIsLoading = ref.read(pageIsLoadingNotifier);
    final screenWidget = pageIsLoading ? const PageLoading() : const HomeScreenGreeting();
    return AppScreenFrame(screenWidget);
  }
}

/// I use this widget for two reasons
/// for home screen when app starts
/// for cases when refreshing page, since we need user to press a button in the side bar
/// to load data from DB to dbCache, so after a refresh we display this widget, which forces
/// user to go the sidebar and press a button to continue working

class HomeScreenGreeting extends ConsumerStatefulWidget {
  const HomeScreenGreeting({super.key});

  @override
  ConsumerState<HomeScreenGreeting> createState() => _HomeScreenGreetingState();
}

class _HomeScreenGreetingState extends ConsumerState<HomeScreenGreeting> {
  String customizableGreeting = '';

  void _setGreeting(BuildContext context, WidgetRef ref) async {
    String greeting = S.of(context).greeting;
    final settingDataNotifier = ref.read(settingsFormDataProvider.notifier);
    if (settingDataNotifier.data.isNotEmpty) {
      greeting = settingDataNotifier.getProperty(mainPageGreetingTextKey) ?? greeting;
      setState(() {
        customizableGreeting = greeting;
      });
    } else {
      final repository = ref.read(settingsRepositoryProvider);
      final allSettings = await repository.fetchItemListAsMaps();
      if (context.mounted) {
        greeting = allSettings[0][mainPageGreetingTextKey] ?? greeting;
        setState(() {
          customizableGreeting = greeting;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // if the greeting is the defautl, then change it
    if (customizableGreeting == S.of(context).greeting) {
      _setGreeting(context, ref);
    }
    return Container(
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomerFastAccessButtons(),
              VendorFastAccessButtons(),
              InternalFastAccessButtons(),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(5),
            width: 800,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  // margin: const EdgeInsets.all(10),
                  width: double.infinity,
                  height: 300, // here I used width intentionally
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.scaleDown),
                ),
                VerticalGap.xl,
                Text(
                  customizableGreeting,
                  style: const TextStyle(fontSize: 24),
                ),
                VerticalGap.xxl,
              ],
            ),
          ),
          const SizedBox()
        ],
      ),
    );
  }
}

class PageLoading extends ConsumerWidget {
  const PageLoading({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            // margin: const EdgeInsets.all(10),
            width: double.infinity,
            height: 300, // here I used width intentionally
            child: Image.asset('assets/images/logo.png', fit: BoxFit.scaleDown),
          ),
          VerticalGap.l,
          const CircularProgressIndicator(),
          VerticalGap.xl,
          Text(
            S.of(context).loading_data,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class EmptyPage extends ConsumerWidget {
  const EmptyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            // margin: const EdgeInsets.all(10),
            width: double.infinity,
            height: 300, // here I used width intentionally
            child: Image.asset('assets/images/empty.png', fit: BoxFit.scaleDown),
          ),
          VerticalGap.xl,
          Text(
            S.of(context).no_data_available,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
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
          FastAccessButton(
            TransactionType.customerInvoice.name,
            textColor: Colors.green[50],
          ),
          VerticalGap.l,
          FastAccessButton(
            TransactionType.customerReceipt.name,
            textColor: Colors.red[50],
          ),
          VerticalGap.l,
          FastAccessButton(
            TransactionType.customerReturn.name,
            textColor: Colors.grey[300],
          ),
          VerticalGap.l,
          FastAccessButton(
            TransactionType.gifts.name,
            textColor: Colors.orange[50],
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
          FastAccessButton(
            TransactionType.vendorInvoice.name,
            textColor: Colors.green[50],
          ),
          VerticalGap.l,
          FastAccessButton(
            TransactionType.vendorReceipt.name,
            textColor: Colors.red[50],
          ),
          VerticalGap.l,
          FastAccessButton(
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
          FastAccessButton(
            TransactionType.expenditures.name,
            textColor: Colors.green[50],
          ),
          VerticalGap.l,
          FastAccessButton(
            TransactionType.damagedItems.name,
            textColor: Colors.red[50],
          ),
        ],
      ),
    );
  }
}

class FastAccessButton extends ConsumerWidget {
  const FastAccessButton(this.formType, {this.textColor, super.key});
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
    fromNavigator.isReadOnly = false;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onPressed: () async {
        // make sure dbCaches and settings are initialized
        await initializeAllDbCaches(context, ref);
        if (context.mounted) {
          initializeSettings(context, ref);
        }
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
