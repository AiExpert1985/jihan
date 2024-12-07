import 'package:anydrawer/anydrawer.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/classes/screen_data_filters.dart';
import 'package:tablets/src/common/interfaces/screen_controller.dart';
import 'package:tablets/src/common/providers/screen_data_notifier.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/search_fields/edit_search_box.dart';

class SearchForm extends StatelessWidget {
  const SearchForm(this._title, this._drawerController, this._filterController,
      this._screenDataController, this._screenDataNotifier, this._bodyWidgets,
      {super.key});
  final String _title;
  final AnyDrawerController _drawerController;
  final ScreenDataFilters _filterController;
  final ScreenDataController _screenDataController;
  final ScreenDataNotifier _screenDataNotifier;
  final List<Widget> _bodyWidgets;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTitle(_title),
            _buildBody(),
            _buildButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SizedBox(
      child: Column(
        children: [
          ..._bodyWidgets,
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            _screenDataController.setFeatureScreenData(context);
            final screenData = _screenDataNotifier.data as List<Map<String, dynamic>>;
            final filteredScreenData = _filterController.applyListFilter(screenData);
            _screenDataNotifier.set(filteredScreenData);
          },
          icon: const ApproveIcon(),
        ),
        HorizontalGap.l,
        IconButton(
          onPressed: () {
            _screenDataController.setFeatureScreenData(context);
            _filterController.reset();
            _drawerController.close();
          },
          icon: const CancelIcon(),
        ),
      ],
    );
  }

  Widget _buildTitle(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class FilterRow extends StatelessWidget {
  const FilterRow(this._label, this._firstFilter, {this.secondFilter, super.key});

  final String _label;
  final Widget _firstFilter;
  final Widget? secondFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 100,
          padding: const EdgeInsets.all(5),
          child: Text(_label, style: const TextStyle(fontSize: 18)),
        ),
        HorizontalGap.l,
        _firstFilter,
        if (secondFilter != null) HorizontalGap.l,
        if (secondFilter != null) secondFilter!,
      ],
    );
  }
}

class NumberMatchSearchField extends StatelessWidget {
  const NumberMatchSearchField(
      this._filterController, this._filterName, this._propertyName, this._label,
      {super.key});
  final ScreenDataFilters _filterController;
  final String _propertyName;
  final String _filterName;
  final String _label;
  @override
  Widget build(BuildContext context) {
    final filter = _buildFilter();
    return FilterRow(_label, filter);
  }

  Widget _buildFilter() {
    return SearchInputField(
      initialValue: _filterController.getFilterValue(_filterName),
      onChangedFn: (value) {
        _filterController.updateFilters(_filterName, _propertyName, FilterCriteria.equals, value);
      },
      dataType: FieldDataType.num,
      name: _filterName,
      isRequired: false,
    );
  }
}

class TextSearchField extends StatelessWidget {
  const TextSearchField(this._filterController, this._filterName, this._propertyName, this._label,
      {super.key});
  final ScreenDataFilters _filterController;
  final String _propertyName;
  final String _filterName;
  final String _label;
  @override
  Widget build(BuildContext context) {
    final filter = _buildFilter();
    return FilterRow(_label, filter);
  }

  Widget _buildFilter() {
    return SearchInputField(
      initialValue: _filterController.getFilterValue(_filterName),
      onChangedFn: (value) {
        _filterController.updateFilters(_filterName, _propertyName, FilterCriteria.contains, value);
      },
      dataType: FieldDataType.text,
      name: _filterName,
      isRequired: false,
    );
  }
}

class NumberRangeSearchField extends StatelessWidget {
  const NumberRangeSearchField(this._filterController, this._firstFilterName,
      this._secondFilterName, this._propertyName, this._label,
      {super.key});
  final ScreenDataFilters _filterController;
  final String _propertyName;
  final String _firstFilterName;
  final String _secondFilterName;
  final String _label;

  @override
  Widget build(BuildContext context) {
    final firstFilter = _buildFirstFilter(context);
    final secondFilter = _buildSecondFilter(context);
    return FilterRow(_label, firstFilter, secondFilter: secondFilter);
  }

  Widget _buildFirstFilter(BuildContext context) {
    return SearchInputField(
      initialValue: _filterController.getFilterValue(_firstFilterName),
      label: S.of(context).from,
      onChangedFn: (value) {
        _filterController.updateFilters(
            _firstFilterName, _propertyName, FilterCriteria.moreThanOrEqual, value);
      },
      dataType: FieldDataType.num,
      name: _firstFilterName,
      isRequired: false,
    );
  }

  Widget _buildSecondFilter(BuildContext context) {
    return SearchInputField(
      initialValue: _filterController.getFilterValue(_secondFilterName),
      label: S.of(context).to,
      onChangedFn: (value) {
        _filterController.updateFilters(
            _secondFilterName, _propertyName, FilterCriteria.lessThanOrEqual, value);
      },
      dataType: FieldDataType.num,
      name: _secondFilterName,
      isRequired: false,
    );
  }
}

class DateRangeSearchField extends StatelessWidget {
  const DateRangeSearchField(
      this._filterController, this._firstFilterName, this._secondFilterName, this._propertyName,
      {super.key});
  final ScreenDataFilters _filterController;
  final String _propertyName;
  final String _firstFilterName;
  final String _secondFilterName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black38,
          width: 1.0, // Border width
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: CalendarDatePicker2(
        config: CalendarDatePicker2Config(
          calendarType: CalendarDatePicker2Type.range,
        ),
        value: [
          _filterController.getFilterValue(_firstFilterName),
          _filterController.getFilterValue(_secondFilterName),
        ],
        onValueChanged: (dates) {
          if (dates.isEmpty) return;
          _filterController.updateFilters(
              _firstFilterName, _propertyName, FilterCriteria.dateAfter, dates[0]);
          if (dates.length == 1) return;
          _filterController.updateFilters(
              _secondFilterName, _propertyName, FilterCriteria.dateBefore, dates[1]);
        },
      ),
    );
  }
}
