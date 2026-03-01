import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  String? _selectedPhase; // 'pre' or 'post'

  void _handleContinue() async {
    if (_selectedPhase != null) {
      // Save phase locally or to Firebase
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phase', _selectedPhase!);

      // For now, just navigate
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                IconButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.black54),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Header Icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFEC4899), // pink-500
                                    Color(0xFF9333EA), // purple-600
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title
                            const Text(
                              'Selamat Datang di Unified',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),

                            // Subtitle
                            Text(
                              'Platform manajemen keuangan untuk pasangan dan keluarga',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),

                            // Phase Selections
                            _buildPhaseSelectionCard(
                              id: 'pre',
                              title: 'Fase Pra-Nikah',
                              subtitle:
                                  'Rencanakan keuangan untuk pernikahan Anda',
                              icon: Icons.favorite,
                              isSelected: _selectedPhase == 'pre',
                              activeColor: const Color(0xFFEC4899), // pink-500
                              activeBgColor: const Color(0xFFFDF2F8), // pink-50
                              onTap: () {
                                setState(() {
                                  _selectedPhase = 'pre';
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            _buildPhaseSelectionCard(
                              id: 'post',
                              title: 'Fase Pasca-Nikah',
                              subtitle:
                                  'Kelola anggaran rumah tangga bersama pasangan',
                              icon: Icons.group,
                              isSelected: _selectedPhase == 'post',
                              activeColor: const Color(
                                0xFFA855F7,
                              ), // purple-500
                              activeBgColor: const Color(
                                0xFFFAF5FF,
                              ), // purple-50
                              onTap: () {
                                setState(() {
                                  _selectedPhase = 'post';
                                });
                              },
                            ),
                            const SizedBox(height: 48),

                            // Continue Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _selectedPhase == null
                                    ? null
                                    : _handleContinue,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: _selectedPhase == null
                                      ? Colors.grey.shade300
                                      : Colors.transparent,
                                  elevation: _selectedPhase == null ? 0 : 4,
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: _selectedPhase == null
                                        ? null
                                        : const LinearGradient(
                                            colors: [
                                              Color(0xFFEC4899), // pink-500
                                              Color(0xFF9333EA), // purple-600
                                            ],
                                          ),
                                    borderRadius: BorderRadius.circular(16),
                                    color: _selectedPhase == null
                                        ? Colors.grey.shade300
                                        : null,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Lanjutkan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseSelectionCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color activeBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.15),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.black87 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
