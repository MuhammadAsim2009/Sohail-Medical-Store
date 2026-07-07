import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_feedback.dart';
import '../services/database_helper.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _primaryColor = Color(0xFF0F4C81);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String _shopName = 'Pharmacy';

  @override
  void initState() {
    super.initState();
    _loadShopName();
  }

  Future<void> _loadShopName() async {
    try {
      final settings = await DatabaseHelper.instance.getAllSettings();
      if (mounted) {
        setState(() {
          _shopName = settings['shop_name']?.isNotEmpty == true
              ? settings['shop_name']!
              : 'Pharmacy';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          if (email == 'admin@gmail.com' && password == 'Admin@123') {
            // Auto create admin account if it doesn't exist
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);
      if (_rememberMe) {
        await prefs.setString('last_activity', DateTime.now().toIso8601String());
      } else {
        await prefs.remove('last_activity');
      }

      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Authentication failed';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = 'Invalid email or password';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is badly formatted';
      } else {
        message = e.message ?? message;
      }
      AppFeedback.show(context, message, type: AppFeedbackType.error);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.show(context, 'An unexpected error occurred', type: AppFeedbackType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _seedAdmin() async {
    setState(() {
      _isLoading = true;
    });
    try {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'admin@gmail.com',
          password: 'Admin@123',
        );
      } catch (e) {
        debugPrint('Sign in failed, attempting to create account. Error was: $e');
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: 'admin@gmail.com',
          password: 'Admin@123',
        );
      }
      if (!mounted) return;
      AppFeedback.show(context, 'Admin account seeded successfully!', type: AppFeedbackType.success);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.show(context, 'Failed to seed admin: $e', type: AppFeedbackType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: _primaryColor,
        ),
      ),
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
          return Row(
            children: [
              if (isWide)
                Expanded(
                  flex: 5,
                  child: _BrandingPanel(shopName: _shopName),
                ),
              Expanded(
                flex: 4,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Welcome Back',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: _primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to manage your pharmacy',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 48),
                            const Text(
                              'Email Address',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.mail_outline),
                                hintText: 'Enter your email',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Password',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.black87),
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline),
                                hintText: 'Enter your password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Remember me'),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('Forgot password?'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton.icon(
                                onPressed: _isLoading ? null : _seedAdmin,
                                icon: const Icon(Icons.admin_panel_settings),
                                label: const Text('Seed Admin Account'),
                                style: TextButton.styleFrom(
                                  foregroundColor: _primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                "Don't have an account? Contact admin",
                                style: const TextStyle(
                                  color: _primaryColor,
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
            ],
          );
        },
      ),
    ),
    );
  }
}

class _BrandingPanel extends StatelessWidget {
  final String shopName;
  const _BrandingPanel({required this.shopName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F4C81), // Primary
            Color(0xFF1976D2), // Accent
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    size: 48,
                    color: Color(0xFF0F4C81),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your complete pharmacy management solution.',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 64),
                const _FeatureRow(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory Tracking',
                  description: 'Monitor stock levels in real-time',
                ),
                const SizedBox(height: 24),
                const _FeatureRow(
                  icon: Icons.receipt_long_outlined,
                  title: 'Fast Billing',
                  description: 'Quick and easy point of sale',
                ),
                const SizedBox(height: 24),
                const _FeatureRow(
                  icon: Icons.bar_chart_rounded,
                  title: 'Reports & Analytics',
                  description: 'Gain insights into your business',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
