import 'package:flutter/material.dart';
import 'belum_menikah_form.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  String? _selectedStatus; // null means hasn't selected yet

  @override
  Widget build(BuildContext context) {
    if (_selectedStatus == null) {
      // Show selection screen
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Silakan pilih status Anda:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'Belum Menikah';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Belum Menikah'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'Sudah Menikah';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Sudah Menikah'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_selectedStatus == 'Belum Menikah') {
      return BelumMenikahForm(
        onSubmit: () {
          // Temporarily go back to status selection after submit
          setState(() {
            _selectedStatus = null;
          });
        },
      );
    }

    // Show content based on selection
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Selamat datang di halaman Home',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 16),
          Text(
            'Mode aktif: $_selectedStatus',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Option to change status
              setState(() {
                _selectedStatus = null;
              });
            },
            child: const Text('Ubah Status'),
          ),
        ],
      ),
    );
  }
}
