import 'package:flutter/material.dart';

abstract class ScreenDataController {
  void setFeatureScreenData(BuildContext context);

  Map<String, dynamic> getItemScreenData(BuildContext context, Map<String, dynamic> itemData);
}
