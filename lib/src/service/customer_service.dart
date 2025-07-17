// lib/src/service/customer_service.dart

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/customer_model.dart';
import 'database_helper.dart';

class CustomerService extends GetxService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    try {
      final maps = await _dbHelper.query(
        DatabaseHelper.tableCustomers,
        orderBy: 'name ASC',
      );
      return maps.map((map) => Customer.fromJson(map)).toList();
    } catch (e) {
      print('Error getting customers: $e');
      return [];
    }
  }

  // Get customer by ID
  Future<Customer?> getCustomerById(String id) async {
    try {
      final maps = await _dbHelper.query(
        DatabaseHelper.tableCustomers,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Customer.fromJson(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting customer by id: $e');
      return null;
    }
  }

  // Search customers
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final maps = await _dbHelper.query(
        DatabaseHelper.tableCustomers,
        where: 'name LIKE ? OR phone_number LIKE ? OR email LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
      return maps.map((map) => Customer.fromJson(map)).toList();
    } catch (e) {
      print('Error searching customers: $e');
      return [];
    }
  }

  // Add customer
  Future<Customer> addCustomer({
    required String name,
    String? phoneNumber,
    String? email,
    String? barcode,
    String? address,
  }) async {
    try {
      // Validate name
      if (name.trim().isEmpty) {
        throw Exception('Nama pelanggan tidak boleh kosong');
      }

      // Check for duplicate name
      final existingByName = await _dbHelper.query(
        DatabaseHelper.tableCustomers,
        where: 'LOWER(name) = LOWER(?)',
        whereArgs: [name.trim()],
      );
      if (existingByName.isNotEmpty) {
        throw Exception('Pelanggan dengan nama "$name" sudah ada');
      }

      // Check for duplicate phone if provided
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        final existingByPhone = await _dbHelper.query(
          DatabaseHelper.tableCustomers,
          where: 'phone_number = ?',
          whereArgs: [phoneNumber.trim()],
        );
        if (existingByPhone.isNotEmpty) {
          throw Exception('Nomor telepon "$phoneNumber" sudah digunakan');
        }
      }

      // Check for duplicate email if provided
      if (email != null && email.trim().isNotEmpty) {
        final existingByEmail = await _dbHelper.query(
          DatabaseHelper.tableCustomers,
          where: 'email = ?',
          whereArgs: [email.trim()],
        );
        if (existingByEmail.isNotEmpty) {
          throw Exception('Email "$email" sudah digunakan');
        }
      }

      // Check for duplicate barcode if provided
      if (barcode != null && barcode.trim().isNotEmpty) {
        final existingByBarcode = await _dbHelper.query(
          DatabaseHelper.tableCustomers,
          where: 'barcode = ?',
          whereArgs: [barcode.trim()],
        );
        if (existingByBarcode.isNotEmpty) {
          throw Exception('Barcode "$barcode" sudah digunakan');
        }
      }

      final now = DateTime.now();
      final newCustomer = Customer(
        id: const Uuid().v4(),
        name: name.trim(),
        phoneNumber: phoneNumber?.trim(),
        email: email?.trim(),
        barcode: barcode?.trim(),
        address: address?.trim(),
        balance: 0.0,
        createdAt: now,
        updatedAt: now,
      );

      await _dbHelper.insert(
        DatabaseHelper.tableCustomers,
        newCustomer.toJson(),
      );

      return newCustomer;
    } catch (e) {
      print('Error adding customer: $e');
      rethrow;
    }
  }

  // Update customer
  Future<void> updateCustomer({
    required String id,
    required String name,
    String? phoneNumber,
    String? email,
    String? barcode,
    String? address,
  }) async {
    try {
      // Validate name
      if (name.trim().isEmpty) {
        throw Exception('Nama pelanggan tidak boleh kosong');
      }

      // Check for duplicate name (excluding current customer)
      final existingByName = await _dbHelper.query(
        DatabaseHelper.tableCustomers,
        where: 'LOWER(name) = LOWER(?) AND id != ?',
        whereArgs: [name.trim(), id],
      );
      if (existingByName.isNotEmpty) {
        throw Exception('Pelanggan dengan nama "$name" sudah ada');
      }

      // Check for duplicate phone if provided (excluding current customer)
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        final existingByPhone = await _dbHelper.query(
          DatabaseHelper.tableCustomers,
          where: 'phone_number = ? AND id != ?',
          whereArgs: [phoneNumber.trim(), id],
        );
        if (existingByPhone.isNotEmpty) {
          throw Exception('Nomor telepon "$phoneNumber" sudah digunakan');
        }
      }

      // Check for duplicate email if provided (excluding current customer)
      if (email != null && email.trim().isNotEmpty) {
        final existingByEmail = await _dbHelper.query(
          DatabaseHelper.tableCustomers,
          where: 'email = ? AND id != ?',
          whereArgs: [email.trim(), id],
        );
        if (existingByEmail.isNotEmpty) {
          throw Exception('Email "$email" sudah digunakan');
        }
      }

      // Check for duplicate barcode if provided (excluding current customer)
      if (barcode != null && barcode.trim().isNotEmpty) {
        final existingByBarcode = await _dbHelper.query(
          DatabaseHelper.tableCustomers,
          where: 'barcode = ? AND id != ?',
          whereArgs: [barcode.trim(), id],
        );
        if (existingByBarcode.isNotEmpty) {
          throw Exception('Barcode "$barcode" sudah digunakan');
        }
      }

      await _dbHelper.update(
        DatabaseHelper.tableCustomers,
        {
          'name': name.trim(),
          'phone_number': phoneNumber?.trim(),
          'email': email?.trim(),
          'barcode': barcode?.trim(),
          'address': address?.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [id],
      );
    } catch (e) {
      print('Error updating customer: $e');
      rethrow;
    }
  }

  // Delete customer
  Future<void> deleteCustomer(String id) async {
    try {
      // Check if customer has transactions
      final transactions = await _dbHelper.query(
        DatabaseHelper.tableCustomerTransactions,
        where: 'customer_id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (transactions.isNotEmpty) {
        throw Exception('Tidak dapat menghapus pelanggan yang memiliki riwayat transaksi');
      }

      await _dbHelper.delete(
        DatabaseHelper.tableCustomers,
        'id = ?',
        [id],
      );
    } catch (e) {
      print('Error deleting customer: $e');
      rethrow;
    }
  }

  // Get customer transactions
  Future<List<CustomerTransaction>> getCustomerTransactions(String customerId) async {
    try {
      final maps = await _dbHelper.query(
        DatabaseHelper.tableCustomerTransactions,
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'date DESC',
      );
      return maps.map((map) => CustomerTransaction.fromJson(map)).toList();
    } catch (e) {
      print('Error getting customer transactions: $e');
      return [];
    }
  }

  // Add customer transaction (invoice or payment)
  Future<CustomerTransaction> addCustomerTransaction({
    required String customerId,
    required String type, // 'invoice' or 'payment'
    required double amount,
    String? paymentMethod,
    String? notes,
    DateTime? date,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Jumlah harus lebih dari 0');
      }

      final now = DateTime.now();
      final transactionDate = date ?? now;

      // Generate ID with format: IN/YYYYMMDD/LMI-XXX
      final dateStr = '${transactionDate.year}${transactionDate.month.toString().padLeft(2, '0')}${transactionDate.day.toString().padLeft(2, '0')}';
      final timeStr = '${transactionDate.hour.toString().padLeft(2, '0')}${transactionDate.minute.toString().padLeft(2, '0')}${transactionDate.second.toString().padLeft(2, '0')}';
      final transactionId = 'IN/$dateStr/LMI-$timeStr';

      final newTransaction = CustomerTransaction(
        id: transactionId,
        customerId: customerId,
        type: type,
        amount: amount,
        paymentMethod: paymentMethod,
        notes: notes,
        status: type == 'payment' ? 'paid' : 'pending',
        date: transactionDate,
        createdAt: now,
        updatedAt: now,
      );

      await _dbHelper.transaction((txn) async {
        // Insert transaction
        await txn.insert(
          DatabaseHelper.tableCustomerTransactions,
          newTransaction.toJson(),
        );

        // Update customer balance
        await _updateCustomerBalance(customerId, txn);
      });

      return newTransaction;
    } catch (e) {
      print('Error adding customer transaction: $e');
      rethrow;
    }
  }

  // Update customer balance
  Future<void> _updateCustomerBalance(String customerId, txn) async {
    try {
      // Calculate total invoices
      final invoiceResult = await txn.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM ${DatabaseHelper.tableCustomerTransactions} WHERE customer_id = ? AND type = "invoice"',
        [customerId],
      );

      // Calculate total payments
      final paymentResult = await txn.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM ${DatabaseHelper.tableCustomerTransactions} WHERE customer_id = ? AND type = "payment"',
        [customerId],
      );

      final totalInvoices = (invoiceResult.first['total'] as num).toDouble();
      final totalPayments = (paymentResult.first['total'] as num).toDouble();
      final balance = totalInvoices - totalPayments;

      // Update customer balance
      await txn.update(
        DatabaseHelper.tableCustomers,
        {
          'balance': balance,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );
    } catch (e) {
      print('Error updating customer balance: $e');
    }
  }

  // Recalculate all customer balances
  Future<void> recalculateAllBalances() async {
    try {
      final customers = await getAllCustomers();

      await _dbHelper.transaction((txn) async {
        for (final customer in customers) {
          await _updateCustomerBalance(customer.id, txn);
        }
      });
    } catch (e) {
      print('Error recalculating balances: $e');
    }
  }

  // Get customer by barcode
  Future<Customer?> getCustomerByBarcode(String barcode) async {
    try {
      final maps = await _dbHelper.query(
        DatabaseHelper.tableCustomers,
        where: 'barcode = ?',
        whereArgs: [barcode.trim()],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Customer.fromJson(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting customer by barcode: $e');
      return null;
    }
  }

  // Get customers with outstanding balance
  Future<List<Customer>> getCustomersWithBalance() async {
    try {
      final maps = await _dbHelper.query(
        DatabaseHelper.tableCustomers,
        where: 'balance > 0',
        orderBy: 'balance DESC, name ASC',
      );
      return maps.map((map) => Customer.fromJson(map)).toList();
    } catch (e) {
      print('Error getting customers with balance: $e');
      return [];
    }
  }
}