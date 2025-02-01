import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/features/settings/controllers/settings_form_data_notifier.dart';
import 'package:tablets/src/features/settings/view/settings_keys.dart';

class HomeGreeting extends ConsumerWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsFormDataProvider);
    final settingDataNotifier = ref.read(settingsFormDataProvider.notifier);
    return Container(
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
            settingDataNotifier.getProperty(mainPageGreetingTextKey) ?? S.of(context).greeting,
            style: const TextStyle(fontSize: 24),
          ),
          VerticalGap.xxl,
        ],
      ),
    );
  }
}
