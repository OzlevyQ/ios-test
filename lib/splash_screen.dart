import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'home_page.dart';

class SplashScreenPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Column(
        children: [
          Image.asset(
            'assets/hammer.gif',
            width: 180,  // קבע את הרוחב ל-180 פיקסלים
            height: 180, // קבע את הגובה ל-180 פיקסלים
          ),
          const SizedBox(height: 20),
            

        ],
      ),
      backgroundColor: Colors.white,
      nextScreen: HomePage(),
      splashIconSize: 200,
      duration: 3000,
      splashTransition: SplashTransition.fadeTransition,
    );
  }
}
