import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/values/gaps.dart';

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
