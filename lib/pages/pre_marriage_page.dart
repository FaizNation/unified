import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PreMarriagePage extends StatefulWidget {
  const PreMarriagePage({super.key});

  @override
  State<PreMarriagePage> createState() => _PreMarriagePageState();
}

class _PreMarriagePageState extends State<PreMarriagePage> {
  Map<String, dynamic>? _financialData;
  int _readinessScore = 0;
  String _status = "green"; // "green", "yellow", "red"
  double _debtToIncome = 0;
  double _monthlySavings = 0;
  double _totalSavingsByWedding = 0;
  int _recommendedMonths = 0;

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

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDataString = prefs.getString('financialData');

    if (savedDataString == null && mounted) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    if (savedDataString != null) {
      final financialData = jsonDecode(savedDataString);
      setState(() {
        _financialData = financialData;
      });
      _calculateMetrics(financialData);
    }
  }

  double _parseDouble(dynamic value, {double defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  void _calculateMetrics(Map<String, dynamic> data) {
    final income = _parseDouble(data['monthlyIncome']);
    final expenses =
        _parseDouble(data['rentOrMortgage']) +
        _parseDouble(data['utilities']) +
        _parseDouble(data['groceries']) +
        _parseDouble(data['transportation']) +
        _parseDouble(data['insurance']) +
        _parseDouble(data['entertainment']) +
        _parseDouble(data['otherExpenses']);
    final debt = _parseDouble(data['debt']);
    final assets = _parseDouble(data['assets']);
    final weddingBudget = _parseDouble(data['weddingBudget']);
    int months = _parseDouble(
      data['monthsUntilWedding'],
      defaultValue: 12,
    ).toInt();
    if (months <= 0) months = 12; // fallback

    // Debt to Income Ratio
    final dti = income > 0 ? (debt / income) * 100 : 0.0;

    // Monthly Savings
    final savings = income - expenses;

    // Total savings by wedding
    final totalSavings = (savings * months) + assets;

    // Calculate readiness score (0-100)
    int score = 100;

    // Debt to Income penalty (max -40 points)
    if (dti > 50)
      score -= 40;
    else if (dti > 30)
      score -= 30;
    else if (dti > 20)
      score -= 20;
    else if (dti > 10)
      score -= 10;

    // Savings vs Wedding Budget (max -40 points)
    final savingsGap = weddingBudget - totalSavings;
    if (savingsGap > weddingBudget * 0.5)
      score -= 40;
    else if (savingsGap > weddingBudget * 0.3)
      score -= 30;
    else if (savingsGap > weddingBudget * 0.1)
      score -= 20;
    else if (savingsGap > 0)
      score -= 10;

    // Monthly savings ratio penalty (max -20 points)
    final savingsRatio = income > 0 ? (savings / income) * 100 : 0.0;
    if (savingsRatio < 10)
      score -= 20;
    else if (savingsRatio < 20)
      score -= 10;

    score = max(0, score);

    // Determine status
    String statusStr = "red";
    if (score >= 70)
      statusStr = "green";
    else if (score >= 40)
      statusStr = "yellow";

    // Calculate recommended months
    int recMonths = months;
    if (savingsGap > 0 && savings > 0) {
      final recommended = (savingsGap / savings).ceil();
      recMonths = recommended + months;
    }

    setState(() {
      _debtToIncome = dti;
      _monthlySavings = savings;
      _totalSavingsByWedding = totalSavings;
      _readinessScore = score;
      _status = statusStr;
      _recommendedMonths = recMonths;
    });
  }

  Color _getStatusColor() {
    switch (_status) {
      case 'green':
        return Colors.green.shade500;
      case 'yellow':
        return Colors.orange.shade500;
      case 'red':
        return Colors.red.shade500;
      default:
        return Colors.green.shade500;
    }
  }

  Color _getStatusBgColor() {
    switch (_status) {
      case 'green':
        return Colors.green.shade50;
      case 'yellow':
        return Colors.orange.shade50;
      case 'red':
        return Colors.red.shade50;
      default:
        return Colors.green.shade50;
    }
  }

  Color _getStatusTextColor() {
    switch (_status) {
      case 'green':
        return Colors.green.shade700;
      case 'yellow':
        return Colors.orange.shade700;
      case 'red':
        return Colors.red.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  String _getStatusText() {
    switch (_status) {
      case 'green':
        return "Siap Menikah!";
      case 'yellow':
        return "Perlu Penyesuaian";
      case 'red':
        return "Belum Siap";
      default:
        return "Siap Menikah!";
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case 'green':
        return Icons.check_circle;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_financialData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    double weddingBudget = _parseDouble(_financialData!['weddingBudget']);
    int monthsUntilWedding = _parseDouble(
      _financialData!['monthsUntilWedding'],
      defaultValue: 12,
    ).toInt();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
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
                      'Kesiapan Finansial Pernikahan',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Analisis keuangan Anda',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.pink.shade100,
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
                // Readiness Score
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(),
                    border: Border.all(color: _getStatusColor(), width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Skor Kesiapan Menikah',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Icon(
                            _getStatusIcon(),
                            color: _getStatusColor(),
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _readinessScore.toString(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getStatusTextColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Debt to Income Ratio
                Container(
                  padding: const EdgeInsets.all(24),
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
                      Text(
                        'Rasio Hutang terhadap Pendapatan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${_debtToIncome.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_debtToIncome < 30)
                            Text(
                              'Sehat',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else if (_debtToIncome < 50)
                            Text(
                              'Hati-hati',
                              style: TextStyle(
                                color: Colors.orange.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else
                            Text(
                              'Bahaya',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_debtToIncome / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _debtToIncome < 30
                                ? Colors.green.shade500
                                : _debtToIncome < 50
                                ? Colors.orange.shade500
                                : Colors.red.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Savings Projection
                Container(
                  padding: const EdgeInsets.all(24),
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
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Proyeksi Tabungan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildProjectionRow(
                        'Tabungan per bulan',
                        _currencyFormat.format(_monthlySavings),
                      ),
                      const SizedBox(height: 12),
                      _buildProjectionRow(
                        'Total saat menikah',
                        _currencyFormat.format(_totalSavingsByWedding),
                      ),
                      const SizedBox(height: 12),
                      _buildProjectionRow(
                        'Budget pernikahan',
                        _currencyFormat.format(weddingBudget),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Recommendations
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFAF5FF),
                        Color(0xFFFDF2F8),
                      ], // purple-50 to pink-50
                    ),
                    border: Border.all(color: Colors.purple.shade200, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rekomendasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_status == "green")
                        _buildRecommendationItem(
                          icon: Icons.check_circle,
                          color: Colors.green.shade600,
                          text:
                              'Keuangan Anda sudah siap untuk menikah! Pertahankan pola tabungan yang baik.',
                        )
                      else ...[
                        if (_totalSavingsByWedding < weddingBudget)
                          _buildRecommendationItem(
                            icon: Icons.calendar_today,
                            color: Colors.purple.shade600,
                            text:
                                'Pertimbangkan untuk menunda pernikahan ${_recommendedMonths - monthsUntilWedding} bulan lagi atau kurangi budget menjadi ${_currencyFormat.format(_totalSavingsByWedding)}.',
                          ),
                        if (_debtToIncome > 30)
                          _buildRecommendationItem(
                            icon: Icons.warning_amber_rounded,
                            color: Colors.purple.shade600,
                            text:
                                'Fokus melunasi hutang terlebih dahulu. Targetkan rasio hutang di bawah 30% dari pendapatan bulanan.',
                          ),
                        if (_monthlySavings <
                            _parseDouble(_financialData!['monthlyIncome']) *
                                0.2)
                          _buildRecommendationItem(
                            icon: Icons.account_balance_wallet,
                            color: Colors.purple.shade600,
                            text:
                                'Tingkatkan tabungan bulanan minimal 20% dari pendapatan dengan mengurangi pengeluaran tidak penting.',
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
