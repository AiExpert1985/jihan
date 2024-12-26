import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/screen_data_notifier.dart';

/// A text data cell that is used for main screen for all features
/// if it is header, then the text will be bold and larger
/// if it is warning for user, then it will be red colored
/// if it is a column total, then the value will be put inside paranthesis
class MainScreenTextCell extends StatelessWidget {
  final dynamic data;
  final bool isExpanded;
  final bool isHeader;
  final bool isWarning;
  final bool isColumnTotal;
  final bool isHighlighted;
  final bool showTime;

  const MainScreenTextCell(
    this.data, {
    super.key,
    this.isExpanded = true,
    this.isHeader = false,
    this.isWarning = false,
    this.isColumnTotal = false,
    this.isHighlighted = false,
    this.showTime = false,
  });

  @override
  Widget build(BuildContext context) {
    String processedData;
    if (data is double || data is int) {
      processedData = doubleToStringWithComma(data);
      if (isColumnTotal) processedData = '($processedData)';
    } else if (data is DateTime) {
      if (showTime) {
        processedData = formatDateTime(data);
      } else {
        processedData = formatDate(data);
      }
    } else if (data is String) {
      processedData = data;
    } else {
      processedData = '';
    }
    Widget cell = Text(
      processedData,
      textAlign: TextAlign.center,
      style: isHeader
          ? const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            )
          : TextStyle(
              fontSize: 16,
              color: _getCellColor(isWarning, isHighlighted),
              fontWeight: FontWeight.bold),
    );
    if (isExpanded) {
      cell = Expanded(child: cell);
    }
    return cell;
  }
}

Color _getCellColor(bool isWarning, bool isHighlighted) {
  if (isWarning) {
    return Colors.red;
  }
  if (isHighlighted) {
    return const Color.fromARGB(255, 25, 150, 48);
  }
  return Colors.black;
}

/// Empty cell used as place holder in list data or list headers
class MainScreenPlaceholder extends StatelessWidget {
  final bool isExpanded;
  final double? width;

  const MainScreenPlaceholder({
    super.key,
    this.isExpanded = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell = SizedBox(width: width);
    if (isExpanded) {
      cell = Expanded(child: cell);
    }
    return cell;
  }
}

/// A clickable cell that is used for main screen for all features
/// if it is warning for user, then it will be red colored
/// this cell is clickable, when it is clicked, it runs onTap fucntion
class MainScreenClickableCell extends StatelessWidget {
  final dynamic data;
  final VoidCallback onTap;
  final bool isWarning;
  final bool isExpanded;

  const MainScreenClickableCell(
    this.data,
    this.onTap, {
    super.key,
    this.isWarning = false,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell = InkWell(
      onTap: onTap,
      child: MainScreenTextCell(
        data,
        isWarning: isWarning,
        isExpanded: false,
        isHighlighted: true,
      ),
    );
    if (isExpanded) {
      cell = Expanded(child: cell);
    }
    return cell;
  }
}

/// clickable a circled number that opens an edit form
/// used in main screen of almost all features as the button that show the item form
class MainScreenNumberedEditButton extends StatelessWidget {
  final int number;
  final Color color;
  final VoidCallback onTap;

  const MainScreenNumberedEditButton(
    this.number,
    this.onTap, {
    this.color = const Color.fromARGB(255, 86, 73, 161),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 4),
          width: 32.0, // Width of the circle
          height: 32.0, // Height of the circle
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle, // Makes the container circular
          ),
          alignment: Alignment.center, // Center the text inside the circle
          child: Text(
            number.toString(),
            style: const TextStyle(
              color: Colors.white, // Text color
              fontSize: 13.0, // Font size
            ),
            textAlign: TextAlign.center,
          ),
        ));
  }
}

/// clickable a avatar image that opens an edit form
/// used in main screen of almost all features as the button that show the item form
class MainScreenEditButton extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;

  const MainScreenEditButton(
    this.imageUrl,
    this.onTap, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        radius: 15,
        foregroundImage: CachedNetworkImageProvider(imageUrl),
      ),
    );
  }
}

// returns a cell that is used for main screen List Column title
// if it is a column total, then the value will be put inside paranthesis
class MainScreenHeaderCell extends StatelessWidget {
  final dynamic data;
  final bool isExpanded;
  final bool isColumnTotal;

  const MainScreenHeaderCell(
    this.data, {
    super.key,
    this.isExpanded = true,
    this.isColumnTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return MainScreenTextCell(
      data,
      isExpanded: isExpanded,
      isHeader: true,
      isColumnTotal: isColumnTotal,
    );
  }
}

// returns a cell that is used for main screen List Column title
// when click it sort column in descendent order, when double click it sorts column
// in ascending order
class SortableMainScreenHeaderCell extends StatelessWidget {
  final ScreenDataNotifier _screenDataNotifier;
  final String _propertyName;
  final String _title;

  const SortableMainScreenHeaderCell(this._screenDataNotifier, this._propertyName, this._title,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        child: MainScreenHeaderCell(
          _title,
          isExpanded: false,
        ),
        onDoubleTap: () {
          _screenDataNotifier.sortDataByProperty(_propertyName);
        },
        onTap: () {
          _screenDataNotifier.sortDataByProperty(_propertyName, isAscending: true);
        },
      ),
    );
  }
}
