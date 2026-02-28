import 'package:flutter/material.dart';

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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save data to Firebase and/or use Gemini for analysis
      widget.onSubmit();
    }
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
          ElevatedButton(
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
