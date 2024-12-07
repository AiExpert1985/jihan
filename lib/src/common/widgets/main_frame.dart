import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/providers/page_title_provider.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/main_drawer.dart';

class AppScreenFrame extends ConsumerWidget {
  const AppScreenFrame(this.listWidget, {this.buttonsWidget, super.key});
  final Widget listWidget;
  final Widget? buttonsWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageTitle = ref.watch(pageTitleProvider);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, 65.0), // Height of the AppBar
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9, // Set width to 90% of screen width
          alignment: Alignment.center,
          child: AppBar(
            title: _buildPageTitle(context, pageTitle),
            leadingWidth: 140,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const MainMenuIcon(),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(), //signout(ref),
                icon: const LocaleAwareLogoutIcon(),
                label: Text(
                  S.of(context).logout,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      drawer: const MainDrawer(),
      body: Container(
        padding: const EdgeInsets.all(30),
        child: MainScreenBody(listWidget, buttonsWidget),
      ),
    );
  }
}

class MainScreenBody extends ConsumerWidget {
  const MainScreenBody(this.listWidget, this.buttonsWidget, {super.key});
  final Widget listWidget;
  final Widget? buttonsWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        listWidget,
        if (buttonsWidget != null)
          Positioned(
            bottom: 0,
            left: 0,
            child: buttonsWidget!,
          )
      ],
    );
  }
}

Widget _buildPageTitle(BuildContext context, String pageTitle) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center, // Center the title
    children: [
      Expanded(
        child: Container(
          alignment: Alignment.center, // Center the title text
          child: Text(
            pageTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
            ),
          ),
        ),
      ),
    ],
  );
}
