import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartstock/core/constants/firestore_constants.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndNavigate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestoreConstants.restrictions)
          .doc('global')
          .get();

      if (doc.exists && doc.data()?['isRestricted'] == true) {
        if (!mounted) return;
        _showRestrictionDialog();
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _showRestrictionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.lock_outline, size: 48, color: AppColors.error),
              SizedBox(height: 12),
              Text('Trial Expired', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          content: const Text(
            'Your free trial has ended. To get full access to SmartStock, please contact the developer.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            GestureDetector(
              onTap: () async {
                const urls = [
                  'https://wa.me/8801600144226',
                  'https://api.whatsapp.com/send?phone=8801600144226',
                ];
                for (final url in urls) {
                  try {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    return;
                  } catch (_) {}
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Contact on WhatsApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/logo/SmartStock logo.jpg',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SmartStock',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inventory Management',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textSecondary.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
