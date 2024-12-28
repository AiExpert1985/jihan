// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Name`
  String get name {
    return Intl.message(
      'Name',
      name: 'name',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message(
      'Email',
      name: 'email',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message(
      'Password',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message(
      'Login',
      name: 'login',
      desc: '',
      args: [],
    );
  }

  /// `Sign up`
  String get signup {
    return Intl.message(
      'Sign up',
      name: 'signup',
      desc: '',
      args: [],
    );
  }

  /// `Create a new account`
  String get create_new_account {
    return Intl.message(
      'Create a new account',
      name: 'create_new_account',
      desc: '',
      args: [],
    );
  }

  /// `I already have account`
  String get i_already_have_account {
    return Intl.message(
      'I already have account',
      name: 'i_already_have_account',
      desc: '',
      args: [],
    );
  }

  /// `Add image`
  String get add_image {
    return Intl.message(
      'Add image',
      name: 'add_image',
      desc: '',
      args: [],
    );
  }

  /// `Choose image`
  String get choose_image {
    return Intl.message(
      'Choose image',
      name: 'choose_image',
      desc: '',
      args: [],
    );
  }

  /// `Add a new user`
  String get add_new_user {
    return Intl.message(
      'Add a new user',
      name: 'add_new_user',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Save changes`
  String get save_changes {
    return Intl.message(
      'Save changes',
      name: 'save_changes',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get edit {
    return Intl.message(
      'Edit',
      name: 'edit',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get search {
    return Intl.message(
      'Search',
      name: 'search',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get add {
    return Intl.message(
      'Add',
      name: 'add',
      desc: '',
      args: [],
    );
  }

  /// `Reports`
  String get reports {
    return Intl.message(
      'Reports',
      name: 'reports',
      desc: '',
      args: [],
    );
  }

  /// `hi`
  String get greeting {
    return Intl.message(
      'hi',
      name: 'greeting',
      desc: '',
      args: [],
    );
  }

  /// `logout`
  String get logout {
    return Intl.message(
      'logout',
      name: 'logout',
      desc: '',
      args: [],
    );
  }

  /// `Privilage`
  String get user_privilage {
    return Intl.message(
      'Privilage',
      name: 'user_privilage',
      desc: '',
      args: [],
    );
  }

  /// `Page is not found`
  String get page_not_found {
    return Intl.message(
      'Page is not found',
      name: 'page_not_found',
      desc: '',
      args: [],
    );
  }

  /// `Go back to home page`
  String get go_home_page {
    return Intl.message(
      'Go back to home page',
      name: 'go_home_page',
      desc: '',
      args: [],
    );
  }

  /// `Transactions`
  String get transactions {
    return Intl.message(
      'Transactions',
      name: 'transactions',
      desc: '',
      args: [],
    );
  }

  /// `Products`
  String get products {
    return Intl.message(
      'Products',
      name: 'products',
      desc: '',
      args: [],
    );
  }

  /// `Salesmen`
  String get salesmen_movement {
    return Intl.message(
      'Salesmen',
      name: 'salesmen_movement',
      desc: '',
      args: [],
    );
  }

  /// `Pending transactions`
  String get pending_transactions {
    return Intl.message(
      'Pending transactions',
      name: 'pending_transactions',
      desc: '',
      args: [],
    );
  }

  /// `Categories`
  String get categories {
    return Intl.message(
      'Categories',
      name: 'categories',
      desc: '',
      args: [],
    );
  }

  /// `Select category`
  String get category_selection {
    return Intl.message(
      'Select category',
      name: 'category_selection',
      desc: '',
      args: [],
    );
  }

  /// `Failure`
  String get failure {
    return Intl.message(
      'Failure',
      name: 'failure',
      desc: '',
      args: [],
    );
  }

  /// `Success`
  String get success {
    return Intl.message(
      'Success',
      name: 'success',
      desc: '',
      args: [],
    );
  }

  /// `info`
  String get info {
    return Intl.message(
      'info',
      name: 'info',
      desc: '',
      args: [],
    );
  }

  /// `Warning`
  String get warning {
    return Intl.message(
      'Warning',
      name: 'warning',
      desc: '',
      args: [],
    );
  }

  /// `Tablets, where accounting started`
  String get slogan {
    return Intl.message(
      'Tablets, where accounting started',
      name: 'slogan',
      desc: '',
      args: [],
    );
  }

  /// `code`
  String get product_code {
    return Intl.message(
      'code',
      name: 'product_code',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get product_name {
    return Intl.message(
      'Name',
      name: 'product_name',
      desc: '',
      args: [],
    );
  }

  /// `Retail price`
  String get product_sell_retail_price {
    return Intl.message(
      'Retail price',
      name: 'product_sell_retail_price',
      desc: '',
      args: [],
    );
  }

  /// `Wholesale price`
  String get product_sell_whole_price {
    return Intl.message(
      'Wholesale price',
      name: 'product_sell_whole_price',
      desc: '',
      args: [],
    );
  }

  /// `Packaging type`
  String get product_package_type {
    return Intl.message(
      'Packaging type',
      name: 'product_package_type',
      desc: '',
      args: [],
    );
  }

  /// `Package weight`
  String get product_package_weight {
    return Intl.message(
      'Package weight',
      name: 'product_package_weight',
      desc: '',
      args: [],
    );
  }

  /// `Number of item in eacch package`
  String get product_num_items_inside_package {
    return Intl.message(
      'Number of item in eacch package',
      name: 'product_num_items_inside_package',
      desc: '',
      args: [],
    );
  }

  /// `Alert when available more than`
  String get product_alert_when_exceeds {
    return Intl.message(
      'Alert when available more than',
      name: 'product_alert_when_exceeds',
      desc: '',
      args: [],
    );
  }

  /// `Alert when available is less than`
  String get product_altert_when_less_than {
    return Intl.message(
      'Alert when available is less than',
      name: 'product_altert_when_less_than',
      desc: '',
      args: [],
    );
  }

  /// `Salesman commision`
  String get product_salesman_commission {
    return Intl.message(
      'Salesman commision',
      name: 'product_salesman_commission',
      desc: '',
      args: [],
    );
  }

  /// `Product photos`
  String get product_photos {
    return Intl.message(
      'Product photos',
      name: 'product_photos',
      desc: '',
      args: [],
    );
  }

  /// `Product category`
  String get product_category {
    return Intl.message(
      'Product category',
      name: 'product_category',
      desc: '',
      args: [],
    );
  }

  /// `Product subcategory`
  String get product_subcategory {
    return Intl.message(
      'Product subcategory',
      name: 'product_subcategory',
      desc: '',
      args: [],
    );
  }

  /// `Product initial quantity`
  String get product_initial_quantitiy {
    return Intl.message(
      'Product initial quantity',
      name: 'product_initial_quantitiy',
      desc: '',
      args: [],
    );
  }

  /// `Password should be at least 6 characters`
  String get input_validation_error_message_for_password {
    return Intl.message(
      'Password should be at least 6 characters',
      name: 'input_validation_error_message_for_password',
      desc: '',
      args: [],
    );
  }

  /// `Name should be at least 4 characters`
  String get input_validation_error_message_for_user_name {
    return Intl.message(
      'Name should be at least 4 characters',
      name: 'input_validation_error_message_for_user_name',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid email adress`
  String get input_validation_error_message_for_email {
    return Intl.message(
      'Please enter a valid email adress',
      name: 'input_validation_error_message_for_email',
      desc: '',
      args: [],
    );
  }

  /// `You must select user privilage`
  String get input_validation_error_message_for_user_privilage {
    return Intl.message(
      'You must select user privilage',
      name: 'input_validation_error_message_for_user_privilage',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid word`
  String get input_validation_error_message_for_text {
    return Intl.message(
      'Enter a valid word',
      name: 'input_validation_error_message_for_text',
      desc: '',
      args: [],
    );
  }

  /// `Enter an integer number`
  String get input_validation_error_message_for_numbers {
    return Intl.message(
      'Enter an integer number',
      name: 'input_validation_error_message_for_numbers',
      desc: '',
      args: [],
    );
  }

  /// `Select a date`
  String get input_validation_error_message_for_date {
    return Intl.message(
      'Select a date',
      name: 'input_validation_error_message_for_date',
      desc: '',
      args: [],
    );
  }

  /// `An error happend while importing images`
  String get error_importing_image {
    return Intl.message(
      'An error happend while importing images',
      name: 'error_importing_image',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Category`
  String get category {
    return Intl.message(
      'Category',
      name: 'category',
      desc: '',
      args: [],
    );
  }

  /// `Add a new Category`
  String get add_new_category {
    return Intl.message(
      'Add a new Category',
      name: 'add_new_category',
      desc: '',
      args: [],
    );
  }

  /// `Update category`
  String get update_category {
    return Intl.message(
      'Update category',
      name: 'update_category',
      desc: '',
      args: [],
    );
  }

  /// `There is no contents`
  String get screen_is_empty {
    return Intl.message(
      'There is no contents',
      name: 'screen_is_empty',
      desc: '',
      args: [],
    );
  }

  /// `Not found in database`
  String get search_not_found_in_db {
    return Intl.message(
      'Not found in database',
      name: 'search_not_found_in_db',
      desc: '',
      args: [],
    );
  }

  /// `Error happened while login`
  String get db_error_login {
    return Intl.message(
      'Error happened while login',
      name: 'db_error_login',
      desc: '',
      args: [],
    );
  }

  /// `An error happened while adding to the database`
  String get db_error_adding_doc {
    return Intl.message(
      'An error happened while adding to the database',
      name: 'db_error_adding_doc',
      desc: '',
      args: [],
    );
  }

  /// `An error happened while updating the database`
  String get db_error_updating_doc {
    return Intl.message(
      'An error happened while updating the database',
      name: 'db_error_updating_doc',
      desc: '',
      args: [],
    );
  }

  /// `Document was added successfully`
  String get db_success_adding_doc {
    return Intl.message(
      'Document was added successfully',
      name: 'db_success_adding_doc',
      desc: '',
      args: [],
    );
  }

  /// `Document was saved successfully`
  String get db_success_saving_doc {
    return Intl.message(
      'Document was saved successfully',
      name: 'db_success_saving_doc',
      desc: '',
      args: [],
    );
  }

  /// `An error happened while saving from db`
  String get db_error_saving_doc {
    return Intl.message(
      'An error happened while saving from db',
      name: 'db_error_saving_doc',
      desc: '',
      args: [],
    );
  }

  /// `Document was updated successfully `
  String get db_success_updaging_doc {
    return Intl.message(
      'Document was updated successfully ',
      name: 'db_success_updaging_doc',
      desc: '',
      args: [],
    );
  }

  /// `Document was deleted successfully`
  String get db_success_deleting_doc {
    return Intl.message(
      'Document was deleted successfully',
      name: 'db_success_deleting_doc',
      desc: '',
      args: [],
    );
  }

  /// `An error happened while deleting from db`
  String get db_error_deleting_doc {
    return Intl.message(
      'An error happened while deleting from db',
      name: 'db_error_deleting_doc',
      desc: '',
      args: [],
    );
  }

  /// `An error happened while downloading files from database`
  String get db_error_downloading_files {
    return Intl.message(
      'An error happened while downloading files from database',
      name: 'db_error_downloading_files',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to delete`
  String get alert_before_delete {
    return Intl.message(
      'Do you want to delete',
      name: 'alert_before_delete',
      desc: '',
      args: [],
    );
  }

  /// `Transaction type`
  String get transaction_type {
    return Intl.message(
      'Transaction type',
      name: 'transaction_type',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get transaction_name {
    return Intl.message(
      'Name',
      name: 'transaction_name',
      desc: '',
      args: [],
    );
  }

  /// `Date`
  String get transaction_date {
    return Intl.message(
      'Date',
      name: 'transaction_date',
      desc: '',
      args: [],
    );
  }

  /// `Number`
  String get transaction_number {
    return Intl.message(
      'Number',
      name: 'transaction_number',
      desc: '',
      args: [],
    );
  }

  /// `Amount`
  String get transaction_amount {
    return Intl.message(
      'Amount',
      name: 'transaction_amount',
      desc: '',
      args: [],
    );
  }

  /// `Currency`
  String get transaction_currency {
    return Intl.message(
      'Currency',
      name: 'transaction_currency',
      desc: '',
      args: [],
    );
  }

  /// `Notes`
  String get transaction_notes {
    return Intl.message(
      'Notes',
      name: 'transaction_notes',
      desc: '',
      args: [],
    );
  }

  /// `Customer Name`
  String get transaction_customer_invoice_name {
    return Intl.message(
      'Customer Name',
      name: 'transaction_customer_invoice_name',
      desc: '',
      args: [],
    );
  }

  /// `Payment type`
  String get transaction_payment_type {
    return Intl.message(
      'Payment type',
      name: 'transaction_payment_type',
      desc: '',
      args: [],
    );
  }

  /// `Salesman`
  String get transaction_salesman {
    return Intl.message(
      'Salesman',
      name: 'transaction_salesman',
      desc: '',
      args: [],
    );
  }

  /// `Discount`
  String get transaction_discount {
    return Intl.message(
      'Discount',
      name: 'transaction_discount',
      desc: '',
      args: [],
    );
  }

  /// `Item`
  String get transaction_item_name {
    return Intl.message(
      'Item',
      name: 'transaction_item_name',
      desc: '',
      args: [],
    );
  }

  /// `Quantity`
  String get transaction_item_quantity {
    return Intl.message(
      'Quantity',
      name: 'transaction_item_quantity',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get transaction_item_price {
    return Intl.message(
      'Price',
      name: 'transaction_item_price',
      desc: '',
      args: [],
    );
  }

  /// `Gift`
  String get transaction_item_gift {
    return Intl.message(
      'Gift',
      name: 'transaction_item_gift',
      desc: '',
      args: [],
    );
  }

  /// `Total price`
  String get transaction_item_total_price {
    return Intl.message(
      'Total price',
      name: 'transaction_item_total_price',
      desc: '',
      args: [],
    );
  }

  /// `Select a date`
  String get date_picker_hint {
    return Intl.message(
      'Select a date',
      name: 'date_picker_hint',
      desc: '',
      args: [],
    );
  }

  /// `Cash`
  String get transaction_payment_cash {
    return Intl.message(
      'Cash',
      name: 'transaction_payment_cash',
      desc: '',
      args: [],
    );
  }

  /// `Credit`
  String get transaction_payment_credit {
    return Intl.message(
      'Credit',
      name: 'transaction_payment_credit',
      desc: '',
      args: [],
    );
  }

  /// `IQ Dinar`
  String get transaction_payment_Dinar {
    return Intl.message(
      'IQ Dinar',
      name: 'transaction_payment_Dinar',
      desc: '',
      args: [],
    );
  }

  /// `US Dollar`
  String get transaction_payment_Dollar {
    return Intl.message(
      'US Dollar',
      name: 'transaction_payment_Dollar',
      desc: '',
      args: [],
    );
  }

  /// `Salaries`
  String get transaction_expenditure_salary {
    return Intl.message(
      'Salaries',
      name: 'transaction_expenditure_salary',
      desc: '',
      args: [],
    );
  }

  /// `Rent`
  String get transaction_expenditure_rent {
    return Intl.message(
      'Rent',
      name: 'transaction_expenditure_rent',
      desc: '',
      args: [],
    );
  }

  /// `Others`
  String get transaction_expenditure_others {
    return Intl.message(
      'Others',
      name: 'transaction_expenditure_others',
      desc: '',
      args: [],
    );
  }

  /// `Bills`
  String get transaction_expenditure_bills {
    return Intl.message(
      'Bills',
      name: 'transaction_expenditure_bills',
      desc: '',
      args: [],
    );
  }

  /// `Expendure type`
  String get transaction_expenditure_type {
    return Intl.message(
      'Expendure type',
      name: 'transaction_expenditure_type',
      desc: '',
      args: [],
    );
  }

  /// `Money transer`
  String get transaction_expenditure_money_transer {
    return Intl.message(
      'Money transer',
      name: 'transaction_expenditure_money_transer',
      desc: '',
      args: [],
    );
  }

  /// `Expenditures`
  String get transaction_type_expenditures {
    return Intl.message(
      'Expenditures',
      name: 'transaction_type_expenditures',
      desc: '',
      args: [],
    );
  }

  /// `Gifts`
  String get transaction_type_gifts {
    return Intl.message(
      'Gifts',
      name: 'transaction_type_gifts',
      desc: '',
      args: [],
    );
  }

  /// `Customer Receipt`
  String get transaction_type_customer_receipt {
    return Intl.message(
      'Customer Receipt',
      name: 'transaction_type_customer_receipt',
      desc: '',
      args: [],
    );
  }

  /// `Vendor Receipt`
  String get transaction_type_vendor_receipt {
    return Intl.message(
      'Vendor Receipt',
      name: 'transaction_type_vendor_receipt',
      desc: '',
      args: [],
    );
  }

  /// `Vender Return`
  String get transaction_type_vender_return {
    return Intl.message(
      'Vender Return',
      name: 'transaction_type_vender_return',
      desc: '',
      args: [],
    );
  }

  /// `Customer Return`
  String get transaction_type_customer_return {
    return Intl.message(
      'Customer Return',
      name: 'transaction_type_customer_return',
      desc: '',
      args: [],
    );
  }

  /// `Vender Invoice`
  String get transaction_type_vender_invoice {
    return Intl.message(
      'Vender Invoice',
      name: 'transaction_type_vender_invoice',
      desc: '',
      args: [],
    );
  }

  /// `Customer Invoice`
  String get transaction_type_customer_invoice {
    return Intl.message(
      'Customer Invoice',
      name: 'transaction_type_customer_invoice',
      desc: '',
      args: [],
    );
  }

  /// `Damaged Items`
  String get transaction_type_damaged_items {
    return Intl.message(
      'Damaged Items',
      name: 'transaction_type_damaged_items',
      desc: '',
      args: [],
    );
  }

  /// `Initial credit Items`
  String get transaction_type_initial_credit {
    return Intl.message(
      'Initial credit Items',
      name: 'transaction_type_initial_credit',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get salesman_name {
    return Intl.message(
      'Name',
      name: 'salesman_name',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get category_name {
    return Intl.message(
      'Name',
      name: 'category_name',
      desc: '',
      args: [],
    );
  }

  /// `Salesmen`
  String get salesmen {
    return Intl.message(
      'Salesmen',
      name: 'salesmen',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get customer_name {
    return Intl.message(
      'Name',
      name: 'customer_name',
      desc: '',
      args: [],
    );
  }

  /// `Customers`
  String get customers {
    return Intl.message(
      'Customers',
      name: 'customers',
      desc: '',
      args: [],
    );
  }

  /// `Salesman selection`
  String get salesman_selection {
    return Intl.message(
      'Salesman selection',
      name: 'salesman_selection',
      desc: '',
      args: [],
    );
  }

  /// `Customer`
  String get customer {
    return Intl.message(
      'Customer',
      name: 'customer',
      desc: '',
      args: [],
    );
  }

  /// `#`
  String get item_sequence {
    return Intl.message(
      '#',
      name: 'item_sequence',
      desc: '',
      args: [],
    );
  }

  /// `Item name`
  String get item_name {
    return Intl.message(
      'Item name',
      name: 'item_name',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get item_price {
    return Intl.message(
      'Price',
      name: 'item_price',
      desc: '',
      args: [],
    );
  }

  /// `Sold Qtty.`
  String get item_sold_quantity {
    return Intl.message(
      'Sold Qtty.',
      name: 'item_sold_quantity',
      desc: '',
      args: [],
    );
  }

  /// `Total`
  String get item_total_price {
    return Intl.message(
      'Total',
      name: 'item_total_price',
      desc: '',
      args: [],
    );
  }

  /// `Gifts Qtty.`
  String get item_gifts_quantity {
    return Intl.message(
      'Gifts Qtty.',
      name: 'item_gifts_quantity',
      desc: '',
      args: [],
    );
  }

  /// `Total price`
  String get invoice_total_price {
    return Intl.message(
      'Total price',
      name: 'invoice_total_price',
      desc: '',
      args: [],
    );
  }

  /// `Total weight`
  String get invoice_total_weight {
    return Intl.message(
      'Total weight',
      name: 'invoice_total_weight',
      desc: '',
      args: [],
    );
  }

  /// `Total as text`
  String get transaction_total_amount_as_text {
    return Intl.message(
      'Total as text',
      name: 'transaction_total_amount_as_text',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get approve {
    return Intl.message(
      'Yes',
      name: 'approve',
      desc: '',
      args: [],
    );
  }

  /// `Amount`
  String get amount {
    return Intl.message(
      'Amount',
      name: 'amount',
      desc: '',
      args: [],
    );
  }

  /// `Number`
  String get number {
    return Intl.message(
      'Number',
      name: 'number',
      desc: '',
      args: [],
    );
  }

  /// `Include payment as text`
  String get include_total_as_text {
    return Intl.message(
      'Include payment as text',
      name: 'include_total_as_text',
      desc: '',
      args: [],
    );
  }

  /// `yes`
  String get yes {
    return Intl.message(
      'yes',
      name: 'yes',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get no {
    return Intl.message(
      'No',
      name: 'no',
      desc: '',
      args: [],
    );
  }

  /// `Vendors`
  String get vendors {
    return Intl.message(
      'Vendors',
      name: 'vendors',
      desc: '',
      args: [],
    );
  }

  /// `Vendor`
  String get vendor {
    return Intl.message(
      'Vendor',
      name: 'vendor',
      desc: '',
      args: [],
    );
  }

  /// `Subtotal`
  String get transaction_subTotal_amount {
    return Intl.message(
      'Subtotal',
      name: 'transaction_subTotal_amount',
      desc: '',
      args: [],
    );
  }

  /// `Phone number`
  String get phone {
    return Intl.message(
      'Phone number',
      name: 'phone',
      desc: '',
      args: [],
    );
  }

  /// `Region name`
  String get region_name {
    return Intl.message(
      'Region name',
      name: 'region_name',
      desc: '',
      args: [],
    );
  }

  /// `Regions`
  String get regions {
    return Intl.message(
      'Regions',
      name: 'regions',
      desc: '',
      args: [],
    );
  }

  /// `Initial amount`
  String get initialAmount {
    return Intl.message(
      'Initial amount',
      name: 'initialAmount',
      desc: '',
      args: [],
    );
  }

  /// `Initial amount date`
  String get initialDate {
    return Intl.message(
      'Initial amount date',
      name: 'initialDate',
      desc: '',
      args: [],
    );
  }

  /// `X coordinate`
  String get gps_x {
    return Intl.message(
      'X coordinate',
      name: 'gps_x',
      desc: '',
      args: [],
    );
  }

  /// `Y coordinate`
  String get gps_y {
    return Intl.message(
      'Y coordinate',
      name: 'gps_y',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get address {
    return Intl.message(
      'Address',
      name: 'address',
      desc: '',
      args: [],
    );
  }

  /// `Selling price type`
  String get selling_price_type {
    return Intl.message(
      'Selling price type',
      name: 'selling_price_type',
      desc: '',
      args: [],
    );
  }

  /// `Wholesale`
  String get selling_price_type_whole {
    return Intl.message(
      'Wholesale',
      name: 'selling_price_type_whole',
      desc: '',
      args: [],
    );
  }

  /// `Retail`
  String get selling_price_type_retail {
    return Intl.message(
      'Retail',
      name: 'selling_price_type_retail',
      desc: '',
      args: [],
    );
  }

  /// `Credit limit`
  String get credit_limit {
    return Intl.message(
      'Credit limit',
      name: 'credit_limit',
      desc: '',
      args: [],
    );
  }

  /// `Payment duration limit`
  String get payment_duration_limit {
    return Intl.message(
      'Payment duration limit',
      name: 'payment_duration_limit',
      desc: '',
      args: [],
    );
  }

  /// `Internal transactions`
  String get internal_transaction {
    return Intl.message(
      'Internal transactions',
      name: 'internal_transaction',
      desc: '',
      args: [],
    );
  }

  /// `Current debt`
  String get current_debt {
    return Intl.message(
      'Current debt',
      name: 'current_debt',
      desc: '',
      args: [],
    );
  }

  /// `Num of open invoices`
  String get num_open_invoice {
    return Intl.message(
      'Num of open invoices',
      name: 'num_open_invoice',
      desc: '',
      args: [],
    );
  }

  /// `Remaining amount`
  String get remaining_amount {
    return Intl.message(
      'Remaining amount',
      name: 'remaining_amount',
      desc: '',
      args: [],
    );
  }

  /// `Payed amount`
  String get paid_amount {
    return Intl.message(
      'Payed amount',
      name: 'paid_amount',
      desc: '',
      args: [],
    );
  }

  /// `Receipt number`
  String get receipt_number {
    return Intl.message(
      'Receipt number',
      name: 'receipt_number',
      desc: '',
      args: [],
    );
  }

  /// `Receipt date`
  String get receipt_date {
    return Intl.message(
      'Receipt date',
      name: 'receipt_date',
      desc: '',
      args: [],
    );
  }

  /// `Receipt amount`
  String get receipt_amount {
    return Intl.message(
      'Receipt amount',
      name: 'receipt_amount',
      desc: '',
      args: [],
    );
  }

  /// `ٌReceipt type`
  String get receipt_type {
    return Intl.message(
      'ٌReceipt type',
      name: 'receipt_type',
      desc: '',
      args: [],
    );
  }

  /// `Due debt`
  String get due_debt_amount {
    return Intl.message(
      'Due debt',
      name: 'due_debt_amount',
      desc: '',
      args: [],
    );
  }

  /// `Due invoices`
  String get num_due_invoices {
    return Intl.message(
      'Due invoices',
      name: 'num_due_invoices',
      desc: '',
      args: [],
    );
  }

  /// `Previous debt`
  String get previous_debt {
    return Intl.message(
      'Previous debt',
      name: 'previous_debt',
      desc: '',
      args: [],
    );
  }

  /// `Later debt`
  String get later_debt {
    return Intl.message(
      'Later debt',
      name: 'later_debt',
      desc: '',
      args: [],
    );
  }

  /// `From date`
  String get from_date {
    return Intl.message(
      'From date',
      name: 'from_date',
      desc: '',
      args: [],
    );
  }

  /// `Print`
  String get print {
    return Intl.message(
      'Print',
      name: 'print',
      desc: '',
      args: [],
    );
  }

  /// `Share`
  String get share {
    return Intl.message(
      'Share',
      name: 'share',
      desc: '',
      args: [],
    );
  }

  /// `Daily income`
  String get daily_income {
    return Intl.message(
      'Daily income',
      name: 'daily_income',
      desc: '',
      args: [],
    );
  }

  /// `Daily income report`
  String get daily_income_report {
    return Intl.message(
      'Daily income report',
      name: 'daily_income_report',
      desc: '',
      args: [],
    );
  }

  /// `Monthly profit`
  String get monthly_profit {
    return Intl.message(
      'Monthly profit',
      name: 'monthly_profit',
      desc: '',
      args: [],
    );
  }

  /// `Monthly profit report`
  String get monthly_profit_report {
    return Intl.message(
      'Monthly profit report',
      name: 'monthly_profit_report',
      desc: '',
      args: [],
    );
  }

  /// `To date`
  String get to_date {
    return Intl.message(
      'To date',
      name: 'to_date',
      desc: '',
      args: [],
    );
  }

  /// `Notes`
  String get notes {
    return Intl.message(
      'Notes',
      name: 'notes',
      desc: '',
      args: [],
    );
  }

  /// `Buying price`
  String get product_buying_price {
    return Intl.message(
      'Buying price',
      name: 'product_buying_price',
      desc: '',
      args: [],
    );
  }

  /// `Quantity`
  String get quantity {
    return Intl.message(
      'Quantity',
      name: 'quantity',
      desc: '',
      args: [],
    );
  }

  /// `Available quantity`
  String get item_available_quantity {
    return Intl.message(
      'Available quantity',
      name: 'item_available_quantity',
      desc: '',
      args: [],
    );
  }

  /// `Stock`
  String get product_stock_quantity {
    return Intl.message(
      'Stock',
      name: 'product_stock_quantity',
      desc: '',
      args: [],
    );
  }

  /// `Stock amount`
  String get product_stock_amount {
    return Intl.message(
      'Stock amount',
      name: 'product_stock_amount',
      desc: '',
      args: [],
    );
  }

  /// `Select`
  String get select {
    return Intl.message(
      'Select',
      name: 'select',
      desc: '',
      args: [],
    );
  }

  /// `Total`
  String get total {
    return Intl.message(
      'Total',
      name: 'total',
      desc: '',
      args: [],
    );
  }

  /// `Payment`
  String get payment {
    return Intl.message(
      'Payment',
      name: 'payment',
      desc: '',
      args: [],
    );
  }

  /// `Invoice status`
  String get invoice_status {
    return Intl.message(
      'Invoice status',
      name: 'invoice_status',
      desc: '',
      args: [],
    );
  }

  /// `Invoice closing duration`
  String get invoice_close_duration {
    return Intl.message(
      'Invoice closing duration',
      name: 'invoice_close_duration',
      desc: '',
      args: [],
    );
  }

  /// `Open`
  String get invoice_status_open {
    return Intl.message(
      'Open',
      name: 'invoice_status_open',
      desc: '',
      args: [],
    );
  }

  /// `Closed`
  String get invoice_status_closed {
    return Intl.message(
      'Closed',
      name: 'invoice_status_closed',
      desc: '',
      args: [],
    );
  }

  /// `Due`
  String get invoice_status_due {
    return Intl.message(
      'Due',
      name: 'invoice_status_due',
      desc: '',
      args: [],
    );
  }

  /// `Average invoice closing duration`
  String get average_invoice_closing_duration {
    return Intl.message(
      'Average invoice closing duration',
      name: 'average_invoice_closing_duration',
      desc: '',
      args: [],
    );
  }

  /// `Customer profit from invoices`
  String get customer_invoice_profit {
    return Intl.message(
      'Customer profit from invoices',
      name: 'customer_invoice_profit',
      desc: '',
      args: [],
    );
  }

  /// `Invoice profit`
  String get invoice_profit {
    return Intl.message(
      'Invoice profit',
      name: 'invoice_profit',
      desc: '',
      args: [],
    );
  }

  /// `Customer gifts and discounts`
  String get customer_gifts_and_discounts {
    return Intl.message(
      'Customer gifts and discounts',
      name: 'customer_gifts_and_discounts',
      desc: '',
      args: [],
    );
  }

  /// `Days`
  String get days {
    return Intl.message(
      'Days',
      name: 'days',
      desc: '',
      args: [],
    );
  }

  /// `Product profits`
  String get product_profits {
    return Intl.message(
      'Product profits',
      name: 'product_profits',
      desc: '',
      args: [],
    );
  }

  /// `Damaged items`
  String get damagedItems {
    return Intl.message(
      'Damaged items',
      name: 'damagedItems',
      desc: '',
      args: [],
    );
  }

  /// `Reload page`
  String get reload_page {
    return Intl.message(
      'Reload page',
      name: 'reload_page',
      desc: '',
      args: [],
    );
  }

  /// `Transaction reports`
  String get transaction_reports {
    return Intl.message(
      'Transaction reports',
      name: 'transaction_reports',
      desc: '',
      args: [],
    );
  }

  /// `Printing transactions`
  String get printing_transactions {
    return Intl.message(
      'Printing transactions',
      name: 'printing_transactions',
      desc: '',
      args: [],
    );
  }

  /// `Salary`
  String get salary {
    return Intl.message(
      'Salary',
      name: 'salary',
      desc: '',
      args: [],
    );
  }

  /// `Basic salary`
  String get basic_salary {
    return Intl.message(
      'Basic salary',
      name: 'basic_salary',
      desc: '',
      args: [],
    );
  }

  /// `Profits`
  String get profits {
    return Intl.message(
      'Profits',
      name: 'profits',
      desc: '',
      args: [],
    );
  }

  /// `Loading data`
  String get loading_data {
    return Intl.message(
      'Loading data',
      name: 'loading_data',
      desc: '',
      args: [],
    );
  }

  /// `Invoices number`
  String get invoices_number {
    return Intl.message(
      'Invoices number',
      name: 'invoices_number',
      desc: '',
      args: [],
    );
  }

  /// `Invoices amount`
  String get invoices_amount {
    return Intl.message(
      'Invoices amount',
      name: 'invoices_amount',
      desc: '',
      args: [],
    );
  }

  /// `Receipts number`
  String get receipts_number {
    return Intl.message(
      'Receipts number',
      name: 'receipts_number',
      desc: '',
      args: [],
    );
  }

  /// `Receipts amount`
  String get receipts_amount {
    return Intl.message(
      'Receipts amount',
      name: 'receipts_amount',
      desc: '',
      args: [],
    );
  }

  /// `Returns number`
  String get returns_number {
    return Intl.message(
      'Returns number',
      name: 'returns_number',
      desc: '',
      args: [],
    );
  }

  /// `Returns amount`
  String get returns_amount {
    return Intl.message(
      'Returns amount',
      name: 'returns_amount',
      desc: '',
      args: [],
    );
  }

  /// `Count`
  String get count {
    return Intl.message(
      'Count',
      name: 'count',
      desc: '',
      args: [],
    );
  }

  /// `Commission`
  String get commission {
    return Intl.message(
      'Commission',
      name: 'commission',
      desc: '',
      args: [],
    );
  }

  /// `Debts`
  String get debts {
    return Intl.message(
      'Debts',
      name: 'debts',
      desc: '',
      args: [],
    );
  }

  /// `Open invoices`
  String get open_invoices {
    return Intl.message(
      'Open invoices',
      name: 'open_invoices',
      desc: '',
      args: [],
    );
  }

  /// `From`
  String get from {
    return Intl.message(
      'From',
      name: 'from',
      desc: '',
      args: [],
    );
  }

  /// `To`
  String get to {
    return Intl.message(
      'To',
      name: 'to',
      desc: '',
      args: [],
    );
  }

  /// `Product search`
  String get product_search {
    return Intl.message(
      'Product search',
      name: 'product_search',
      desc: '',
      args: [],
    );
  }

  /// `Transactions search`
  String get transaction_search {
    return Intl.message(
      'Transactions search',
      name: 'transaction_search',
      desc: '',
      args: [],
    );
  }

  /// `Salesmen search`
  String get salesman_search {
    return Intl.message(
      'Salesmen search',
      name: 'salesman_search',
      desc: '',
      args: [],
    );
  }

  /// `Customers search`
  String get customer_search {
    return Intl.message(
      'Customers search',
      name: 'customer_search',
      desc: '',
      args: [],
    );
  }

  /// `Vendors search`
  String get vendor_search {
    return Intl.message(
      'Vendors search',
      name: 'vendor_search',
      desc: '',
      args: [],
    );
  }

  /// `Commissions_sum`
  String get sum_of_commissions {
    return Intl.message(
      'Commissions_sum',
      name: 'sum_of_commissions',
      desc: '',
      args: [],
    );
  }

  /// `Hide customer profit`
  String get hide_customer_profit {
    return Intl.message(
      'Hide customer profit',
      name: 'hide_customer_profit',
      desc: '',
      args: [],
    );
  }

  /// `Hide columns totals`
  String get hide_totals_row {
    return Intl.message(
      'Hide columns totals',
      name: 'hide_totals_row',
      desc: '',
      args: [],
    );
  }

  /// `hide Transaction Amount As Text`
  String get hide_amount_as_text {
    return Intl.message(
      'hide Transaction Amount As Text',
      name: 'hide_amount_as_text',
      desc: '',
      args: [],
    );
  }

  /// `hide Product Profit`
  String get hide_product_profit {
    return Intl.message(
      'hide Product Profit',
      name: 'hide_product_profit',
      desc: '',
      args: [],
    );
  }

  /// `hide Salesman Profit `
  String get hide_salesman_profit {
    return Intl.message(
      'hide Salesman Profit ',
      name: 'hide_salesman_profit',
      desc: '',
      args: [],
    );
  }

  /// `show Company Url Bar Code`
  String get show_barcode_when_printing {
    return Intl.message(
      'show Company Url Bar Code',
      name: 'show_barcode_when_printing',
      desc: '',
      args: [],
    );
  }

  /// `max Debt Duration `
  String get max_debt_duration_allowed {
    return Intl.message(
      'max Debt Duration ',
      name: 'max_debt_duration_allowed',
      desc: '',
      args: [],
    );
  }

  /// `max Debt Amount `
  String get max_debt_amount_allowed {
    return Intl.message(
      'max Debt Amount ',
      name: 'max_debt_amount_allowed',
      desc: '',
      args: [],
    );
  }

  /// `printed Customer Invoices `
  String get num_printed_invoices {
    return Intl.message(
      'printed Customer Invoices ',
      name: 'num_printed_invoices',
      desc: '',
      args: [],
    );
  }

  /// `printed Customer Receipts `
  String get num_printed_receipts {
    return Intl.message(
      'printed Customer Receipts ',
      name: 'num_printed_receipts',
      desc: '',
      args: [],
    );
  }

  /// `company Url `
  String get settings_company_url {
    return Intl.message(
      'company Url ',
      name: 'settings_company_url',
      desc: '',
      args: [],
    );
  }

  /// `main Page Greeting Text`
  String get settings_main_page_greeting {
    return Intl.message(
      'main Page Greeting Text',
      name: 'settings_main_page_greeting',
      desc: '',
      args: [],
    );
  }

  /// `hide product buying price`
  String get hide_product_buying_price {
    return Intl.message(
      'hide product buying price',
      name: 'hide_product_buying_price',
      desc: '',
      args: [],
    );
  }

  /// `Used currency`
  String get settings_currency {
    return Intl.message(
      'Used currency',
      name: 'settings_currency',
      desc: '',
      args: [],
    );
  }

  /// `Home page`
  String get home_page {
    return Intl.message(
      'Home page',
      name: 'home_page',
      desc: '',
      args: [],
    );
  }

  /// `Stock`
  String get stock {
    return Intl.message(
      'Stock',
      name: 'stock',
      desc: '',
      args: [],
    );
  }

  /// `No data available`
  String get no_data_available {
    return Intl.message(
      'No data available',
      name: 'no_data_available',
      desc: '',
      args: [],
    );
  }

  /// `Save data backup`
  String get save_data_backup {
    return Intl.message(
      'Save data backup',
      name: 'save_data_backup',
      desc: '',
      args: [],
    );
  }

  /// `Tablets database`
  String get downloaded_backup_file_name {
    return Intl.message(
      'Tablets database',
      name: 'downloaded_backup_file_name',
      desc: '',
      args: [],
    );
  }

  /// `Category search`
  String get category_search {
    return Intl.message(
      'Category search',
      name: 'category_search',
      desc: '',
      args: [],
    );
  }

  /// `Region search`
  String get region_search {
    return Intl.message(
      'Region search',
      name: 'region_search',
      desc: '',
      args: [],
    );
  }

  /// `Region`
  String get region {
    return Intl.message(
      'Region',
      name: 'region',
      desc: '',
      args: [],
    );
  }

  /// `Data entry date`
  String get date_entery_date {
    return Intl.message(
      'Data entry date',
      name: 'date_entery_date',
      desc: '',
      args: [],
    );
  }

  /// `Database backup were successful`
  String get db_backup_success {
    return Intl.message(
      'Database backup were successful',
      name: 'db_backup_success',
      desc: '',
      args: [],
    );
  }

  /// `Error happened during database backup`
  String get db_backup_failure {
    return Intl.message(
      'Error happened during database backup',
      name: 'db_backup_failure',
      desc: '',
      args: [],
    );
  }

  /// `Main menu`
  String get main_menu {
    return Intl.message(
      'Main menu',
      name: 'main_menu',
      desc: '',
      args: [],
    );
  }

  /// `Next`
  String get next {
    return Intl.message(
      'Next',
      name: 'next',
      desc: '',
      args: [],
    );
  }

  /// `Previous`
  String get previous {
    return Intl.message(
      'Previous',
      name: 'previous',
      desc: '',
      args: [],
    );
  }

  /// `First`
  String get first {
    return Intl.message(
      'First',
      name: 'first',
      desc: '',
      args: [],
    );
  }

  /// `Last`
  String get last {
    return Intl.message(
      'Last',
      name: 'last',
      desc: '',
      args: [],
    );
  }

  /// `Printed`
  String get printed {
    return Intl.message(
      'Printed',
      name: 'printed',
      desc: '',
      args: [],
    );
  }

  /// `Not printed`
  String get not_printed {
    return Intl.message(
      'Not printed',
      name: 'not_printed',
      desc: '',
      args: [],
    );
  }

  /// `You must enter name`
  String get no_name_print_error {
    return Intl.message(
      'You must enter name',
      name: 'no_name_print_error',
      desc: '',
      args: [],
    );
  }

  /// `Code`
  String get code {
    return Intl.message(
      'Code',
      name: 'code',
      desc: '',
      args: [],
    );
  }

  /// `Transaction group selection`
  String get transaction_group_selection {
    return Intl.message(
      'Transaction group selection',
      name: 'transaction_group_selection',
      desc: '',
      args: [],
    );
  }

  /// `Transaction type selection`
  String get transaction_type_selection {
    return Intl.message(
      'Transaction type selection',
      name: 'transaction_type_selection',
      desc: '',
      args: [],
    );
  }

  /// `Back`
  String get back {
    return Intl.message(
      'Back',
      name: 'back',
      desc: '',
      args: [],
    );
  }

  /// `New`
  String get new_item {
    return Intl.message(
      'New',
      name: 'new_item',
      desc: '',
      args: [],
    );
  }

  /// `Last receipt date`
  String get last_receipt_date {
    return Intl.message(
      'Last receipt date',
      name: 'last_receipt_date',
      desc: '',
      args: [],
    );
  }

  /// `Customer total debt`
  String get total_debt {
    return Intl.message(
      'Customer total debt',
      name: 'total_debt',
      desc: '',
      args: [],
    );
  }

  /// `Show printed only`
  String get show_printed_only {
    return Intl.message(
      'Show printed only',
      name: 'show_printed_only',
      desc: '',
      args: [],
    );
  }

  /// `Show all`
  String get show_all {
    return Intl.message(
      'Show all',
      name: 'show_all',
      desc: '',
      args: [],
    );
  }

  /// `Transaction not found`
  String get transaction_not_found {
    return Intl.message(
      'Transaction not found',
      name: 'transaction_not_found',
      desc: '',
      args: [],
    );
  }

  /// `no receipt`
  String get there_is_no_customer_receipt {
    return Intl.message(
      'no receipt',
      name: 'there_is_no_customer_receipt',
      desc: '',
      args: [],
    );
  }

  /// `Balance`
  String get balance {
    return Intl.message(
      'Balance',
      name: 'balance',
      desc: '',
      args: [],
    );
  }

  /// `No item were added to invoice`
  String get no_item_were_added_to_invoice {
    return Intl.message(
      'No item were added to invoice',
      name: 'no_item_were_added_to_invoice',
      desc: '',
      args: [],
    );
  }

  /// `Previous item has zero quantity`
  String get previous_item_quantity_is_zero {
    return Intl.message(
      'Previous item has zero quantity',
      name: 'previous_item_quantity_is_zero',
      desc: '',
      args: [],
    );
  }

  /// `Product is out of stock`
  String get product_out_of_stock {
    return Intl.message(
      'Product is out of stock',
      name: 'product_out_of_stock',
      desc: '',
      args: [],
    );
  }

  /// `Salesmen debt report`
  String get salesmen_debt_report {
    return Intl.message(
      'Salesmen debt report',
      name: 'salesmen_debt_report',
      desc: '',
      args: [],
    );
  }

  /// `Print status`
  String get print_status {
    return Intl.message(
      'Print status',
      name: 'print_status',
      desc: '',
      args: [],
    );
  }

  /// `Net amount`
  String get net_amount {
    return Intl.message(
      'Net amount',
      name: 'net_amount',
      desc: '',
      args: [],
    );
  }

  /// `Sold`
  String get sold {
    return Intl.message(
      'Sold',
      name: 'sold',
      desc: '',
      args: [],
    );
  }

  /// `Returned`
  String get returned {
    return Intl.message(
      'Returned',
      name: 'returned',
      desc: '',
      args: [],
    );
  }

  /// `Salesmen sellings`
  String get salesmen_sellings {
    return Intl.message(
      'Salesmen sellings',
      name: 'salesmen_sellings',
      desc: '',
      args: [],
    );
  }

  /// `Salesman items sold`
  String get salesman_selling_report {
    return Intl.message(
      'Salesman items sold',
      name: 'salesman_selling_report',
      desc: '',
      args: [],
    );
  }

  /// `for the period`
  String get for_the_duration {
    return Intl.message(
      'for the period',
      name: 'for_the_duration',
      desc: '',
      args: [],
    );
  }

  /// `Supervisor salesmen report`
  String get supervisor_salesmen_report {
    return Intl.message(
      'Supervisor salesmen report',
      name: 'supervisor_salesmen_report',
      desc: '',
      args: [],
    );
  }

  /// `Supervisor customer report`
  String get supervisor_customer_report {
    return Intl.message(
      'Supervisor customer report',
      name: 'supervisor_customer_report',
      desc: '',
      args: [],
    );
  }

  /// `Customer matching`
  String get customer_matching {
    return Intl.message(
      'Customer matching',
      name: 'customer_matching',
      desc: '',
      args: [],
    );
  }

  /// `Salesman customers`
  String get saleman_customers {
    return Intl.message(
      'Salesman customers',
      name: 'saleman_customers',
      desc: '',
      args: [],
    );
  }

  /// `Hide from special reports`
  String get hide_from_special_reports {
    return Intl.message(
      'Hide from special reports',
      name: 'hide_from_special_reports',
      desc: '',
      args: [],
    );
  }

  /// `Salesman`
  String get salesman {
    return Intl.message(
      'Salesman',
      name: 'salesman',
      desc: '',
      args: [],
    );
  }

  /// `Packages number`
  String get package_number {
    return Intl.message(
      'Packages number',
      name: 'package_number',
      desc: '',
      args: [],
    );
  }

  /// `Deleted transactions`
  String get deleted_transactions {
    return Intl.message(
      'Deleted transactions',
      name: 'deleted_transactions',
      desc: '',
      args: [],
    );
  }

  /// `Deletion time`
  String get deletion_time {
    return Intl.message(
      'Deletion time',
      name: 'deletion_time',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to signout`
  String get alert_before_signout {
    return Intl.message(
      'Do you want to signout',
      name: 'alert_before_signout',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
