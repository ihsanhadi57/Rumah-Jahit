import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/biometric_service.dart';
import '../data/auth_repository.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _canUseBiometric = false;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final supported = await BiometricService.isDeviceSupported();
    final enabled = await BiometricService.isBiometricEnabled();
    final hasCreds = await BiometricService.hasStoredCredentials();
    if (mounted) {
      setState(() {
        _canUseBiometric = supported && enabled && hasCreds;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithBiometric() async {
    final authenticated = await BiometricService.authenticate();
    if (!authenticated) return;

    final creds = await BiometricService.getCredentials();
    if (creds == null) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final appUser = await authRepo.signInWithUsername(
        creds['email']!,
        creds['password']!,
      );

      if (!mounted) return;

      if (!appUser.isApproved) {
        context.go('/activation-pending');
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        // Credentials might be stale, clear them
        await BiometricService.clearCredentials();
        if (!mounted) return; // Fix for context across async gaps
        setState(() {
          _canUseBiometric = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sidik jari gagal. Silakan login dengan email & password.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);

      if (_isLogin) {
        final appUser = await authRepo.signInWithUsername(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

        if (!mounted) return;

        // Save credentials for biometric login on next app launch
        final deviceSupported = await BiometricService.isDeviceSupported();
        if (deviceSupported) {
          await BiometricService.saveCredentials(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
          );
        }

        if (!mounted) return; // Fix for context across async gaps
        if (!appUser.isApproved) {
          context.go('/activation-pending');
        } else {
          context.go('/dashboard');
        }
      } else {
        await authRepo.signUp(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        context.go('/activation-pending');
      }
    } catch (e) {
      if (mounted) {
        String message = 'Terjadi kesalahan.';
        final errorStr = e.toString();
        if (errorStr.contains('user-not-found')) {
          message = 'Akun tidak ditemukan.';
        } else if (errorStr.contains('wrong-password') ||
            errorStr.contains('invalid-credential')) {
          message = 'Username atau password salah.';
        } else if (errorStr.contains('tidak ditemukan')) {
          message = errorStr.replaceAll('Exception: ', '');
        } else if (errorStr.contains('email-already-in-use')) {
          message = 'Email sudah terdaftar. Silakan gunakan email lain.';
        } else if (errorStr.contains('weak-password')) {
          message =
              'Password terlalu lemah. Gunakan min 6 karakter dengan huruf besar, huruf kecil, dan angka.';
        } else if (errorStr.contains('invalid-email')) {
          message = 'Format email tidak valid.';
        } else if (errorStr.contains('too-many-requests')) {
          message = 'Terlalu banyak percobaan. Coba lagi nanti.';
        } else if (errorStr.contains('network-request-failed')) {
          message = 'Tidak ada koneksi internet.';
        } else if (errorStr.contains('Data pengguna tidak ditemukan')) {
          message = 'Data pengguna tidak ditemukan di database.';
        } else {
          // Fallback: show actual error so user knows what happened
          final match = RegExp(r'\] (.+)').firstMatch(errorStr);
          message = match != null ? match.group(1)! : errorStr;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: GoogleFonts.inter()),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Password',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Masukkan email Anda. Kami akan mengirimkan link untuk reset password.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'email@contoh.com',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.mail_outline,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
                filled: true,
                fillColor: const Color(0xFFF2F4F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D4C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) return;

              try {
                await ref
                    .read(authRepositoryProvider)
                    .sendPasswordResetEmail(email);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Link reset password telah dikirim ke $email',
                        style: GoogleFonts.inter(),
                      ),
                      backgroundColor: const Color(0xFF004D4C),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal mengirim email. Pastikan email benar.',
                        style: GoogleFonts.inter(),
                      ),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Kirim',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      body: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
    );
  }

  // ─────────────────────────── TABLET ───────────────────────────
  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Left branding panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF003D3D), Color(0xFF006766)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rumah Jahit Alya',
                      style: GoogleFonts.manrope(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Spacer(),
                    if (!_isLogin)
                      Text(
                        'KONVEKSI MODERN',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    if (!_isLogin) const SizedBox(height: 16),
                    Text(
                      _isLogin
                          ? 'Merajut Kualitas\ndi Setiap Jahitan.'
                          : 'Menciptakan Karya,\nSatu Jahitan \nTerbaik.',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isLogin
                          ? 'Akses ruang kerja jahit Anda, kelola persediaan bahan,\ndan pantau pesanan dengan tingkat detail terbaik\ntanpa kendala.'
                          : 'Bergabunglah dengan konveksi modern kami. Kelola kreasi,\npantau ketersediaan bahan, dan alur kerja jahitan Anda.',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _buildDot(true),
                        const SizedBox(width: 8),
                        _buildDot(false),
                        const SizedBox(width: 8),
                        _buildDot(false),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right form panel
        Expanded(
          flex: 5,
          child: Container(
            color: const Color(0xFFF8FAFA),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildForm(isTablet: true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(bool active) {
    return Container(
      width: active ? 32 : 16,
      height: 4,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white38,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ─────────────────────────── MOBILE ───────────────────────────
  Widget _buildMobileLayout() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_isLogin) ...[
                    // Hero header for login
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE0F2F1), Color(0xFFF8FAFA)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFF004D4C),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.checkroom,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Selamat Datang',
                            style: GoogleFonts.manrope(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF001F1F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manajemen menjahit dalam genggaman Anda',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Header for register
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mulai Petualangan\nMenjahit Anda',
                            style: GoogleFonts.manrope(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF001F1F),
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Bergabunglah bersama kami dan wujudkan karya busana\ndengan perhitungan yang lebih matang.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: _buildForm(isTablet: false),
                  ),
                ],
              ),
            ),
          ),
          // Bottom toggle bar
          _buildBottomToggle(),
        ],
      ),
    );
  }

  // ─────────────────────────── FORM ───────────────────────────
  Widget _buildForm({required bool isTablet}) {
    final colors = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTablet) ...[
            Text(
              _isLogin ? 'Selamat Datang' : 'Mulai Perjalanan\nMenjahit Anda',
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF001F1F),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isLogin
                  ? 'Manajemen menjahit dalam genggaman Anda'
                  : 'Buat profil profesional Anda untuk memulai.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Username (login & register)
          _buildLabel('USERNAME'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _usernameController,
            hint: 'Masukkan username',
            icon: Icons.person_outline,
            validator: (v) =>
                (v == null || v.trim().isEmpty || v.trim().length < 3)
                ? 'Username minimal 3 karakter'
                : null,
          ),
          const SizedBox(height: 20),

          // Email (register only)
          if (!_isLogin) ...[
            _buildLabel('ALAMAT EMAIL'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _emailController,
              hint: 'hello@rumahjahit.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],

          // Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('PASSWORD'),
              if (_isLogin)
                GestureDetector(
                  onTap: _showForgotPasswordDialog,
                  child: Text(
                    'Lupa Password?',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passwordController,
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: Colors.grey.shade500,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password wajib diisi';
              if (v.length < 6) return 'Password minimal 6 karakter';
              if (!_isLogin) {
                if (!RegExp(r'[A-Z]').hasMatch(v)) {
                  return 'Password harus mengandung huruf besar';
                }
                if (!RegExp(r'[a-z]').hasMatch(v)) {
                  return 'Password harus mengandung huruf kecil';
                }
                if (!RegExp(r'[0-9]').hasMatch(v)) {
                  return 'Password harus mengandung angka';
                }
              }
              return null;
            },
          ),

          // Confirm Password (register only)
          if (!_isLogin) ...[
            const SizedBox(height: 20),
            _buildLabel('KONFIRMASI PASSWORD'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _confirmPasswordController,
              hint: '••••••••',
              icon: Icons.shield_outlined,
              obscure: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Konfirmasi password wajib diisi';
                }
                if (v != _passwordController.text) {
                  return 'Password tidak cocok';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? 'Masuk' : 'Daftar Akun',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
          ),

          // Biometric login button
          if (_isLogin && _canUseBiometric) ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    'atau masuk dengan',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _isLoading ? null : _loginWithBiometric,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF004D4C).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.fingerprint,
                        size: 36,
                        color: Color(0xFF004D4C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Toggle link for tablet
          if (isTablet) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text(
                    _isLogin ? 'Belum punya akun?' : 'Sudah punya akun?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => setState(() {
                      _isLogin = !_isLogin;
                      _formKey.currentState?.reset();
                    }),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLogin
                              ? Icons.person_add_outlined
                              : Icons.arrow_back,
                          size: 16,
                          color: const Color(0xFF004D4C),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isLogin ? 'Daftar Sekarang' : 'Kembali ke Login',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF004D4C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFooterLink('KEBIJAKAN PRIVASI'),
                  const SizedBox(width: 24),
                  _buildFooterLink('SYARAT & KETENTUAN'),
                  const SizedBox(width: 24),
                  _buildFooterLink('DUKUNGAN'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '© 2024 RUMAH JAHIT ALYA. HAK CIPTA DILINDUNGI.',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],

          // Footer branding for mobile
          if (!isTablet) ...[
            const SizedBox(height: 32),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 40, height: 1, color: Colors.grey.shade300),
                  const SizedBox(width: 12),
                  Text(
                    'KONVEKSI MODERN',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 40, height: 1, color: Colors.grey.shade300),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 0.5,
      ),
    );
  }

  // ─────────────────────────── BOTTOM TOGGLE (MOBILE) ───────────────────────────
  Widget _buildBottomToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('MASUK', Icons.login, _isLogin, true),
          ),
          Expanded(
            child: _buildTabButton(
              'DAFTAR',
              Icons.person_add_outlined,
              !_isLogin,
              false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    String label,
    IconData icon,
    bool isActive,
    bool isLoginTab,
  ) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() {
        _isLogin = isLoginTab;
        _formKey.currentState?.reset();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE0F2F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? colors.primary : Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? colors.primary : Colors.grey.shade400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── SHARED WIDGETS ───────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF004D4C),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF2F4F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF004D4C)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
