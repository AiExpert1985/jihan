const String nameKey = 'name';
const String dbRefKey = 'dbRef';
const String nameDbRefKey = 'nameDbRef';
const String numberKey = 'number';
const String dateKey = 'date';
const String currencyKey = 'currency';
const String notesKey = 'notes';
const String transTypeKey = 'transactionType';
const String paymentTypeKey = 'paymentType';
const String salesmanKey = 'salesman';
const String itemsKey = 'items';
const String discountKey = 'discount';
const String totalAsTextKey = 'totalAsText';
const String totalWeightKey = 'totalWeight';
const String totalAmountKey = 'totalAmount';
const String itemNameKey = 'name';
const String itemDbRefKey = 'dbRef';
const String itemWeightKey = 'weight';
const String itemStockQuantityKey = 'itemStockQuantity';
const String itemSellingPriceKey = 'sellingPrice';
const String itemBuyingPriceKey = 'buyingPrice';
const String itemSalesmanCommissionKey = 'salesmanCommission'; // commision on one item
const String itemSalesmanTotalCommissionKey =
    'salesmanTotalCommission'; // commision on one item quanity sold
const String itemTotalProfitKey = 'itemTotalProfit';
const String itemSoldQuantityKey = 'soldQuantity';
const String itemGiftQuantityKey = 'giftQuantity';
const String itemTotalAmountKey = 'itemTotalAmount';
const String itemTotalWeightKey = 'itemTotalWeight';
const String itemCodeKey = 'code';
const String subTotalAmountKey = 'subTotalAmount';
const String salesmanDbRefKey = 'salesmanDbRef';
const String sellingPriceTypeKey = 'sellingPriceType';
const String transactionTotalProfitKey = 'transactionTotalProfit';
const String salesmanTransactionComssionKey = 'salesmanTransactionComssion';
const String itemsTotalProfitKey = 'itemsTotalProfit'; // profit of all items in the transaction
const String isPrintedKey = 'isPrinted';
Map<String, dynamic> emptyInvoiceItem = {
  itemCodeKey: null,
  itemNameKey: '',
  itemSellingPriceKey: 0,
  itemWeightKey: 0,
  itemSoldQuantityKey: 0,
  itemGiftQuantityKey: 0,
  itemTotalAmountKey: 0,
  itemTotalWeightKey: 0,
  itemStockQuantityKey: 0,
  itemTotalProfitKey: 0,
  itemSalesmanTotalCommissionKey: 0,
};
