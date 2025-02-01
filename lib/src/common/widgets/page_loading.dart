import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/values/gaps.dart';

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
