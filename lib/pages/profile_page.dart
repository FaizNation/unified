import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Mock data for the current user
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            _currentUser = {
              'nama': data['name'] ?? 'Pengguna Unified',
              'email': user.email ?? data['email'] ?? 'user@example.com',
              'umur': data['age'] ?? 0,
              'statusPernikahan': data['maritalStatus'] ?? 'belum',
            };
          });
        }
      } catch (e) {
        // Fallback
        if (mounted) {
          setState(() {
            _currentUser = {
              'nama': 'Pengguna Unified',
              'email': user.email ?? 'user@example.com',
              'umur': 0,
              'statusPernikahan': 'belum',
            };
          });
        }
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keluar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      // In a real app, clear local storage/shared preferences here
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  void _handleClearData() async {
    final bool? confirmClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Data'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus semua data keuangan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmClear == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('phase');
      await prefs.remove('financialData');
      await prefs.remove('transactions');

      // Firestore deletion
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // 1. Check for family ID
          String targetUid = user.uid;
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
          }

          // 2. Delete the financial_data document
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUid)
              .collection('financial_data')
              .doc('current')
              .delete();

          // Optional: We could also delete the transactions collection here if needed,
          // but clearing financial_data and SharedPreferences is enough to reset the "phase".
        } catch (e) {
          debugPrint("Failed to delete from Firestore: $e");
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Data berhasil dihapus')));
        // Force reload the app by pushing named route with replacement
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const SizedBox.shrink(); // Similar to 'if (!currentUser) return null'
    }

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Uses parent Scaffold/Container color
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 60,
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFFEC4899), // pink-500
                      Color(0xFF9333EA), // purple-600
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Color(0xFF9333EA), // purple-600
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentUser!['nama'] ?? 'Nama Pengguna',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser!['email'] ?? 'email@example.com',
                            style: const TextStyle(
                              color: Color(0xFFFCE7F3), // pink-100
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User Info Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildUserInfoRow(
                              icon: Icons.email_outlined,
                              iconColor: const Color(0xFF9333EA),
                              iconBgColor: Colors.purple.shade100,
                              label: 'Email',
                              value: _currentUser!['email'] ?? '-',
                            ),
                            const Divider(height: 16),
                            _buildUserInfoRow(
                              icon: Icons.calendar_today_outlined,
                              iconColor: Colors.blue.shade600,
                              iconBgColor: Colors.blue.shade100,
                              label: 'Umur',
                              value: '${_currentUser!['umur'] ?? '-'} tahun',
                            ),
                            const Divider(height: 16),
                            _buildUserInfoRow(
                              icon: Icons.favorite_border,
                              iconColor: const Color(0xFFEC4899),
                              iconBgColor: Colors.pink.shade100,
                              label: 'Status Pernikahan',
                              value:
                                  _currentUser!['statusPernikahan'] == 'sudah'
                                  ? 'Sudah Menikah'
                                  : 'Belum Menikah',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions / Pengaturan
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'Pengaturan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildActionItem(
                      title: 'Langganan Premium',
                      subtitle: 'Buka fitur sinkronisasi dengan akun pasangan',
                      icon: Icons.star_rounded,
                      iconColor: Colors.amber.shade600,
                      iconBgColor: Colors.amber.shade100,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Segera Hadir!'),
                            content: const Text(
                              'Fitur berlangganan Premium masih dalam tahap pengembangan. Saat ini fitur kolaborasi pasangan dapat digunakan secara gratis!',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Mengerti', style: TextStyle(color: Colors.purple)),
                              ),
                            ],
                          ),
                        );
                      },
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade500,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildActionItem(
                      title: 'Ubah Fase',
                      subtitle: 'Pra-nikah atau Pasca-nikah',
                      icon: Icons.favorite,
                      iconColor: const Color(0xFF9333EA),
                      iconBgColor: Colors.purple.shade100,
                      onTap: () async {
                        await Navigator.pushNamed(context, '/onboarding');
                        // In a real app we might reload here or refresh HomePage
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildActionItem(
                      title: 'Hapus Data Keuangan',
                      subtitle: 'Reset semua data',
                      icon: Icons.event_busy,
                      iconColor: Colors.orange.shade600,
                      iconBgColor: Colors.orange.shade100,
                      onTap: _handleClearData,
                    ),
                    const SizedBox(height: 24),

                    // Logout Button
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                      color: Colors.white,
                      child: InkWell(
                        onTap: () => _handleLogout(context),
                        borderRadius: BorderRadius.circular(16),
                        splashColor: Colors.red.shade50,
                        highlightColor: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: Colors.red.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'Keluar dari Akun',
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Info
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Unified v1.0.0',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Platform Manajemen Keuangan Pasangan',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
                if (trailing == null)
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
