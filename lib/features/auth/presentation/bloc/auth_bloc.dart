import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/datasources/auth_remote_datasource.dart';

// --- EVENTS ---
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginSubmitted({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class BiometricLoginRequested extends AuthEvent {}

class GuestLoginRequested extends AuthEvent {}

class GoogleLoginRequested extends AuthEvent {}

class OtpRequested extends AuthEvent {
  final String phone;
  const OtpRequested({required this.phone});
  @override
  List<Object?> get props => [phone];
}

class OtpLoginSubmitted extends AuthEvent {
  final String phone;
  final String otp;
  const OtpLoginSubmitted({required this.phone, required this.otp});
  @override
  List<Object?> get props => [phone, otp];
}

class VerifyOtpForLinkSubmitted extends AuthEvent {
  final String otp;
  final bool force;
  const VerifyOtpForLinkSubmitted({required this.otp, this.force = false});
  @override
  List<Object?> get props => [otp, force];
}

class RegisterSubmitted extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const RegisterSubmitted({required this.name, required this.email, required this.password});
  @override
  List<Object?> get props => [name, email, password];
}

class UpdateProfileRequested extends AuthEvent {
  final String name;
  final String? gender;
  final String? dob;
  final String? address;

  const UpdateProfileRequested({
    required this.name,
    this.gender,
    this.dob,
    this.address,
  });

  @override
  List<Object?> get props => [name, gender, dob, address];
}

class ForgotPasswordSubmitted extends AuthEvent {
  final String email;
  const ForgotPasswordSubmitted({required this.email});
  @override
  List<Object?> get props => [email];
}

class LogoutRequested extends AuthEvent {}

class AuthCodeSentInternal extends AuthEvent {
  final String verificationId;
  const AuthCodeSentInternal({required this.verificationId});
  @override
  List<Object?> get props => [verificationId];
}

class AuthInternalErrorOccurred extends AuthEvent {
  final String message;
  const AuthInternalErrorOccurred({required this.message});
  @override
  List<Object?> get props => [message];
}

// --- STATES ---
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthenticatedState extends AuthState {
  final UserEntity user;
  const AuthenticatedState(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}

class AuthOtpSent extends AuthState {
  final String message;
  final String? mockOtp;
  const AuthOtpSent({required this.message, this.mockOtp});
  @override
  List<Object?> get props => [message, mockOtp];
}

class AuthActionSuccess extends AuthState {
  final String message;
  const AuthActionSuccess({required this.message});
  @override
  List<Object?> get props => [message];
}

class AuthRequirePhoneLink extends AuthState {
  const AuthRequirePhoneLink();
}

class AuthRequirePhoneConflictResolution extends AuthState {
  final String phone;
  final String otp;
  const AuthRequirePhoneConflictResolution({required this.phone, required this.otp});
  @override
  List<Object?> get props => [phone, otp];
}

// --- BLOC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  String? _verificationId;
  String? _pendingPhone;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<BiometricLoginRequested>(_onBiometricLoginRequested);
    on<GuestLoginRequested>(_onGuestLoginRequested);
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<OtpRequested>(_onOtpRequested);
    on<OtpLoginSubmitted>(_onOtpLoginSubmitted);
    on<VerifyOtpForLinkSubmitted>(_onVerifyOtpForLinkSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
    on<ForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthCodeSentInternal>(_onAuthCodeSentInternal);
    on<AuthInternalErrorOccurred>(_onAuthInternalErrorOccurred);
  }

  Future<void> _onOtpRequested(OtpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      _pendingPhone = event.phone;
      final devOtp = await authRepository.requestOtp(event.phone);
      
      emit(AuthOtpSent(
        message: devOtp != null 
           ? "Đã tự động điền OTP (Gateway lỗi/tắt)." 
           : "Đã gửi mã OTP thật qua SMS!",
        mockOtp: devOtp,
      ));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(message: "Gửi OTP lỗi: $message"));
    }
  }

  void _onAuthCodeSentInternal(AuthCodeSentInternal event, Emitter<AuthState> emit) {
    // Không còn dùng Firebase Phone Auth nên không cần
  }

  void _onAuthInternalErrorOccurred(AuthInternalErrorOccurred event, Emitter<AuthState> emit) {
    // Không còn dùng Firebase Phone Auth nên không cần
  }

  Future<void> _onOtpLoginSubmitted(OtpLoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.verifyOtp(event.phone, event.otp);
      emit(AuthenticatedState(user));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(message: "Xác thực OTP lỗi: $message"));
    }
  }
  
  Future<void> _onVerifyOtpForLinkSubmitted(VerifyOtpForLinkSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      if (_pendingPhone == null) {
        emit(const AuthError(message: "Vui lòng yêu cầu lại mã OTP."));
        return;
      }
      final user = await authRepository.linkPhone(_pendingPhone!, event.otp, force: event.force);
      emit(AuthenticatedState(user));
    } on PhoneConflictException catch (_) {
      emit(AuthRequirePhoneConflictResolution(phone: _pendingPhone!, otp: event.otp));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(message: "Liên kết số điện thoại lỗi: $message"));
    }
  }

  Future<void> _onGoogleLoginRequested(GoogleLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      await googleSignIn.signOut().catchError((_) => null);

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        emit(const AuthError(message: "Đăng nhập bằng Google bị hủy."));
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        emit(const AuthError(message: "Không lấy được Firebase ID Token."));
        return;
      }

      try {
        final user = await authRepository.syncAuth(idToken);
        emit(AuthenticatedState(user));
      } on AuthException catch (e) {
        if (e.code == 'REQUIRE_PHONE_LINK') {
          emit(const AuthRequirePhoneLink());
        } else {
          emit(AuthError(message: e.toString()));
        }
      }
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(message: "Lỗi Google Sign-In: $message"));
    }
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(event.email, event.password);
      emit(AuthenticatedState(user));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(message: message));
    }
  }

  Future<void> _onUpdateProfileRequested(UpdateProfileRequested event, Emitter<AuthState> emit) async {
    final currentState = state;
    if (currentState is AuthenticatedState) {
      emit(AuthLoading());
      try {
        final updatedUser = await authRepository.updateProfile(
          customerId: currentState.user.id,
          name: event.name,
          gender: event.gender,
          dob: event.dob,
          address: event.address,
        );
        emit(AuthenticatedState(updatedUser));
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        emit(AuthError(message: message));
        emit(currentState); // Restore state
      }
    }
  }

  Future<void> _onBiometricLoginRequested(BiometricLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (canAuthenticate) {
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to login to phoneShop Premium',
          options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
        );
        if (didAuthenticate) {
          emit(const AuthenticatedState(UserEntity(
            id: 'bio_user', name: 'Biometric User', email: 'bio@phoneshop.com',
          )));
        } else {
          emit(const AuthError(message: "Biometric authentication failed or was canceled."));
        }
      } else {
        emit(const AuthError(message: "Biometric authentication is not supported on this device."));
      }
    } catch (e) {
      emit(AuthError(message: "Biometric error: ${e.toString()}"));
    }
  }

  void _onGuestLoginRequested(GuestLoginRequested event, Emitter<AuthState> emit) {
    emit(const AuthenticatedState(UserEntity(
      id: 'guest',
      name: 'Khách',
      email: '',
      avatarUrl: '',
    )));
  }

  Future<void> _onRegisterSubmitted(RegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.register(event.name, event.email, event.password);
      emit(const AuthActionSuccess(message: "Registration successful! You can now log in."));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(message: message));
    }
  }

  Future<void> _onForgotPasswordSubmitted(ForgotPasswordSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await Future.delayed(const Duration(seconds: 2));
      emit(AuthActionSuccess(message: "Password reset link sent to ${event.email}."));
    } catch (e) {
      emit(AuthError(message: "Failed to send reset link: ${e.toString()}"));
    }
  }
  
  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await _firebaseAuth.signOut();
    emit(AuthInitial());
  }
}
