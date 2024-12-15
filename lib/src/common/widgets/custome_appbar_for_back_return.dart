import 'package:flutter/material.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';

PreferredSizeWidget buildArabicAppBar(
    BuildContext context, final void Function() backOnTapFn, final void Function() homeOnTapFn) {
  return AppBar(
    leadingWidth: 140,
    automaticallyImplyLeading: false,
    leading: Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: IconButton(onPressed: homeOnTapFn, icon: const HomeReturnIcon()),
      ),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: IconButton(onPressed: backOnTapFn, icon: const NavigationBackButton()),
      ),
    ],
  );
}
