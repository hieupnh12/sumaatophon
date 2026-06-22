import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
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
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onGoogleLoginPressed() {
    context.read<AuthBloc>().add(GoogleLoginRequested());
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
                        ? [const Color(0xFF0F0F12), AppColors.darkBackground]
                        : [const Color(0xFFE8ECEF), AppColors.lightBackground],
                  ),
                ),
              ),

              // Glowing blur elements for premium background
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),

              Positioned(
                bottom: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withValues(alpha: isDark ? 0.15 : 0.08),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),

              SafeArea(
                child: Stack(
                  children: [
                    // Theme Switcher Top Right
                    Positioned(
                      top: 16,
                      right: 16,
                      child: BlocBuilder<ThemeCubit, ThemeMode>(
                        builder: (context, themeMode) {
                          final isDarkTheme = themeMode == ThemeMode.dark ||
                              (themeMode == ThemeMode.system &&
                                  MediaQuery.of(context).platformBrightness == Brightness.dark);
                          return IconButton(
                            icon: Icon(isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                            onPressed: () {
                              context.read<ThemeCubit>().toggleTheme();
                            },
                          );
                        },
                      ),
                    ),

                    Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Brand Section
                                Image.asset(
                                  'assets/images/logo.png',
                                  width: 90,
                                  height: 90,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'phoneShop',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                    fontSize: 32,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr('login_subtitle'),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 50),

                                // Glassmorphism Login Card
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.03)
                                            : Colors.black.withValues(alpha: 0.02),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : Colors.black.withValues(alpha: 0.06),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          // Title in card
                                          Text(
                                            context.tr('login_title'),
                                            style: theme.textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                            ),
                                          ),
                                          const SizedBox(height: 32),

                                          // Google Sign-In Button
                                          SizedBox(
                                            height: 56,
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: isLoading ? null : _onGoogleLoginPressed,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isDark ? Colors.white : Colors.white,
                                                foregroundColor: Colors.black,
                                                elevation: 2,
                                                shadowColor: Colors.black.withValues(alpha: 0.2),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  side: BorderSide(
                                                    color: Colors.grey.shade300,
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              child: isLoading
                                                  ? const SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(
                                                        color: Colors.black87,
                                                        strokeWidth: 2.5,
                                                      ),
                                                    )
                                                  : Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const GoogleLogo(size: 24),
                                                        const SizedBox(width: 12),
                                                        Text(
                                                          context.tr('login_google_btn'),
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),

                                          const SizedBox(height: 32),

                                          // Divider with Or
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Divider(
                                                  color: isDark ? Colors.white30 : Colors.black26,
                                                  thickness: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                child: Text(
                                                  'Or',
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white54 : Colors.black45,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Divider(
                                                  color: isDark ? Colors.white30 : Colors.black26,
                                                  thickness: 1,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 24),

                                          // Biometric button label
                                          Text(
                                            'Login with Fingerprint / Face ID',
                                            style: TextStyle(
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          // Biometric login action
                                          IconButton(
                                            onPressed: isLoading ? null : _onBiometricPressed,
                                            iconSize: 44,
                                            color: AppColors.primary,
                                            style: IconButton.styleFrom(
                                              backgroundColor: isDark
                                                  ? Colors.white.withValues(alpha: 0.05)
                                                  : Colors.black.withValues(alpha: 0.04),
                                              padding: const EdgeInsets.all(12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                                side: BorderSide(
                                                  color: isDark ? Colors.white12 : Colors.black12,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            icon: const Icon(Icons.fingerprint_rounded),
                                            tooltip: 'Biometric Login',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
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

// Custom Painter to draw Google 'G' logo
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.22
      ..strokeCap = StrokeCap.butt;

    final Rect rect = Rect.fromLTWH(0, 0, width, height);

    // Google Red Arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.1, 1.4, false, paint);

    // Google Yellow Arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -3.5, 1.4, false, paint);

    // Google Green Arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.7, 1.4, false, paint);

    // Google Blue Arc & Horizontal Bar
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.7, 1.4, false, paint);

    final Paint fillPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    
    // Draw horizontal bar of 'G'
    canvas.drawRect(
      Rect.fromLTWH(width * 0.5, height * 0.39, width * 0.45, width * 0.22),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: GoogleLogoPainter(),
      ),
    );
  }
}
