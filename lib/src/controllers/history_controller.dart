import 'package:get/get.dart';

import '../models/transaction_model.dart';
import '../service/transaction_service.dart';

class HistoryController extends GetxController {
  final TransactionService _service = Get.find<TransactionService>();

  final RxList<Transaction> transactions = <Transaction>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    isLoading.value = true;

    try {
      final transactionList = await _service.getAllTransactions();
      transactions.assignAll(transactionList);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat riwayat transaksi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      isLoading.value = true;
      await _service.deleteTransaction(id);
      await fetchTransactions();
      Get.snackbar('Sukses', 'Transaksi berhasil dihapus');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus transaksi: $e');
    } finally {
      isLoading.value = false;
    }
  }
}