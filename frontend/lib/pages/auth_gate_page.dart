import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../theme/app_theme.dart';
import 'main.navigations.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  final LocalAuthentication _auth = LocalAuthentication();

  bool _isChecking = true;
  bool _isUnlocked = false;
  bool _biometricAvailable = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      final biometrics = await _auth.getAvailableBiometrics();
      final available =
          (canCheck || isSupported) &&
          biometrics.any(
            (item) =>
                item == BiometricType.fingerprint ||
                item == BiometricType.strong ||
                item == BiometricType.weak,
          );

      if (!available) {
        setState(() {
          _biometricAvailable = false;
          _isUnlocked = true;
          _isChecking = false;
          _message =
              'Biometrik tidak tersedia di perangkat ini. Aplikasi dibuka tanpa autentikasi sidik jari.';
        });
        return;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason:
            'Gunakan sidik jari yang sudah terdaftar untuk masuk ke aplikasi.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      setState(() {
        _biometricAvailable = true;
        _isUnlocked = didAuthenticate;
        _isChecking = false;
        _message = didAuthenticate
            ? null
            : 'Autentikasi dibatalkan. Silakan coba lagi untuk melanjutkan.';
      });
    } catch (error) {
      setState(() {
        _biometricAvailable = true;
        _isUnlocked = false;
        _isChecking = false;
        _message = 'Autentikasi biometrik gagal: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked) {
      return const MainNavigation();
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fingerprint,
                          size: 52,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Keamanan Biometrik',
                        style: AppTheme.heading2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masuk menggunakan sidik jari yang sudah terdaftar pada perangkat Anda.',
                        style: AppTheme.body.copyWith(color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _biometricAvailable
                                ? Colors.orange.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _biometricAvailable
                                  ? Colors.orange.shade200
                                  : Colors.blue.shade200,
                            ),
                          ),
                          child: Text(
                            _message!,
                            style: AppTheme.caption.copyWith(
                              color: Colors.grey.shade800,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isChecking ? null : _authenticate,
                          icon: _isChecking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.lock_open),
                          label: Text(
                            _isChecking
                                ? 'Memeriksa Biometrik...'
                                : 'Autentikasi Sekarang',
                          ),
                        ),
                      ),
                      if (!_biometricAvailable && !_isChecking) ...[
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isUnlocked = true;
                            });
                          },
                          child: const Text('Buka Aplikasi'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
