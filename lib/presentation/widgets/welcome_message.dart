import 'package:ai_cockpit_app/blocs/auth/auth_cubit.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

class WelcomeMessage extends StatelessWidget {
  final AuthState authState;
  const WelcomeMessage({super.key, required this.authState});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = authState is Authenticated;
    final String name = isAuthenticated
        ? (authState as Authenticated).user.displayName?.split(' ')[0] ?? 'User'
        : '';
    final String text = isAuthenticated
        ? 'Halo, $name!'
        : 'Meet AI Research Cockpit';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  text,
                  textStyle: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                  speed: const Duration(milliseconds: 70),
                ),
              ],
              totalRepeatCount: 1,
            ),
            if (!isAuthenticated) ...[
              const SizedBox(height: 8),
              Text(
                'your personal AI assistant',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white54),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
