import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();

  String _maritalStatus = 'belum'; // Default status
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Validasi
      if (_nameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty ||
          _ageController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = "Semua field harus diisi";
          _isLoading = false;
        });
        return;
      }

      final age = int.tryParse(_ageController.text.trim()) ?? 0;
      if (age < 17) {
        setState(() {
          _errorMessage = "Umur minimal 17 tahun";
          _isLoading = false;
        });
        return;
      }

      if (_passwordController.text.trim().length < 6) {
        setState(() {
          _errorMessage = "Password minimal 6 karakter";
          _isLoading = false;
        });
        return;
      }

      // Create user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Save additional details to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'age': age,
            'maritalStatus': _maritalStatus,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        // Redirect ke home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? "Terjadi kesalahan. Silakan coba lagi.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF9333EA)),
            ),
          ),
        ),
      ],
    );
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
              Color(0xFFFDF2F8), // pink-50 equivalent
              Color(0xFFFAF5FF), // purple-50 equivalent
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header Section
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFEC4899), // pink-500
                            Color(0xFF9333EA), // purple-600
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unified',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Platform Keuangan Pasangan',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Register Card
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Daftar Akun',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Buat akun untuk mulai menggunakan Unified',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Error Message
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2), // red-50
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626), // red-600
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                            // Fields
                            _buildTextField(
                              'Nama Lengkap',
                              'Masukkan nama lengkap',
                              _nameController,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              'Email',
                              'nama@example.com',
                              _emailController,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              'Password',
                              'Minimal 6 karakter',
                              _passwordController,
                              isPassword: true,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              'Umur',
                              'Masukkan umur',
                              _ageController,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),

                            // Radio Group (Status Pernikahan)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Pernikahan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    unselectedWidgetColor: Colors.grey.shade400,
                                  ),
                                  child: Column(
                                    children: [
                                      RadioListTile<String>(
                                        title: const Text(
                                          'Belum Menikah',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        value: 'belum',
                                        groupValue: _maritalStatus,
                                        activeColor: const Color(0xFF9333EA),
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical: -4,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _maritalStatus = value!;
                                          });
                                        },
                                      ),
                                      RadioListTile<String>(
                                        title: const Text(
                                          'Sudah Menikah',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        value: 'sudah',
                                        groupValue: _maritalStatus,
                                        activeColor: const Color(0xFF9333EA),
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical: -4,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _maritalStatus = value!;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'Daftar',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Footer link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Sudah punya akun? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Text(
                                    'Login di sini',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF9333EA), // purple-600
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
