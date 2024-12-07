import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/providers/page_is_loading_notifier.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/repository/settings_repository_provider.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';

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
    // Access the notifier using ref.read
    _setGreeting(context, ref);
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
          VerticalGap.xl,
          Text(
            customizableGreeting,
            style: const TextStyle(fontSize: 24),
          ),
          VerticalGap.xxl,
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
