import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/auth/auth_guard.dart';
import '../bloc/auth_bloc.dart';
import '../phone_utils.dart';
import '../auth_navigation.dart';
import 'link_phone_page.dart';

class LoginScreen extends StatefulWidget {
  final bool returnAfterAuth;

  const LoginScreen({super.key, this.returnAfterAuth = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _showOtpStep = false;
  String? _otpError;
  final FocusNode _otpFocusNode = FocusNode();
  Timer? _validityTimer;
  Timer? _resendTimer;
  int _validitySeconds = 300;
  int _resendSeconds = 60;

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

    if (widget.returnAfterAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (isRealAuthenticatedState(context.read<AuthBloc>().state)) {
          Navigator.pop(context, true);
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _validityTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    setState(() {
      _validitySeconds = 300;
      _resendSeconds = 60;
    });

    _validityTimer?.cancel();
    _resendTimer?.cancel();

    _validityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_validitySeconds > 0) {
        setState(() => _validitySeconds--);
      } else {
        timer.cancel();
      }
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _stopTimers() {
    _validityTimer?.cancel();
    _resendTimer?.cancel();
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '$minutes phút $seconds giây';
    }
    return '$seconds giây';
  }

  void _onContinuePressed() {
    final phoneDisplay = _phoneController.text.trim();
    if (phoneDisplay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.trRead('login_phone_hint')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final phone = normalizePhone(phoneDisplay);
    final phoneRegex = RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$');
    if (!phoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.trRead('login_phone_invalid')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(OtpRequested(phone: phone));
  }

  void _onOtpCompleted(String otp) {
    if (context.read<AuthBloc>().state is AuthLoading) return;
    final phone = normalizePhone(_phoneController.text);
    context.read<AuthBloc>().add(OtpLoginSubmitted(phone: phone, otp: otp));
  }

  void _onChangePhonePressed() {
    setState(() {
      _showOtpStep = false;
      _otpController.clear();
    });
    _stopTimers();
  }

  void _onResendOtpPressed() {
    if (_resendSeconds == 0) {
      final phone = normalizePhone(_phoneController.text);
      context.read<AuthBloc>().add(OtpRequested(phone: phone));
    }
  }

  void _onGoogleLoginPressed() {
    context.read<AuthBloc>().add(GoogleLoginRequested());
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: TextStyle(
        fontSize: 22,
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            String errorMsg = state.message;
            if (errorMsg.contains('Connection refused') || errorMsg.contains('SocketException') || errorMsg.contains('TimeoutException')) {
              errorMsg = "Không thể kết nối đến máy chủ. Vui lòng thử lại sau.";
              if (_showOtpStep) {
                setState(() {
                  _otpError = errorMsg;
                  _otpController.clear();
                });
                _otpFocusNode.requestFocus();
              }
            } else if ((errorMsg.toLowerCase().contains('otp') || errorMsg.toLowerCase().contains('code')) && _showOtpStep) {
              errorMsg = context.trRead('otp_invalid_error');
              setState(() {
                _otpError = errorMsg;
                _otpController.clear();
              });
              _otpFocusNode.requestFocus();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          } else if (state is AuthenticatedState) {
            if (widget.returnAfterAuth) {
              Navigator.pop(context, true);
            } else {
              navigateAfterAuth(context);
            }
          } else if (state is AuthRequirePhoneLink) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LinkPhonePage(returnAfterAuth: widget.returnAfterAuth),
              ),
            ).then((_) {
              if (!mounted || !widget.returnAfterAuth) return;
              if (isRealAuthenticatedState(context.read<AuthBloc>().state)) {
                Navigator.pop(context, true);
              }
            });
          } else if (state is AuthOtpSent) {
            if (!_showOtpStep) {
              setState(() => _showOtpStep = true);
            }
            _startTimers();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
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

              // Glowing blur elements
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
                    // Theme Switcher
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

                    // Skip Button Bottom Right
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: TextButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(GuestLoginRequested());
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : Colors.black87,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('Bỏ qua'),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          ],
                        ),
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
                                const SizedBox(height: 40),

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
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        child: _showOtpStep
                                            ? _buildOtpStep(context, theme, isDark, isLoading, defaultPinTheme)
                                            : _buildPhoneStep(context, theme, isDark, isLoading),
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

  Widget _buildPhoneStep(BuildContext context, ThemeData theme, bool isDark, bool isLoading) {
    return Column(
      key: const ValueKey('PhoneStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('login_title'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('login_benefits_desc'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 24),

        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _PhoneNumberFormatter(),
          ],
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: context.tr('login_phone_hint'),
            hintStyle: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _onContinuePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : const Color(0xFF16161A),
              foregroundColor: isDark ? Colors.black : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: isDark ? Colors.black : Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    context.tr('login_continue_btn'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 24),

        // Social Login Section
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
                'Hoặc',
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
            child: Row(
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
      ],
    );
  }

  Widget _buildOtpStep(BuildContext context, ThemeData theme, bool isDark, bool isLoading, PinTheme defaultPinTheme) {
    return Column(
      key: const ValueKey('OtpStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: _onChangePhonePressed,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? Colors.white : Colors.black87),
              ),
            ),
            Expanded(
              child: Text(
                context.tr('otp_title'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.5,
            ),
            children: [
              TextSpan(text: '${context.tr('otp_sent_to')}\n'),
              TextSpan(
                text: '${_phoneController.text.trim()}, ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '${context.tr('otp_valid_for')} '),
              TextSpan(
                text: _formatTime(_validitySeconds),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _onChangePhonePressed,
          borderRadius: BorderRadius.circular(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit, size: 14, color: AppColors.warning),
              const SizedBox(width: 4),
              Text(
                context.tr('otp_change_phone'),
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // OTP Input
        Center(
          child: Column(
            children: [
              Pinput(
                length: 6,
                controller: _otpController,
                focusNode: _otpFocusNode,
                errorText: _otpError,
                forceErrorState: _otpError != null,
                onChanged: (val) {
                  if (val.isNotEmpty && _otpError != null) {
                    setState(() => _otpError = null);
                  }
                },
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
                errorPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppColors.error, width: 2),
                  ),
                ),
                submittedPinTheme: defaultPinTheme,
                onCompleted: _onOtpCompleted,
                enabled: !isLoading,
                autofocus: true,
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Resend Text
        Center(
          child: InkWell(
            onTap: _onResendOtpPressed,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('otp_resend_code'),
                    style: TextStyle(
                      color: _resendSeconds == 0 
                          ? (isDark ? Colors.white : Colors.black87) 
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      fontWeight: _resendSeconds == 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (_resendSeconds > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '$_resendSeconds giây',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
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

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 4 || i == 7) {
        formatted += ' ';
      }
      formatted += text[i];
    }
    
    if (formatted.length > 12) {
      return oldValue;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
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
