import 'dart:ui';

import 'package:flutter/material.dart';

import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage('assets/bg-sfhsi.png'),
          fit: BoxFit.cover,
        )
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
          body: Center(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),

            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/sfhsi.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome to SFHSI System',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Student Entry and Exit Monitoring System',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: const Text(
                      'A comprehensive system for tracking and monitoring students, ensuring safety and providing real-time updates to parents and administrators.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 450),
                          pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      animationDuration: const Duration(milliseconds: 250),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.brown[700],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 45),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildFeatureCard(
                            icon: Icons.shield,
                            title: 'Real-Time Tracking',
                            description: 'Monitor student entries and exits in real time',
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildFeatureCard(
                            icon: Icons.apartment,
                            title: 'Grade Management',
                            description: 'Organized by grade levels for easy navigation',
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildFeatureCard(
                            icon: Icons.arrow_forward,
                            title: 'Parent Portal',
                            description: "Parents can monitor their child's activities",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
