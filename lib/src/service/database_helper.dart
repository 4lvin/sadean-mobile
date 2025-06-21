import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "sadean_pos.db";
  static const _databaseVersion = 4; // Incremented for stock tracking support

  // Table names
  static const String tableCategories = 'categories';
  static const String tableProducts = 'products';
  static const String tableTransactions = 'transactions';
  static const String tableTransactionItems = 'transaction_items';
  static const String tableIncomeExpense = 'income_expense';

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Categories table
    await db.execute('''
      CREATE TABLE $tableCategories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        product_count INTEGER DEFAULT 0,
        sold_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Products table with stock tracking
    await db.execute('''
      CREATE TABLE $tableProducts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        image_url TEXT,
        sku TEXT UNIQUE NOT NULL,
        barcode TEXT UNIQUE NOT NULL,
        cost_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        unit TEXT NOT NULL,
        stock INTEGER NOT NULL,
        min_stock INTEGER NOT NULL,
        sold_count INTEGER DEFAULT 0,
        is_stock_enabled INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES $tableCategories (id) ON DELETE RESTRICT
      )
    ''');

    // Transactions table with payment fields
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        cost_amount REAL NOT NULL,
        profit REAL NOT NULL,
        subtotal REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        shipping_cost REAL DEFAULT 0,
        service_fee REAL DEFAULT 0,
        payment_method TEXT DEFAULT 'cash',
        amount_paid REAL DEFAULT 0,
        change_amount REAL DEFAULT 0,
        payment_status TEXT DEFAULT 'paid',
        customer_name TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Transaction items table
    await db.execute('''
      CREATE TABLE $tableTransactionItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        cost_price REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES $tableTransactions (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES $tableProducts (id) ON DELETE RESTRICT
      )
    ''');

    // Income/Expense table
    await db.execute('''
      CREATE TABLE $tableIncomeExpense (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        notes TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_products_category_id ON $tableProducts (category_id)');
    await db.execute('CREATE INDEX idx_products_barcode ON $tableProducts (barcode)');
    await db.execute('CREATE INDEX idx_products_sku ON $tableProducts (sku)');
    await db.execute('CREATE INDEX idx_products_stock_enabled ON $tableProducts (is_stock_enabled)');
    await db.execute('CREATE INDEX idx_products_low_stock ON $tableProducts (stock, min_stock, is_stock_enabled)');
    await db.execute('CREATE INDEX idx_transaction_items_transaction_id ON $tableTransactionItems (transaction_id)');
    await db.execute('CREATE INDEX idx_transaction_items_product_id ON $tableTransactionItems (product_id)');
    await db.execute('CREATE INDEX idx_transactions_date ON $tableTransactions (date)');
    await db.execute('CREATE INDEX idx_income_expense_type ON $tableIncomeExpense (type)');
    await db.execute('CREATE INDEX idx_income_expense_date ON $tableIncomeExpense (date)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add payment fields to existing transactions table
      await db.execute('ALTER TABLE $tableTransactions ADD COLUMN payment_method TEXT DEFAULT "cash"');
      await db.execute('ALTER TABLE $tableTransactions ADD COLUMN amount_paid REAL DEFAULT 0');
      await db.execute('ALTER TABLE $tableTransactions ADD COLUMN change_amount REAL DEFAULT 0');
      await db.execute('ALTER TABLE $tableTransactions ADD COLUMN payment_status TEXT DEFAULT "paid"');
    }

    if (oldVersion < 3) {
      // Create income/expense table
      await db.execute('''
        CREATE TABLE $tableIncomeExpense (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
          amount REAL NOT NULL,
          payment_method TEXT NOT NULL DEFAULT 'cash',
          notes TEXT,
          date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create indexes
      await db.execute('CREATE INDEX idx_income_expense_type ON $tableIncomeExpense (type)');
      await db.execute('CREATE INDEX idx_income_expense_date ON $tableIncomeExpense (date)');
    }

    if (oldVersion < 4) {
      // Add stock tracking column to products table
      await db.execute('ALTER TABLE $tableProducts ADD COLUMN is_stock_enabled INTEGER DEFAULT 1');

      // Create new indexes for stock tracking
      await db.execute('CREATE INDEX idx_products_stock_enabled ON $tableProducts (is_stock_enabled)');
      await db.execute('CREATE INDEX idx_products_low_stock ON $tableProducts (stock, min_stock, is_stock_enabled)');

      // Update existing products to have stock tracking enabled by default
      await db.execute('UPDATE $tableProducts SET is_stock_enabled = 1 WHERE is_stock_enabled IS NULL');
    }
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.insert(table, data);
  }

  Future<int> insertTrx(DatabaseExecutor db, String table, Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.insert(table, data);
  }

  Future<int> update(String table, Map<String, dynamic> data, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(table, data, where: whereClause, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.delete(table, where: whereClause, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> query(
      String table, {
        List<String>? columns,
        String? where,
        List<dynamic>? whereArgs,
        String? orderBy,
        int? limit,
      }) async {
    final db = await database;
    return await db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  // Transaction operations
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Stock tracking specific queries
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM $tableProducts 
      WHERE is_stock_enabled = 1 AND stock <= min_stock AND stock > 0
      ORDER BY stock ASC, name ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getOutOfStockProducts() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM $tableProducts 
      WHERE is_stock_enabled = 1 AND stock = 0
      ORDER BY name ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getUnlimitedStockProducts() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM $tableProducts 
      WHERE is_stock_enabled = 0
      ORDER BY name ASC
    ''');
  }

  Future<Map<String, int>> getStockStatistics() async {
    final db = await database;

    final totalProducts = await db.rawQuery('SELECT COUNT(*) as count FROM $tableProducts');
    final stockEnabledProducts = await db.rawQuery('SELECT COUNT(*) as count FROM $tableProducts WHERE is_stock_enabled = 1');
    final unlimitedStockProducts = await db.rawQuery('SELECT COUNT(*) as count FROM $tableProducts WHERE is_stock_enabled = 0');
    final lowStockProducts = await db.rawQuery('SELECT COUNT(*) as count FROM $tableProducts WHERE is_stock_enabled = 1 AND stock <= min_stock AND stock > 0');
    final outOfStockProducts = await db.rawQuery('SELECT COUNT(*) as count FROM $tableProducts WHERE is_stock_enabled = 1 AND stock = 0');

    return {
      'total': totalProducts.first['count'] as int,
      'stockEnabled': stockEnabledProducts.first['count'] as int,
      'unlimitedStock': unlimitedStockProducts.first['count'] as int,
      'lowStock': lowStockProducts.first['count'] as int,
      'outOfStock': outOfStockProducts.first['count'] as int,
    };
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableTransactionItems);
      await txn.delete(tableTransactions);
      await txn.delete(tableIncomeExpense);
      await txn.delete(tableProducts);
      await txn.delete(tableCategories);
    });
  }

  // Get database path (for debugging)
  Future<String> getDatabasePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, _databaseName);
  }
}