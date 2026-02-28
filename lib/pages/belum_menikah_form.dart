import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class BelumMenikahForm extends StatefulWidget {
  final VoidCallback onSubmit;

  const BelumMenikahForm({super.key, required this.onSubmit});

  @override
  State<BelumMenikahForm> createState() => _BelumMenikahFormState();
}

class _BelumMenikahFormState extends State<BelumMenikahForm> {
  final _formKey = GlobalKey<FormState>();

  final _gajiController = TextEditingController();
  final _pendapatanTambahanController = TextEditingController();
  final _pengeluaranController = TextEditingController();
  final _hutangController = TextEditingController();
  final _asetController = TextEditingController();
  final _tabunganController = TextEditingController();

  int _targetNikahTahun = 1; // Default 1 tahun
  final _estimasiResepsiController = TextEditingController();
  final _estimasiMaharController = TextEditingController();
  final _estimasiSeserahanController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _gajiController.dispose();

    _pendapatanTambahanController.dispose();
    _pengeluaranController.dispose();
    _hutangController.dispose();
    _asetController.dispose();
    _tabunganController.dispose();
    _estimasiResepsiController.dispose();
    _estimasiMaharController.dispose();
    _estimasiSeserahanController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("API Key Gemini tidak ditemukan di .env");
      }

      final model = GenerativeModel(model: 'gemini-2.0-flash-001', apiKey: apiKey);

      final prompt =
          '''
      Saya sedang merencanakan pernikahan. Tolong berikan analisis finansial dan proyeksi stabilitas pasca-nikah berdasarkan data berikut:
      - Gaji Bulanan: Rp ${_gajiController.text}
      - Pendapatan Tambahan: Rp ${_pendapatanTambahanController.text}
      - Pengeluaran Bulanan: Rp ${_pengeluaranController.text}
      - Hutang/Cicilan: Rp ${_hutangController.text}
      - Total Aset: Rp ${_asetController.text}
      - Tabungan Saat Ini: Rp ${_tabunganController.text}
      - Target Menikah: $_targetNikahTahun tahun lagi
      - Estimasi Biaya Resepsi: Rp ${_estimasiResepsiController.text}
      - Estimasi Biaya Mahar: Rp ${_estimasiMaharController.text}
      - Estimasi Biaya Seserahan: Rp ${_estimasiSeserahanController.text}

      Berikan analisis terstruktur mengenai:
      1. Kesiapan Finansial untuk biaya pernikahan (Resepsi+Mahar+Seserahan) dalam waktu $_targetNikahTahun tahun.
      2. Saran pengelolaan gaji dan tabungan bulanan agar target tercapai.
      3. Proyeksi Stabilitas Jangka Panjang pasca-nikah (dengan asumsi pengeluaran meningkat).
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (mounted) {
        _showAnalysisDialog(
          response.text ?? 'Tidak ada analisis yang dapat diberikan.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAnalysisDialog(String text) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Proyeksi & Analisis Pernikahan'),
          content: SingleChildScrollView(child: Text(text)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onSubmit();
              },
              child: const Text('Tutup & Selesai'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrencyField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'Rp ',
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Wajib diisi';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Informasi Keuangan Saat Ini',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCurrencyField('Gaji Bulanan', _gajiController),
          _buildCurrencyField(
            'Pendapatan Tambahan',
            _pendapatanTambahanController,
          ),
          _buildCurrencyField(
            'Pengeluaran Bulanan (Makan, Kost, dll)',
            _pengeluaranController,
          ),
          _buildCurrencyField('Total Hutang / Cicilan', _hutangController),
          _buildCurrencyField('Total Aset Berharga', _asetController),
          _buildCurrencyField('Total Tabungan Saat Ini', _tabunganController),

          const Divider(height: 32, thickness: 2),

          const Text(
            'Target Pernikahan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _targetNikahTahun,
            decoration: const InputDecoration(
              labelText: 'Target Menikah Dalam (Tahun)',
              border: OutlineInputBorder(),
            ),
            items: [1, 2, 3, 4, 5].map((int year) {
              return DropdownMenuItem<int>(
                value: year,
                child: Text('$year Tahun'),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _targetNikahTahun = newValue!;
              });
            },
          ),
          const SizedBox(height: 16),

          _buildCurrencyField(
            'Estimasi Anggaran Resepsi',
            _estimasiResepsiController,
          ),
          _buildCurrencyField(
            'Estimasi Anggaran Mahar',
            _estimasiMaharController,
          ),
          _buildCurrencyField(
            'Estimasi Anggaran Seserahan',
            _estimasiSeserahanController,
          ),

          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Simpan & Analisis Proyeksi'),
                ),
        ],
      ),
    );
  }
}
