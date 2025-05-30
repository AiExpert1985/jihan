import 'package:flutter/material.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/values/gaps.dart';

class ApproveIcon extends StatelessWidget {
  const ApproveIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Icon(Icons.check, color: Colors.green),
      VerticalGap.s,
      Text(S.of(context).approve)
    ]);
  }
}

class MainMenuIcon extends StatelessWidget {
  const MainMenuIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.menu, color: Colors.white),
      HorizontalGap.s,
      Text(
        S.of(context).main_menu,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      )
    ]);
  }
}

class HomeReturnIcon extends StatelessWidget {
  const HomeReturnIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.home, color: Colors.red, size: 30),
      HorizontalGap.s,
      Text(
        S.of(context).home_page,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      )
    ]);
  }
}

class NavigationBackButton extends StatelessWidget {
  const NavigationBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(
        S.of(context).back,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      HorizontalGap.s,
      const Icon(Icons.arrow_forward_ios_outlined, color: Colors.black, size: 30)
    ]);
  }
}

class SaveIcon extends StatelessWidget {
  const SaveIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Icon(Icons.check, color: Colors.green),
      VerticalGap.s,
      Text(S.of(context).save)
    ]);
  }
}

class CancelIcon extends StatelessWidget {
  const CancelIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Icon(
        Icons.close,
        color: Colors.red,
      ),
      VerticalGap.s,
      Text(S.of(context).cancel),
    ]);
  }
}

class DeleteIcon extends StatelessWidget {
  const DeleteIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.delete, color: Colors.red),
        VerticalGap.s,
        Text(S.of(context).delete),
      ],
    );
  }
}

class AddIcon extends StatelessWidget {
  const AddIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.add, color: Colors.white),
        VerticalGap.s,
        Text(S.of(context).add),
      ],
    );
  }
}

class SearchIcon extends StatelessWidget {
  const SearchIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.search, color: Colors.red),
        VerticalGap.s,
        Text(S.of(context).search),
      ],
    );
  }
}

class ReportsIcon extends StatelessWidget {
  const ReportsIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.report, color: Colors.red),
        VerticalGap.s,
        Text(S.of(context).reports),
      ],
    );
  }
}

class AddImageIcon extends StatelessWidget {
  const AddImageIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.image),
        VerticalGap.s,
        Text(S.of(context).add),
      ],
    );
  }
}

class NewIemIcon extends StatelessWidget {
  const NewIemIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.add,
          color: Colors.green,
          size: 25,
        ),
        VerticalGap.s,
        Text(S.of(context).new_item),
      ],
    );
  }
}

class EditIcon extends StatelessWidget {
  const EditIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.edit_document,
          color: Colors.orangeAccent,
          size: 25,
        ),
        VerticalGap.s,
        Text(S.of(context).edit),
      ],
    );
  }
}

class PrintIcon extends StatelessWidget {
  const PrintIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image.asset(
        //   'assets/icons/buttons/print.png',
        //   width: 25,
        //   height: 22,
        // ),
        const Icon(Icons.print),
        VerticalGap.s,
        Text(S.of(context).print),
      ],
    );
  }
}

// same Icon with only difference in label
class PrintIconB extends StatelessWidget {
  const PrintIconB({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        // Image.asset(
        //   'assets/icons/buttons/print.png',
        //   width: 25,
        //   height: 22,
        // ),
        Icon(Icons.print),
        VerticalGap.s,
        Text("طباعة2"),
      ],
    );
  }
}

class PrintedIcon extends StatelessWidget {
  const PrintedIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      color: Colors.green[900],
      child: Column(children: [
        // Image.asset(
        //   'assets/icons/buttons/print.png',
        //   width: 25,
        //   height: 22,
        // ),
        const Icon(
          Icons.print,
          color: Colors.white,
        ),
        VerticalGap.s,

        Text(S.of(context).printed, style: const TextStyle(color: Colors.white)),
      ]),
    );
  }
}

class ShareIcon extends StatelessWidget {
  const ShareIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.share,
          color: Colors.blue,
        ),
        VerticalGap.s,
        Text(S.of(context).share),
      ],
    );
  }
}

class GoNextIcon extends StatelessWidget {
  const GoNextIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.navigate_next,
          color: Colors.green,
        ),
        VerticalGap.s,
        Text(S.of(context).next),
      ],
    );
  }
}

class GoPreviousIcon extends StatelessWidget {
  const GoPreviousIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.navigate_before,
          color: Colors.green,
        ),
        VerticalGap.s,
        Text(S.of(context).previous),
      ],
    );
  }
}

class GoFirstIcon extends StatelessWidget {
  const GoFirstIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.first_page,
          color: Colors.green,
        ),
        VerticalGap.s,
        Text(S.of(context).first),
      ],
    );
  }
}

class GoLastIcon extends StatelessWidget {
  const GoLastIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.last_page,
          color: Colors.green,
        ),
        VerticalGap.s,
        Text(S.of(context).last),
      ],
    );
  }
}

class LocaleAwareLogoutIcon extends StatelessWidget {
  const LocaleAwareLogoutIcon({super.key});

  @override
  Widget build(BuildContext context) {
    Locale currentLocale = Localizations.localeOf(context);
    // for arabic, we flip the direction
    if (currentLocale.languageCode == 'ar') {
      // for arabic,
      return Transform.flip(
        flipX: true,
        child: const Icon(
          Icons.logout,
          color: Colors.white,
        ),
      );
    }
    return const Icon(Icons.logout);
  }
}
