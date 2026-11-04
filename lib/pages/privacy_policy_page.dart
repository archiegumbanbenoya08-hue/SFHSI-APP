import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'welcome_page.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  bool _agreed = false;
  bool _isSaving = false;

  Future<void> _acceptTerms() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to continue.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accepted_privacy_policy', true);
    if (!mounted) return;
    setState(() => _isSaving = false);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => const WelcomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
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
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Image.asset('assets/sfhsi.png', width: 100, height: 100),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Privacy Policy & Terms',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Please review our terms and privacy policy before using the app.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('App Privacy Policy', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 12),
                            Text(
                              'SFHSI collects basic account details to keep your child safe and notify you about campus activities. ' 
                              'We use local storage to store login preferences and message history. '
                              'Your data is kept on device and shared only with authorized admin and parent accounts in the app.',
                              style: TextStyle(color: Colors.white70, height: 1.5),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'By tapping Next, you agree to these terms and consent to receive secure push notifications for activity updates.',
                              style: TextStyle(color: Colors.white70, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Checkbox(
                            value: _agreed,
                            activeColor: const Color(0xFFE7B77A),
                            onChanged: (value) => setState(() => _agreed = value ?? false),
                          ),
                          const Expanded(
                            child: Text(
                              'I agree to the terms and privacy policy.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _acceptTerms,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.brown[800],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: _isSaving
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
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
