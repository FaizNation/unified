import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class FinancialInputPage extends StatefulWidget {
  const FinancialInputPage({super.key});

  @override
  State<FinancialInputPage> createState() => _FinancialInputPageState();
}

class _FinancialInputPageState extends State<FinancialInputPage> {
  String _phase = "";

  // Controllers
  final Map<String, TextEditingController> _controllers = {
    'monthlyIncome': TextEditingController(),
    'partnerIncome': TextEditingController(),
    'savings': TextEditingController(),
    'debt': TextEditingController(),
    'assets': TextEditingController(),
    'rentOrMortgage': TextEditingController(),
    'utilities': TextEditingController(),
    'groceries': TextEditingController(),
    'transportation': TextEditingController(),
    'insurance': TextEditingController(),
    'entertainment': TextEditingController(),
    'otherExpenses': TextEditingController(),
    'weddingBudget': TextEditingController(),
    'monthsUntilWedding': TextEditingController(),
  };

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhase = prefs.getString('phase');

    if (savedPhase == null && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    setState(() {
      _phase = savedPhase ?? "";
    });

    final savedDataString = prefs.getString('financialData');
    if (savedDataString != null) {
      final Map<String, dynamic> savedData = jsonDecode(savedDataString);

      savedData.forEach((key, value) {
        if (_controllers.containsKey(key)) {
          if (value != null && value.toString().isNotEmpty && value != 0) {
            if (key == 'monthsUntilWedding') {
              _controllers[key]!.text = value.toString();
            } else {
              _controllers[key]!.text = _currencyFormat.format(
                num.parse(value.toString()),
              );
            }
          }
        }
      });
    }
  }

  double _parseCurrency(String value) {
    if (value.isEmpty) return 0;
    String cleanString = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanString.isEmpty) return 0;
    return double.parse(cleanString);
  }

  void _onCurrencyInputChanged(String key, String value) {
    if (value.isEmpty) {
      _controllers[key]!.text = '';
      return;
    }

    String cleanString = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanString.isEmpty) return;

    int number = int.parse(cleanString);
    String formatted = _currencyFormat.format(number);

    _controllers[key]!.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  // ALGORITMA 1: Kesiapan Menikah (Fase Pre)
  int _calculateReadinessScore(Map<String, dynamic> data) {
    int score = 0;
    double income = (data['monthlyIncome'] ?? 0) + (data['partnerIncome'] ?? 0);
    double totalExpenses =
        (data['rentOrMortgage'] ?? 0) +
        (data['utilities'] ?? 0) +
        (data['groceries'] ?? 0) +
        (data['transportation'] ?? 0) +
        (data['insurance'] ?? 0) +
        (data['entertainment'] ?? 0) +
        (data['otherExpenses'] ?? 0);
    double monthlySavings = income - totalExpenses;

    if (income >= 10000000)
      score += 20;
    else if (income >= 7000000)
      score += 15;
    else if (income >= 5000000)
      score += 10;
    else
      score += 5;

    double savings = data['savings'] ?? 0;
    if (savings >= 50000000)
      score += 25;
    else if (savings >= 30000000)
      score += 20;
    else if (savings >= 15000000)
      score += 15;
    else if (savings >= 5000000)
      score += 10;
    else
      score += 5;

    double debt = data['debt'] ?? 0;
    double debtRatio = income > 0 ? (debt / income) : 100;
    if (debtRatio == 0)
      score += 20;
    else if (debtRatio < 0.3)
      score += 15; // Rasio hutang aman di bawah 30%
    else if (debtRatio < 0.6)
      score += 10;
    else
      score += 5;

    if (monthlySavings >= income * 0.3)
      score += 20;
    else if (monthlySavings >= income * 0.2)
      score += 15;
    else if (monthlySavings >= income * 0.1)
      score += 10;
    else
      score += 5;

    double weddingBudget = data['weddingBudget'] ?? 0;
    int monthsUntilWedding = (data['monthsUntilWedding'] ?? 0).toInt();

    if (weddingBudget > 0 && monthsUntilWedding > 0) {
      double monthlyWeddingSavingsNeeded = weddingBudget / monthsUntilWedding;
      if (monthlySavings >= monthlyWeddingSavingsNeeded * 1.5)
        score += 15;
      else if (monthlySavings >= monthlyWeddingSavingsNeeded)
        score += 10;
      else
        score += 5;
    } else {
      score += 5;
    }

    return min(score, 100);
  }

  // ALGORITMA 2 (BARU): Kesehatan Finansial Pasca-Nikah (Fase Post)
  int _calculatePostMarriageHealthScore(Map<String, dynamic> data) {
    int score = 0;
    double income = (data['monthlyIncome'] ?? 0) + (data['partnerIncome'] ?? 0);
    double totalExpenses =
        (data['rentOrMortgage'] ?? 0) +
        (data['utilities'] ?? 0) +
        (data['groceries'] ?? 0) +
        (data['transportation'] ?? 0) +
        (data['insurance'] ?? 0) +
        (data['entertainment'] ?? 0) +
        (data['otherExpenses'] ?? 0);

    double monthlySavings = income - totalExpenses;
    double savings = data['savings'] ?? 0;
    double debt = data['debt'] ?? 0;

    // 1. Dana Darurat (Max 30 Poin) - Ideal minimal 6x pengeluaran bulanan
    double targetDanaDarurat = totalExpenses * 6;
    if (targetDanaDarurat > 0) {
      if (savings >= targetDanaDarurat)
        score += 30; // Sangat aman (6+ bulan tercover)
      else if (savings >= totalExpenses * 3)
        score += 20; // Cukup (3-5 bulan tercover)
      else if (savings >= totalExpenses * 1)
        score += 10; // Bahaya (Hanya 1-2 bulan)
    } else if (savings > 0) {
      score +=
          30; // Jika tidak ada pengeluaran (jarang terjadi) namun punya tabungan
    }

    // 2. Kapasitas Menabung Bulanan (Max 30 Poin)
    double savingsRate = income > 0 ? (monthlySavings / income) : 0;
    if (savingsRate >= 0.20)
      score += 30; // Sehat (Bisa nabung >= 20%)
    else if (savingsRate >= 0.10)
      score += 20; // Cukup (Nabung >= 10%)
    else if (savingsRate > 0)
      score += 10; // Bahaya (Nabung di bawah 10%)

    // 3. Rasio Beban Hutang DTI (Max 40 Poin)
    double debtRatio = income > 0 ? (debt / income) : (debt > 0 ? 1 : 0);
    if (debtRatio == 0)
      score += 40; // Bebas hutang
    else if (debtRatio <= 0.30)
      score += 30; // Hutang sehat KPR/Cicilan (di bawah 30% gaji)
    else if (debtRatio <= 0.40)
      score += 15; // Warning KPR mepet
    else
      score += 0; // Terlilit hutang (Beban cicilan di atas 40%)

    return score.clamp(0, 100);
  }

  void _handleSubmit() async {
    final Map<String, dynamic> dataToSave = {
      'monthlyIncome': _parseCurrency(_controllers['monthlyIncome']!.text),
      'partnerIncome': _parseCurrency(_controllers['partnerIncome']!.text),
      'savings': _parseCurrency(_controllers['savings']!.text),
      'debt': _parseCurrency(_controllers['debt']!.text),
      'assets': _parseCurrency(_controllers['assets']!.text),
      'rentOrMortgage': _parseCurrency(_controllers['rentOrMortgage']!.text),
      'utilities': _parseCurrency(_controllers['utilities']!.text),
      'groceries': _parseCurrency(_controllers['groceries']!.text),
      'transportation': _parseCurrency(_controllers['transportation']!.text),
      'insurance': _parseCurrency(_controllers['insurance']!.text),
      'entertainment': _parseCurrency(_controllers['entertainment']!.text),
      'otherExpenses': _parseCurrency(_controllers['otherExpenses']!.text),
      'weddingBudget': _parseCurrency(_controllers['weddingBudget']!.text),
      'monthsUntilWedding':
          int.tryParse(_controllers['monthsUntilWedding']!.text) ?? 0,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('financialData', jsonEncode(dataToSave));

    if (!mounted) return;

    if (_phase == "pre") {
      final score = _calculateReadinessScore(dataToSave);
      await prefs.setString('readinessScore', score.toString());
    } else if (_phase == "post") {
      // SIMPAN SKOR KESEHATAN FINANSIAL PASCA-NIKAH KE LOKAL
      final healthScore = _calculatePostMarriageHealthScore(dataToSave);
      await prefs.setString('postMarriageScore', healthScore.toString());
    }

    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151), // gray-700
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String key,
    bool isNumeric = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers[key],
            keyboardType: TextInputType.number,
            onChanged: (val) {
              if (!isNumeric) {
                _onCurrencyInputChanged(key, val);
              }
            },
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  !isNumeric ? 'Rp' : '',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              suffixText: isNumeric ? 'bulan' : null,
              hintText: '0',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.purple, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFEC4899), // pink-500
                Color(0xFF9333EA), // purple-600
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Keuangan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Isi informasi keuangan Anda',
              style: TextStyle(color: Color(0xFFFCE7F3), fontSize: 14),
            ),
          ],
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Income Section
            _buildSectionHeader(
              icon: Icons.trending_up,
              color: Colors.green.shade600,
              title: 'Pendapatan',
            ),
            _buildInputField(
              title: 'Pendapatan Bulanan Anda',
              icon: Icons.attach_money,
              iconColor: Colors.green.shade600,
              iconBgColor: Colors.green.shade100,
              key: 'monthlyIncome',
            ),
            if (_phase == "post")
              _buildInputField(
                title: 'Pendapatan Pasangan',
                icon: Icons.people,
                iconColor: Colors.blue.shade600,
                iconBgColor: Colors.blue.shade100,
                key: 'partnerIncome',
              ),
            const SizedBox(height: 24),

            // Assets & Savings Section
            _buildSectionHeader(
              icon: Icons.account_balance_wallet,
              color: Colors.blue.shade600,
              title: 'Aset & Tabungan',
            ),
            _buildInputField(
              title: 'Total Tabungan Saat Ini',
              icon: Icons.account_balance_wallet,
              iconColor: Colors.blue.shade600,
              iconBgColor: Colors.blue.shade100,
              key: 'savings',
            ),
            _buildInputField(
              title: 'Total Nilai Aset',
              icon: Icons.home,
              iconColor: Colors.purple.shade600,
              iconBgColor: Colors.purple.shade100,
              key: 'assets',
            ),
            _buildInputField(
              title: 'Cicilan/Hutang Bulanan',
              icon: Icons.credit_card,
              iconColor: Colors.red.shade600,
              iconBgColor: Colors.red.shade100,
              key: 'debt',
            ),
            const SizedBox(height: 24),

            // Expenses Section
            _buildSectionHeader(
              icon: Icons.credit_card,
              color: Colors.orange.shade600,
              title: 'Pengeluaran Bulanan',
            ),
            _buildInputField(
              title: 'Sewa / KPR',
              icon: Icons.home,
              iconColor: Colors.orange.shade600,
              iconBgColor: Colors.orange.shade100,
              key: 'rentOrMortgage',
            ),
            _buildInputField(
              title: 'Utilitas (Listrik, Air, dll)',
              icon: Icons.bolt,
              iconColor: Colors.yellow.shade700,
              iconBgColor: Colors.yellow.shade100,
              key: 'utilities',
            ),
            _buildInputField(
              title: 'Belanja & Kebutuhan',
              icon: Icons.shopping_cart,
              iconColor: Colors.green.shade600,
              iconBgColor: Colors.green.shade100,
              key: 'groceries',
            ),
            _buildInputField(
              title: 'Transportasi',
              icon: Icons.directions_car,
              iconColor: Colors.blue.shade600,
              iconBgColor: Colors.blue.shade100,
              key: 'transportation',
            ),
            _buildInputField(
              title: 'Asuransi',
              icon: Icons.security,
              iconColor: Colors.indigo.shade600,
              iconBgColor: Colors.indigo.shade100,
              key: 'insurance',
            ),
            _buildInputField(
              title: 'Hiburan & Rekreasi',
              icon: Icons.sports_esports,
              iconColor: Colors.pink.shade600,
              iconBgColor: Colors.pink.shade100,
              key: 'entertainment',
            ),
            _buildInputField(
              title: 'Pengeluaran Lainnya',
              icon: Icons.account_balance_wallet,
              iconColor: Colors.grey.shade600,
              iconBgColor: Colors.grey.shade100,
              key: 'otherExpenses',
            ),
            const SizedBox(height: 24),

            // Wedding Section (Only if pre)
            if (_phase == "pre") ...[
              _buildSectionHeader(
                icon: Icons.favorite,
                color: Colors.pink.shade600,
                title: 'Rencana Pernikahan',
              ),
              _buildInputField(
                title: 'Estimasi Budget Pernikahan',
                icon: Icons.attach_money,
                iconColor: Colors.purple.shade600,
                iconBgColor: Colors.purple.shade50,
                key: 'weddingBudget',
              ),
              _buildInputField(
                title: 'Waktu Hingga Pernikahan',
                icon: Icons.calendar_month,
                iconColor: Colors.purple.shade600,
                iconBgColor: Colors.purple.shade50,
                key: 'monthsUntilWedding',
                isNumeric: true,
              ),
              const SizedBox(height: 24),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF9333EA)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _phase == 'pre'
                          ? 'Analisis Kesiapan Menikah'
                          : 'Analisis Kesehatan Finansial',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
