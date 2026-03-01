import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetCategory {
  final String name;
  final double percentage;
  final double allocated;
  double spent;
  final Color color;

  BudgetCategory({
    required this.name,
    required this.percentage,
    required this.allocated,
    required this.spent,
    required this.color,
  });
}

class Transaction {
  final String id;
  final String category;
  final double amount;
  final String description;
  final String date;

  Transaction({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'amount': amount,
    'description': description,
    'date': date,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    category: json['category'],
    amount: (json['amount'] as num).toDouble(),
    description: json['description'],
    date: json['date'],
  );
}

class PostMarriagePage extends StatefulWidget {
  const PostMarriagePage({super.key});

  @override
  State<PostMarriagePage> createState() => _PostMarriagePageState();
}

class _PostMarriagePageState extends State<PostMarriagePage> {
  Map<String, dynamic>? _financialData;
  String _budgetModel = "50/30/20";
  List<BudgetCategory> _categories = [];
  List<Transaction> _transactions = [];
  bool _showAddTransaction = false;

  // Spouse Linking
  String? _familyId;
  String? _spouseEmail;

  // Form State
  String _selectedCategory = "";
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDataString = prefs.getString('financialData');

    Map<String, dynamic>? financialData;

    // First try Firestore
    final user = FirebaseAuth.instance.currentUser;
    String targetUid = user?.uid ?? "";

    if (user != null) {
      try {
        // 1. Get User Profile to check for Family ID
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          if (userData.containsKey('familyId') &&
              userData['familyId'] != null) {
            targetUid = userData['familyId'];
          }
          if (userData.containsKey('spouseEmail')) {
            _spouseEmail = userData['spouseEmail'];
          }
        }

        setState(() {
          _familyId = targetUid;
        });

        // 2. Fetch Financial Data using targetUid (Family ID or own UID)
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .collection('financial_data')
            .doc('current')
            .get();
        if (doc.exists) {
          financialData = doc.data()!;
        }

        // 3. Fetch Transactions using targetUid
        final transSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .collection('transactions')
            .orderBy('date', descending: true)
            .get();

        if (transSnapshot.docs.isNotEmpty) {
          setState(() {
            _transactions = transSnapshot.docs
                .map((d) => Transaction.fromJson(d.data()))
                .toList();
          });
        } else {
          // Fallback to local transactions if Firestore is empty
          final savedTransactionsString = prefs.getString('transactions');
          if (savedTransactionsString != null) {
            final List<dynamic> decoded = jsonDecode(savedTransactionsString);
            setState(() {
              _transactions = decoded
                  .map((e) => Transaction.fromJson(e))
                  .toList();
            });
          }
        }
      } catch (e) {
        debugPrint("Error loading from Firestore: $e");
      }
    }

    // Fallback to local financial data
    if (financialData == null && savedDataString != null) {
      financialData = jsonDecode(savedDataString);
    }

    if (financialData == null && mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/',
      ); // Assumes '/' is root or login
      return;
    }

    if (financialData != null && mounted) {
      setState(() {
        _financialData = financialData;
      });
    }

    _calculateBudget();
  }

  void _calculateBudget() {
    if (_financialData == null) return;

    double income = (_financialData?['monthlyIncome'] ?? 0) * 1.0;

    // Fallback if data hasn't accounted for string/int conversions easily
    if (_financialData?['monthlyIncome'] is String) {
      income = double.tryParse(_financialData!['monthlyIncome']) ?? 0;
    }

    List<BudgetCategory> categoriesData = [];

    if (_budgetModel == "50/30/20") {
      categoriesData = [
        BudgetCategory(
          name: "Kebutuhan Pokok",
          percentage: 50,
          allocated: income * 0.5,
          spent: 0,
          color: Colors.blue.shade500,
        ),
        BudgetCategory(
          name: "Hiburan & Gaya Hidup",
          percentage: 30,
          allocated: income * 0.3,
          spent: 0,
          color: Colors.purple.shade500,
        ),
        BudgetCategory(
          name: "Tabungan & Investasi",
          percentage: 20,
          allocated: income * 0.2,
          spent: 0,
          color: Colors.green.shade500,
        ),
      ];
    } else if (_budgetModel == "60/20/20") {
      categoriesData = [
        BudgetCategory(
          name: "Kebutuhan Pokok",
          percentage: 60,
          allocated: income * 0.6,
          spent: 0,
          color: Colors.blue.shade500,
        ),
        BudgetCategory(
          name: "Hiburan & Gaya Hidup",
          percentage: 20,
          allocated: income * 0.2,
          spent: 0,
          color: Colors.purple.shade500,
        ),
        BudgetCategory(
          name: "Tabungan & Investasi",
          percentage: 20,
          allocated: income * 0.2,
          spent: 0,
          color: Colors.green.shade500,
        ),
      ];
    } else {
      categoriesData = [
        BudgetCategory(
          name: "Kebutuhan Pokok",
          percentage: 70,
          allocated: income * 0.7,
          spent: 0,
          color: Colors.blue.shade500,
        ),
        BudgetCategory(
          name: "Hiburan & Gaya Hidup",
          percentage: 20,
          allocated: income * 0.2,
          spent: 0,
          color: Colors.purple.shade500,
        ),
        BudgetCategory(
          name: "Tabungan & Investasi",
          percentage: 10,
          allocated: income * 0.1,
          spent: 0,
          color: Colors.green.shade500,
        ),
      ];
    }

    // Calculate spent amounts from transactions
    for (var transaction in _transactions) {
      try {
        final category = categoriesData.firstWhere(
          (c) => c.name == transaction.category,
        );
        category.spent += transaction.amount;
      } catch (e) {
        // Category not found, ignore or handle
      }
    }

    setState(() {
      _categories = categoriesData;
    });
  }

  void _updateBudgetModel(String model) {
    setState(() {
      _budgetModel = model;
    });
    _calculateBudget();
  }

  Future<void> _handleAddTransaction() async {
    if (_selectedCategory.isEmpty || _amountController.text.isEmpty) return;

    String amountClean = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    if (amountClean.isEmpty) return;

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: _selectedCategory,
      amount: double.parse(amountClean),
      description: _descController.text,
      date: DateTime.now().toIso8601String(),
    );

    setState(() {
      _transactions.add(transaction);
      _selectedCategory = "";
      _amountController.clear();
      _descController.clear();
      _showAddTransaction = false;
    });
    
    _calculateBudget();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final targetUid = _familyId ?? user.uid;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .collection('transactions')
            .doc(transaction.id)
            .set(transaction.toJson());
      } catch (e) {
        debugPrint("Error saving transaction to Firestore: $e");
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'transactions',
      jsonEncode(_transactions.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _handleDeleteTransaction(String id) async {
    setState(() {
      _transactions.removeWhere((t) => t.id == id);
    });

    _calculateBudget();
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final targetUid = _familyId ?? user.uid;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .collection('transactions')
            .doc(id)
            .delete();
      } catch (e) {
        debugPrint("Error deleting transaction from Firestore: $e");
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'transactions',
      jsonEncode(_transactions.map((e) => e.toJson()).toList()),
    );
  }

  void _onCurrencyInputChanged(String value) {
    if (value.isEmpty) {
      _amountController.text = '';
      return;
    }

    String cleanString = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanString.isEmpty) return;

    int number = int.parse(cleanString);
    String formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(number);

    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_financialData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors
                    .transparent, // Avoid solid color glitch before gradient
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFFA855F7), // purple-500
                        Color(0xFFDB2777), // pink-600
                      ],
                    ),
                  ),
                  child: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(
                      left: 16,
                      bottom: 16,
                      right: 16,
                    ),
                    title: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Dashboard Keuangan Keluarga',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Kelola anggaran rumah tangga',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.purple.shade100,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pushNamed(context, '/home'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Spouse Linking Card
                    if (_spouseEmail == null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.pink.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: Colors.pink.shade400,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hubungkan Akun Pasangan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kelola keuangan bersama-sama secara sinkron.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _showLinkSpouseDialog,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.pink.shade50,
                                foregroundColor: Colors.pink.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Hubungkan'),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Terhubung dengan: $_spouseEmail',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Budget Model Selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.pie_chart,
                                  color: Colors.purple.shade600,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Model Budgeting',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildBudgetModelButton("50/30/20"),
                              const SizedBox(width: 8),
                              _buildBudgetModelButton("60/20/20"),
                              const SizedBox(width: 8),
                              _buildBudgetModelButton("70/20/10"),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Budget Categories
                    ..._categories.map((category) {
                      double percentageSpent = category.allocated > 0
                          ? (category.spent / category.allocated) * 100
                          : 0;
                      bool isOverBudget = percentageSpent > 90;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${category.percentage.toInt()}% dari pendapatan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isOverBudget)
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.red.shade500,
                                    size: 24,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_currencyFormat.format(category.spent)} / ${_currencyFormat.format(category.allocated)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '${percentageSpent.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: percentageSpent > 100
                                        ? Colors.red.shade600
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (percentageSpent / 100).clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percentageSpent > 100
                                      ? Colors.red.shade500
                                      : percentageSpent > 90
                                      ? Colors.orange.shade500
                                      : category.color,
                                ),
                              ),
                            ),
                            if (isOverBudget) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '⚠️ Pengeluaran mendekati atau melebihi batas budget!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),

                    // Add Transaction Form
                    if (_showAddTransaction)
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tambah Pengeluaran',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Kategori',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedCategory.isEmpty
                                      ? null
                                      : _selectedCategory,
                                  hint: const Text('Pilih kategori'),
                                  items: _categories.map((cat) {
                                    return DropdownMenuItem<String>(
                                      value: cat.name,
                                      child: Text(cat.name),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedCategory = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Jumlah',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              onChanged: _onCurrencyInputChanged,
                              decoration: InputDecoration(
                                prefixText: 'Rp ',
                                hintText: '0',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.purple,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Keterangan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _descController,
                              decoration: InputDecoration(
                                hintText: 'Opsional',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.purple,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _handleAddTransaction,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple.shade500,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Simpan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => setState(
                                      () => _showAddTransaction = false,
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.grey.shade200,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Batal',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Transactions List
                    if (_transactions.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Riwayat Pengeluaran',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._transactions.reversed.take(5).map((
                              transaction,
                            ) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade100,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            transaction.category,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (transaction
                                              .description
                                              .isNotEmpty)
                                            Text(
                                              transaction.description,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          Text(
                                            DateFormat('dd/MM/yyyy').format(
                                              DateTime.parse(transaction.date),
                                            ),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '-${_currencyFormat.format(transaction.amount)}',
                                          style: TextStyle(
                                            color: Colors.red.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _handleDeleteTransaction(
                                            transaction.id,
                                          ),
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: Colors.grey.shade400,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                    const SizedBox(height: 80), // Padding for FAB
                  ]),
                ),
              ),
            ],
          ),

          if (!_showAddTransaction)
            Positioned(
              bottom: 24,
              right: 24,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA855F7), Color(0xFFDB2777)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () => setState(() => _showAddTransaction = true),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetModelButton(String label) {
    bool isSelected = _budgetModel == label;
    return Expanded(
      child: InkWell(
        onTap: () => _updateBudgetModel(label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple.shade50 : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.purple.shade500 : Colors.grey.shade200,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.purple.shade700 : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLinkSpouseDialog() async {
    final TextEditingController emailController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Hubungkan Akun Pasangan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Masukkan email akun pasangan Anda yang sudah terdaftar di aplikasi.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Pasangan',
                      hintText: 'contoh@email.com',
                      errorText: errorMessage,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty) {
                            setState(
                              () => errorMessage = "Email tidak boleh kosong",
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            if (currentUser == null)
                              throw Exception("Harap login kembali.");
                            if (email == currentUser.email) {
                              throw Exception(
                                "Tidak bisa menghubungkan ke email diri sendiri.",
                              );
                            }

                            final usersRef = FirebaseFirestore.instance
                                .collection('users');
                            final query = await usersRef
                                .where('email', isEqualTo: email)
                                .limit(1)
                                .get();

                            if (query.docs.isEmpty) {
                              setState(() {
                                errorMessage =
                                    "Pengguna dengan email ini tidak ditemukan.";
                                isLoading = false;
                              });
                              return;
                            }

                            final targetUserDoc = query.docs.first;
                            final targetUid = targetUserDoc.id;

                            // Connect: targetUid becomes the familyId
                            final batch = FirebaseFirestore.instance.batch();

                            // 1. Update Current User
                            batch.set(
                              usersRef.doc(currentUser.uid),
                              {'familyId': targetUid, 'spouseEmail': email},
                              SetOptions(merge: true),
                            );

                            // 2. Update Target Spouse User
                            batch.set(usersRef.doc(targetUid), {
                              'familyId': targetUid,
                              'spouseEmail': currentUser.email,
                            }, SetOptions(merge: true));

                            await batch.commit();

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Berhasil menghubungkan akun!'),
                                ),
                              );
                              // Refresh data
                              _loadData();
                            }
                          } catch (e) {
                            setState(() {
                              errorMessage = e.toString().replaceAll(
                                "Exception: ",
                                "",
                              );
                              isLoading = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Hubungkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
