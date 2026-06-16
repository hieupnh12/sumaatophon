import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@phoneshop.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _isPasswordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginSubmitted(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _onBiometricPressed() {
    context.read<AuthBloc>().add(BiometricLoginRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              // Background Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [const Color(0xFF1A1A1D), AppColors.darkBackground]
                        : [const Color(0xFFF0F4F8), AppColors.lightBackground],
                  ),
                ),
              ),
              
              // Decorative Blur Element (Top Right)
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),

              SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Form(
                        key: _formKey,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Logo or Brand Name
                                const SizedBox(height: 40),
                                Icon(
                                  Icons.phone_iphone_rounded,
                                  size: 64,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'phoneShop',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr('login_subtitle'),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 60),

                                // Email Input
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  enabled: !isLoading,
                                  decoration: InputDecoration(
                                    hintText: context.tr('email_hint'),
                                    prefixIcon: const Icon(Icons.email_outlined),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password Input
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  textInputAction: TextInputAction.done,
                                  enabled: !isLoading,
                                  decoration: InputDecoration(
                                    hintText: context.tr('password_hint'),
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
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
                                const SizedBox(height: 12),

                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const ForgotPasswordScreen(),
                                              ),
                                            );
                                          },
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.primaryColor,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 30),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      context.tr('forgot_password'),
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Login Button
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _onLoginPressed,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(context.tr('login_btn'), style: const TextStyle(fontSize: 18)),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Biometric Login
                                Center(
                                  child: IconButton(
                                    onPressed: isLoading ? null : _onBiometricPressed,
                                    iconSize: 48,
                                    color: theme.primaryColor,
                                    style: IconButton.styleFrom(
                                      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                      padding: const EdgeInsets.all(16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    icon: const Icon(Icons.fingerprint_rounded),
                                    tooltip: 'Login with Biometrics',
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Register Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      context.tr('no_account'),
                                      style: TextStyle(
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: isLoading
                                          ? null
                                          : () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const RegisterScreen(),
                                                ),
                                              );
                                            },
                                      child: Text(
                                        context.tr('register'),
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
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
                Positioned(
                  top: 16,
                  right: 16,
                  child: BlocBuilder<ThemeCubit, ThemeMode>(
                    builder: (context, themeMode) {
                      final isDark = themeMode == ThemeMode.dark || 
                          (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
                      return IconButton(
                        icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                        onPressed: () {
                          context.read<ThemeCubit>().toggleTheme();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  ),
);
  }
}
