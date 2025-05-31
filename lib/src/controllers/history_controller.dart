import 'package:get/get.dart';

import '../models/transaction_model.dart';

class HistoryController extends GetxController {
  final RxList<Transaction> transactions = <Transaction>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  void fetchTransactions() {
    // Sample data for demonstration
    transactions.value = [
      Transaction(
        id: 'TRX001',
        date: DateTime.now().subtract(Duration(hours: 2)),
        items: [
          TransactionItem(
            productId: '1',
            productName: 'Nasi Goreng',
            quantity: 2,
            unitPrice: 25000,
            costPrice: 15000,
          ),
          TransactionItem(
            productId: '2',
            productName: 'Es Teh Manis',
            quantity: 2,
            unitPrice: 8000,
            costPrice: 3000,
          ),
        ],
        totalAmount: 66000,
        costAmount: 36000,
        profit: 30000,
      ),
      Transaction(
        id: 'TRX002',
        date: DateTime.now().subtract(Duration(days: 1)),
        items: [
          TransactionItem(
            productId: '3',
            productName: 'Ayam Goreng',
            quantity: 1,
            unitPrice: 20000,
            costPrice: 12000,
          ),
        ],
        totalAmount: 20000,
        costAmount: 12000,
        profit: 8000,
      ),
    ];
  }
}