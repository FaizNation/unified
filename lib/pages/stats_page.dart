import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  // Mock data for initial rendering
  Map<String, dynamic>? _financialData = {
    'monthlyIncome': 10000000,
    'partnerIncome': 8000000,
    'savings': 50000000,
    'rentOrMortgage': 4000000,
    'utilities': 500000,
    'groceries': 2000000,
    'transportation': 1500000,
    'insurance': 500000,
    'entertainment': 1000000,
    'otherExpenses': 500000,
    'assets': 100000000,
    'debt': 10000000,
    'weddingBudget': 150000000,
    'monthsUntilWedding': 12,
  };
  String? _phase;
  int _score = 85;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _phase = prefs.getString('phase');
    });
  }

  int _calculateMonthlyExpenses() {
    if (_financialData == null) return 0;
    return (_financialData!['rentOrMortgage'] ?? 0) +
        (_financialData!['utilities'] ?? 0) +
        (_financialData!['groceries'] ?? 0) +
        (_financialData!['transportation'] ?? 0) +
        (_financialData!['insurance'] ?? 0) +
        (_financialData!['entertainment'] ?? 0) +
        (_financialData!['otherExpenses'] ?? 0);
  }

  int _calculateTotalIncome() {
    if (_financialData == null) return 0;
    return (_financialData!['monthlyIncome'] ?? 0) +
        (_financialData!['partnerIncome'] ?? 0);
  }

  int _calculateSavingsRate() {
    final income = _calculateTotalIncome();
    final expenses = _calculateMonthlyExpenses();
    if (income == 0) return 0;
    return (((income - expenses) / income) * 100).round();
  }

  int _calculateMonthlySavingsCapacity() {
    final income = _calculateTotalIncome();
    final expenses = _calculateMonthlyExpenses();
    return income - expenses;
  }

  String _formatCurrency(int amount) {
    // Basic currency formatter for demo, replace with intl package normally
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // Inherited from common background if needed
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFDF2F8), // pink-50
              Color(0xFFFAF5FF), // purple-50
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 96.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistik',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ringkasan keuangan Anda',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54, // gray-600 approx
                        ),
                      ),
                    ],
                  ),
                ),

                if (_financialData == null)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada data keuangan. Silakan input data keuangan terlebih dahulu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Klik menu "Input Keuangan" di halaman Home untuk memulai',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Score Card (for pre-marriage)
                      if (_phase == "pre" && _score > 0)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                              ),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Skor Kesiapan Menikah',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        '$_score',
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        'dari 100',
                                        style: TextStyle(
                                          color: Color(0xFFF3E8FF),
                                        ), // purple-100
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        height: 1,
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _score >= 80
                                            ? "✨ Sangat Siap!"
                                            : _score >= 60
                                            ? "👍 Hampir Siap"
                                            : _score >= 40
                                            ? "💪 Perlu Perbaikan"
                                            : "📝 Mulai Persiapan",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFFF3E8FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (_phase == "pre" && _score > 0)
                        const SizedBox(height: 16),

                      // Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.25,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatGridItem(
                            title: 'Total Pendapatan',
                            value:
                                'Rp ${_formatCurrency(_calculateTotalIncome())}',
                            icon: Icons.attach_money,
                            iconColor: Colors.green.shade600,
                            iconBgColor: Colors.green.shade100,
                          ),
                          _buildStatGridItem(
                            title: 'Total Tabungan',
                            value:
                                'Rp ${_formatCurrency(_financialData!['savings'] ?? 0)}',
                            icon: Icons.savings_outlined,
                            iconColor: Colors.blue.shade600,
                            iconBgColor: Colors.blue.shade100,
                          ),
                          _buildStatGridItem(
                            title: 'Pengeluaran Bulanan',
                            value:
                                'Rp ${_formatCurrency(_calculateMonthlyExpenses())}',
                            icon: Icons.trending_up,
                            iconColor: Colors.red.shade600,
                            iconBgColor: Colors.red.shade100,
                          ),
                          _buildStatGridItem(
                            title: 'Rasio Tabungan',
                            value: '${_calculateSavingsRate()}%',
                            icon: Icons.calendar_today_outlined,
                            iconColor: const Color(0xFF9333EA),
                            iconBgColor: Colors.purple.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Monthly Savings Capacity
                      _buildSummaryCard(
                        title: 'Kemampuan Menabung Bulanan',
                        titleColor: _calculateMonthlySavingsCapacity() >= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        titleIcon: Icons.trending_up,
                        borderColor: _calculateMonthlySavingsCapacity() >= 0
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sisa per bulan',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Text(
                              'Rp ${_formatCurrency(_calculateMonthlySavingsCapacity())}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _calculateMonthlySavingsCapacity() >= 0
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Income Breakdown
                      _buildGeneralCard(
                        title: 'Rincian Pendapatan',
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Pendapatan Anda',
                              'Rp ${_formatCurrency(_financialData!['monthlyIncome'] ?? 0)}',
                            ),
                            if ((_financialData!['partnerIncome'] ?? 0) >
                                0) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Pendapatan Pasangan',
                                'Rp ${_formatCurrency(_financialData!['partnerIncome'] ?? 0)}',
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Total',
                              'Rp ${_formatCurrency(_calculateTotalIncome())}',
                              isTotal: true,
                              valueColor: Colors.green.shade600,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Detailed Breakdown
                      _buildGeneralCard(
                        title: 'Rincian Pengeluaran',
                        child: Column(
                          children: [
                            if ((_financialData!['rentOrMortgage'] ?? 0) > 0)
                              _buildIconInfoRow(
                                'Sewa/KPR',
                                Icons.home_outlined,
                                Colors.orange.shade600,
                                'Rp ${_formatCurrency(_financialData!['rentOrMortgage'])}',
                              ),
                            if ((_financialData!['utilities'] ?? 0) > 0)
                              _buildIconInfoRow(
                                'Utilitas',
                                Icons.bolt,
                                Colors.yellow.shade700,
                                'Rp ${_formatCurrency(_financialData!['utilities'])}',
                              ),
                            if ((_financialData!['groceries'] ?? 0) > 0)
                              _buildIconInfoRow(
                                'Belanja',
                                Icons.shopping_cart_outlined,
                                Colors.green.shade600,
                                'Rp ${_formatCurrency(_financialData!['groceries'])}',
                              ),
                            if ((_financialData!['transportation'] ?? 0) > 0)
                              _buildIconInfoRow(
                                'Transportasi',
                                Icons.directions_car_outlined,
                                Colors.blue.shade600,
                                'Rp ${_formatCurrency(_financialData!['transportation'])}',
                              ),
                            if ((_financialData!['insurance'] ?? 0) > 0)
                              _buildIconInfoRow(
                                'Asuransi',
                                Icons.shield_outlined,
                                Colors.indigo.shade600,
                                'Rp ${_formatCurrency(_financialData!['insurance'])}',
                              ),
                            if ((_financialData!['entertainment'] ?? 0) > 0)
                              _buildIconInfoRow(
                                'Hiburan',
                                Icons.sports_esports_outlined,
                                Colors.pink.shade600,
                                'Rp ${_formatCurrency(_financialData!['entertainment'])}',
                              ),
                            if ((_financialData!['otherExpenses'] ?? 0) > 0)
                              _buildIconInfoRow(
                                'Lainnya',
                                Icons.account_balance_wallet_outlined,
                                Colors.grey.shade600,
                                'Rp ${_formatCurrency(_financialData!['otherExpenses'])}',
                              ),

                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Total',
                              'Rp ${_formatCurrency(_calculateMonthlyExpenses())}',
                              isTotal: true,
                              valueColor: Colors.red.shade600,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Assets & Debts
                      if ((_financialData!['assets'] ?? 0) > 0)
                        _buildSummaryCard(
                          title: 'Total Aset',
                          titleColor: Colors.blue.shade600,
                          titleIcon: Icons.home,
                          borderColor: Colors.blue.shade200,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Nilai Aset',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                'Rp ${_formatCurrency(_financialData!['assets'])}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if ((_financialData!['debt'] ?? 0) > 0) ...[
                        const SizedBox(height: 12),
                        _buildSummaryCard(
                          title: 'Total Hutang',
                          titleColor: Colors.red.shade600,
                          titleIcon: Icons.credit_card,
                          borderColor: Colors.red.shade200,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Jumlah Hutang',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                'Rp ${_formatCurrency(_financialData!['debt'])}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Wedding Planning (for pre-marriage)
                      if (_phase == "pre" &&
                          (_financialData!['weddingBudget'] ?? 0) > 0) ...[
                        const SizedBox(height: 16),
                        _buildSummaryCard(
                          title: 'Rencana Pernikahan',
                          titleColor: const Color(0xFF7E22CE), // purple-700
                          borderColor: Colors.pink.shade200,
                          backgroundColor: const Color(
                            0xFFFDF2F8,
                          ), // pink-50 approx blending
                          child: Column(
                            children: [
                              _buildInfoRow(
                                'Target Budget',
                                'Rp ${_formatCurrency(_financialData!['weddingBudget'])}',
                              ),
                              if ((_financialData!['monthsUntilWedding'] ?? 0) >
                                  0) ...[
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  'Waktu Tersisa',
                                  '${_financialData!['monthsUntilWedding']} bulan',
                                ),
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  'Harus Ditabung/Bulan',
                                  'Rp ${_formatCurrency((_financialData!['weddingBudget'] / _financialData!['monthsUntilWedding']).ceil())}',
                                  isTotal: true,
                                  valueColor: const Color(0xFF9333EA),
                                ),
                                if (_calculateMonthlySavingsCapacity() >=
                                    0) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Status Kemampuan',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (_calculateMonthlySavingsCapacity() >=
                                            (_financialData!['weddingBudget'] /
                                                _financialData!['monthsUntilWedding']))
                                          Text(
                                            '✅ Anda mampu menabung untuk target ini!',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.green.shade600,
                                            ),
                                          )
                                        else
                                          Text(
                                            '⚠️ Perlu tambahan Rp ${_formatCurrency(((_financialData!['weddingBudget'] / _financialData!['monthsUntilWedding']) - _calculateMonthlySavingsCapacity()).ceil())} per bulan',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.orange.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatGridItem({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralCard({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required Color titleColor,
    IconData? titleIcon,
    required Color borderColor,
    Color backgroundColor = Colors.white,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, color: titleColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? Colors.grey.shade800 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildIconInfoRow(
    String label,
    IconData icon,
    Color iconColor,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
