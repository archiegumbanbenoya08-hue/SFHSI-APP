import 'dart:ui';

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../services/app_connection_service.dart';
import '../services/parent_account_service.dart';
import 'admin_page.dart';
import 'parent_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _navigateToAccount(String email) async {
    final accountService = ParentAccountService();
    final currentAdminEmail = await accountService.getAdminEmail();
    final isAdminLogin = email == currentAdminEmail || email == ParentAccountService.adminEmail;

    if (!mounted) return;

    await accountService.setLastLoggedInEmail(email);
    if (isAdminLogin) {
      _navigateWithFade(const AdminPage());
      return;
    }

    _navigateWithFade(ParentPage(email: email));
  }

  void _navigateWithFade(Widget page) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final accountService = ParentAccountService();
      final isValidCredentials = await accountService.verifyCredentials(email, password);

      if (mounted) {
        if (isValidCredentials) {
          final connectionService = AppConnectionService();
          final isConnected = await connectionService.canUseApp();
          if (!isConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Offline mode: saved account login is available, but live campus updates require internet.'),
              ),
            );
          }
          await _navigateToAccount(email);
          // clear password after successful login for basic security
          if (mounted) _passwordController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid credentials')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/bg-sfhsi.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Stack(
          children: [
            // Back button at upper left
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        SizedBox(width: 4),
                        Text('Back', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main content - centered
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Welcome text positioned above login box
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Welcome',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.brown[400],
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.0,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                    color: Colors.black.withAlpha(77),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Log in to your account to continue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Centered login container
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('assets/sfhsi.png', width: 110, height: 110),
                              const SizedBox(height: 10),
                              const SizedBox(height: 20),

                              TextField(
                                controller: _emailController,
                                enabled: !_isLoading,
                                keyboardType: TextInputType.emailAddress,
                                onSubmitted: (_) => _handleLogin(),
                                decoration: InputDecoration(
                                  hintText: 'Enter your email',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                enabled: !_isLoading,
                                obscureText: !_showPassword,
                                onSubmitted: (_) => _handleLogin(),
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                                    onPressed: _isLoading ? null : () => setState(() => _showPassword = !_showPassword),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.brown[700],
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.brown[700]?.withAlpha(153),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 15,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Log In', style: TextStyle(fontSize: 20, color: Colors.white)),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
